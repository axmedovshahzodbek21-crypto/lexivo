-- ─────────────────────────────────────────────────────────────────────────────
-- Class chat (teacher ↔ one student), limited free-tier version
-- Run in the Supabase SQL Editor — AFTER deploying the updated send-push
-- Edge Function (it needs to know the new 'reply' kind).
--
-- A conversation = one class + one student. Teacher messages are the
-- existing class_notes rows (so the Flutter app, Insights "Send" and note
-- push keep working unchanged); student messages go in class_replies.
-- Clients poll for new rows while a chat is open — no Realtime, so it
-- stays inside the free plan.
--
-- Limits for now: chat is off until the teacher turns it on per class;
-- students send at most 50 messages a day per class, 500 characters each.
-- Students can't edit or delete messages (kept for transparency).
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Per-class switch, off by default. Students read it with the class row.
alter table public.classes add column if not exists chat_enabled boolean not null default false;

create or replace function public.set_class_chat_enabled(p_class_id uuid, p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update classes set chat_enabled = p_enabled
   where id = p_class_id and teacher_id = auth.uid();
  if not found then
    raise exception 'not the teacher of this class';
  end if;
end;
$$;

revoke all on function public.set_class_chat_enabled(uuid, boolean) from public, anon;
grant execute on function public.set_class_chat_enabled(uuid, boolean) to authenticated;

-- 2. Student → teacher messages.
create table if not exists public.class_replies (
  id         uuid primary key default gen_random_uuid(),
  class_id   uuid not null references classes(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  message    text not null check (char_length(btrim(message)) between 1 and 500),
  created_at timestamptz not null default now(),
  read_at    timestamptz
);

create index if not exists class_replies_thread_idx
  on public.class_replies (class_id, student_id, created_at);

alter table public.class_replies enable row level security;

-- The student and the class's teacher read the conversation.
drop policy if exists class_replies_select on public.class_replies;
create policy class_replies_select
  on public.class_replies for select to authenticated
  using (
    student_id = auth.uid()
    or exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid())
  );

-- Only an approved student of a class with chat on, as themselves.
drop policy if exists class_replies_insert on public.class_replies;
create policy class_replies_insert
  on public.class_replies for insert to authenticated
  with check (
    student_id = auth.uid()
    and exists (select 1 from class_members m
                 where m.class_id = class_replies.class_id and m.student_id = auth.uid() and m.status = 'approved')
    and exists (select 1 from classes c where c.id = class_replies.class_id and c.chat_enabled)
  );

-- No update/delete policies: messages stay as sent. read_at is set only
-- through mark_class_replies_read below.
grant select, insert on public.class_replies to authenticated;

-- 3. Daily cap: 50 messages per student per class per Tashkent day.
create or replace function public.class_replies_daily_cap()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select count(*) from class_replies r
       where r.class_id = new.class_id and r.student_id = new.student_id
         and r.created_at >= (date_trunc('day', now() at time zone 'Asia/Tashkent') at time zone 'Asia/Tashkent')) >= 50 then
    raise exception 'daily_message_limit';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_class_replies_daily_cap on public.class_replies;
create trigger trg_class_replies_daily_cap
  before insert on public.class_replies
  for each row execute function public.class_replies_daily_cap();

-- 4. The teacher marks one student's messages read.
create or replace function public.mark_class_replies_read(p_class_id uuid, p_student_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update class_replies r
     set read_at = now()
   where r.class_id = p_class_id
     and r.student_id = p_student_id
     and r.read_at is null
     and exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid());
$$;

revoke all on function public.mark_class_replies_read(uuid, uuid) from public, anon;
grant execute on function public.mark_class_replies_read(uuid, uuid) to authenticated;

-- 5. Push the teacher when a student writes. Extends notify_push()
-- (latest: 20261018000001_notify_class_notes.sql) with a 'reply' kind.
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
        'message', new.message
      );
    elsif tg_table_name = 'class_replies' then
      payload := jsonb_build_object(
        'kind', 'reply',
        'class_id', new.class_id,
        'student_id', new.student_id,
        'message', new.message
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

drop trigger if exists trg_notify_reply on public.class_replies;
create trigger trg_notify_reply
  after insert on public.class_replies
  for each row execute function notify_push();
