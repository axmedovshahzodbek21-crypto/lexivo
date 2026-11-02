-- ─────────────────────────────────────────────────────────────────────────────
-- Fix for 20261102000002: every chat photo upload failed with
-- "infinite recursion detected in policy for relation objects" — the upload
-- policy counted today's uploads by reading storage.objects itself. The
-- count now goes through a SECURITY DEFINER function (no RLS inside), so
-- the rule is unchanged: a student uploads at most 10 photos a day.
-- Also: inside "select ... from public.classes c", a bare `name` resolved to
-- classes.name (the class title), not the file path, so the teacher checks
-- never matched. Both policies now say objects.name.
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.chat_photos_uploaded_today()
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int from storage.objects o
   where o.bucket_id = 'chat-photos' and o.owner = auth.uid()
     and o.created_at >= date_trunc('day', now() at time zone 'Asia/Tashkent') at time zone 'Asia/Tashkent';
$$;

revoke all on function public.chat_photos_uploaded_today() from public, anon;
grant execute on function public.chat_photos_uploaded_today() to authenticated;

drop policy if exists chat_photos_read on storage.objects;
create policy chat_photos_read on storage.objects for select to authenticated
using (
  bucket_id = 'chat-photos'
  and (
    (storage.foldername(objects.name))[2] = auth.uid()::text
    or exists (select 1 from public.classes c
                where c.id::text = (storage.foldername(objects.name))[1] and c.teacher_id = auth.uid())
  )
);

drop policy if exists chat_photos_upload on storage.objects;
create policy chat_photos_upload on storage.objects for insert to authenticated
with check (
  bucket_id = 'chat-photos'
  and (
    exists (select 1 from public.classes c
             where c.id::text = (storage.foldername(objects.name))[1] and c.teacher_id = auth.uid())
    or (
      (storage.foldername(objects.name))[2] = auth.uid()::text
      and exists (select 1 from public.class_members m
                   where m.class_id::text = (storage.foldername(objects.name))[1]
                     and m.student_id = auth.uid() and m.status = 'approved')
      and exists (select 1 from public.classes c
                   where c.id::text = (storage.foldername(objects.name))[1] and c.chat_enabled)
      and public.chat_photos_uploaded_today() < 10
    )
  )
);
