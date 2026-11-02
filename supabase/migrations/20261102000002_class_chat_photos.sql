-- ─────────────────────────────────────────────────────────────────────────────
-- Class chat photos (teacher ↔ student), photos only — no other files.
-- Run in the Supabase SQL Editor AFTER deploying the cleanup-chat-photos
-- Edge Function (--no-verify-jwt; step 5 schedules it).
--
-- User's rules (2026-11-02): both sides can send photos; a student sends at
-- most 10 photos a day per class (they also count toward the 50 messages);
-- photos are deleted after 30 days and the message shows "photo expired".
--
-- Files live in the private bucket chat-photos at
--   <class_id>/<student_id>/<random>.jpg
-- (student_id = the conversation, whoever sent it). Clients shrink photos to
-- 1280px JPEG before upload; the bucket refuses anything over 2 MB or not an
-- image. Read access is the conversation only: that student + the class's
-- teacher. Messages point at the file via image_path.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Message rows can carry a photo; a photo message may have no text.
alter table public.class_notes   add column if not exists image_path text;
alter table public.class_replies add column if not exists image_path text;

alter table public.class_replies drop constraint if exists class_replies_message_check;
alter table public.class_replies add constraint class_replies_message_check check (
  char_length(message) <= 500
  and (image_path is not null or char_length(btrim(message)) >= 1)
);

-- A photo row must point inside its own conversation's folder, so nobody can
-- attach someone else's file to their message.
alter table public.class_replies drop constraint if exists class_replies_image_path_check;
alter table public.class_replies add constraint class_replies_image_path_check check (
  image_path is null or image_path like class_id::text || '/' || student_id::text || '/%'
);
alter table public.class_notes drop constraint if exists class_notes_image_path_check;
alter table public.class_notes add constraint class_notes_image_path_check check (
  image_path is null or image_path like class_id::text || '/' || student_id::text || '/%'
);

-- 2. Student daily caps: 50 messages (unchanged) and 10 photos.
create or replace function public.class_replies_daily_cap()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  day_start timestamptz := date_trunc('day', now() at time zone 'Asia/Tashkent') at time zone 'Asia/Tashkent';
begin
  if (select count(*) from class_replies r
       where r.class_id = new.class_id and r.student_id = new.student_id
         and r.created_at >= day_start) >= 50 then
    raise exception 'daily_message_limit';
  end if;
  if new.image_path is not null and (select count(*) from class_replies r
       where r.class_id = new.class_id and r.student_id = new.student_id
         and r.image_path is not null and r.created_at >= day_start) >= 10 then
    raise exception 'daily_photo_limit';
  end if;
  return new;
end;
$$;

-- 3. Private bucket: images only, 2 MB max.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat-photos', 'chat-photos', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

-- Read: the student of that conversation, or the class's teacher.
drop policy if exists chat_photos_read on storage.objects;
create policy chat_photos_read on storage.objects for select to authenticated
using (
  bucket_id = 'chat-photos'
  and (
    (storage.foldername(name))[2] = auth.uid()::text
    or exists (select 1 from public.classes c
                where c.id::text = (storage.foldername(name))[1] and c.teacher_id = auth.uid())
  )
);

-- Upload: the teacher into any of their class's conversations; a student only
-- into their own, only while chat is on and they're approved, at most 10 a
-- day (upload cap mirrors the message cap so orphan uploads can't pile up).
drop policy if exists chat_photos_upload on storage.objects;
create policy chat_photos_upload on storage.objects for insert to authenticated
with check (
  bucket_id = 'chat-photos'
  and (
    exists (select 1 from public.classes c
             where c.id::text = (storage.foldername(name))[1] and c.teacher_id = auth.uid())
    or (
      (storage.foldername(name))[2] = auth.uid()::text
      and exists (select 1 from public.class_members m
                   where m.class_id::text = (storage.foldername(name))[1]
                     and m.student_id = auth.uid() and m.status = 'approved')
      and exists (select 1 from public.classes c
                   where c.id::text = (storage.foldername(name))[1] and c.chat_enabled)
      and (select count(*) from storage.objects o
            where o.bucket_id = 'chat-photos' and o.owner = auth.uid()
              and o.created_at >= date_trunc('day', now() at time zone 'Asia/Tashkent') at time zone 'Asia/Tashkent') < 10
    )
  )
);
-- No update/delete policies: photos stay as sent until the 30-day cleanup.

-- 4. Push text for a photo message (no text to show).
create or replace function notify_push() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  payload jsonb;
  trigger_secret text;
begin
  begin
    select decrypted_secret into trigger_secret
      from vault.decrypted_secrets where name = 'push_trigger_secret';

    if tg_table_name = 'class_homework' then
      payload := jsonb_build_object(
        'kind', 'homework',
        'class_id', new.class_id,
        'student_ids', new.student_ids,
        'title', coalesce(new.collection_name, 'New homework')
      );
    elsif tg_table_name = 'class_targets' then
      payload := jsonb_build_object(
        'kind', 'target',
        'class_id', new.class_id,
        'student_ids', jsonb_build_array(new.student_id),
        'title', new.title
      );
    elsif tg_table_name = 'class_announcements' then
      payload := jsonb_build_object(
        'kind', 'announcement',
        'class_id', new.class_id,
        'message', new.message
      );
    elsif tg_table_name = 'class_members' and new.status = 'pending' then
      payload := jsonb_build_object(
        'kind', 'join_request',
        'class_id', new.class_id,
        'student_id', new.student_id
      );
    elsif tg_table_name = 'class_notes' then
      payload := jsonb_build_object(
        'kind', 'note',
        'class_id', new.class_id,
        'student_ids', jsonb_build_array(new.student_id),
        'message', coalesce(nullif(btrim(new.message), ''), '📷 Rasm')
      );
    elsif tg_table_name = 'class_replies' then
      payload := jsonb_build_object(
        'kind', 'reply',
        'class_id', new.class_id,
        'student_id', new.student_id,
        'message', coalesce(nullif(btrim(new.message), ''), '📷 Rasm')
      );
    end if;

    if payload is not null then
      perform net.http_post(
        url := 'https://jzozrqbzhagezlwncktf.supabase.co/functions/v1/send-push',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || trigger_secret
        ),
        body := payload
      );
    end if;
  exception when others then
    raise warning 'notify_push failed for %: %', tg_table_name, sqlerrm;
  end;

  return new;
end;
$$;

-- 5. Nightly cleanup at 03:30 Tashkent (22:30 UTC). Storage won't let SQL
-- delete files directly (protect_objects_delete), so the Edge Function
-- removes them through the Storage API with the service role. This lists
-- them for it (service role only).
create or replace function public.chat_photos_expired(p_days int default 30, p_limit int default 1000)
returns table(name text)
language sql
security definer
set search_path = public
as $$
  select o.name from storage.objects o
   where o.bucket_id = 'chat-photos'
     and o.created_at < now() - make_interval(days => p_days)
   order by o.created_at
   limit p_limit;
$$;

revoke all on function public.chat_photos_expired(int, int) from public, anon, authenticated;
grant execute on function public.chat_photos_expired(int, int) to service_role;

select cron.schedule(
  'chat-photos-cleanup',
  '30 22 * * *',
  $$
  select net.http_post(
    url := 'https://jzozrqbzhagezlwncktf.supabase.co/functions/v1/cleanup-chat-photos',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'push_trigger_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
