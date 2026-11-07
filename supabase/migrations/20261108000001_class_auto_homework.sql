-- ─────────────────────────────────────────────────────────────────────────────
-- Auto homework: a teacher sets "X units a day" once, units are assigned
-- every day by a nightly job.
-- Run in the Supabase SQL Editor. No Edge Function redeploy needed (the push
-- reuses send-push's existing 'homework' kind).
--
-- User's rules (2026-11-08):
--   * Whole-class pace: everyone gets the same unit on the same day.
--   * Sources: built-in collections and the teacher's library folders.
--   * Backlog cap: if fewer than half the approved students finished every
--     unit of the previous auto batch, today's release is HELD (status
--     'held'); it resumes by itself once the class catches up.
--   * Review day: every Nth release day gives no new unit; instead each unit
--     released since the last review day gets a quiz-only homework row
--     (is_review = true).
--   * Release at 00:02 Tashkent; one push per schedule at 08:01.
--   * Units already assigned to the whole class are skipped.
--
-- Turn the jobs off:
--   select cron.unschedule('auto-homework-daily');
--   select cron.unschedule('auto-homework-morning-push');
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.class_auto_homework (
  id                uuid primary key default gen_random_uuid(),
  class_id          uuid not null references classes(id) on delete cascade,
  teacher_id        uuid not null references auth.users(id) on delete cascade,
  collection_name   text,
  day_numbers       int[],              -- collections only, in order (units with words): their content lives in app code
  folder_id         uuid references teacher_folders(id) on delete cascade,
  units_per_day     int  not null default 1 check (units_per_day between 1 and 10),
  weekdays          int[] not null default '{1,2,3,4,5,6}'   -- ISO: 1 = Mon … 7 = Sun
                    check (cardinality(weekdays) > 0 and weekdays <@ '{1,2,3,4,5,6,7}'::int[]),
  modes             text[] not null default '{learn,flashcard,quiz}'
                    check (cardinality(modes) > 0 and modes <@ '{learn,flashcard,quiz,match}'::text[]),
  due_days          int check (due_days between 0 and 14),   -- null = no deadline
  review_every      int check (review_every between 2 and 14), -- null = no review days
  paused            boolean not null default false,
  start_date        date not null default (now() at time zone 'Asia/Tashkent')::date,
  last_run_on       date,
  last_status       text check (last_status in ('released', 'review', 'held', 'done')),
  last_count        int not null default 0,
  days_since_review int not null default 0,
  push_pending      boolean not null default false,
  created_at        timestamptz not null default now(),
  constraint class_auto_homework_one_source check (
    (collection_name is not null and cardinality(day_numbers) > 0 and folder_id is null)
    or (folder_id is not null and collection_name is null and day_numbers is null)
  ),
  unique (class_id, collection_name),
  unique (class_id, folder_id)
);

alter table public.class_homework
  add column if not exists auto_schedule_id uuid references public.class_auto_homework(id) on delete set null,
  add column if not exists is_review boolean not null default false;

create index if not exists class_homework_auto_schedule_idx
  on public.class_homework (auto_schedule_id) where auto_schedule_id is not null;

-- RLS: the class's teacher only. A folder schedule needs the teacher's own
-- folder, already assigned to this class (students can only read units of
-- assigned folders). Students never read this table.
alter table public.class_auto_homework enable row level security;

drop policy if exists class_auto_homework_teacher on public.class_auto_homework;
create policy class_auto_homework_teacher on public.class_auto_homework
  for all to authenticated
  using (
    teacher_id = auth.uid()
    and exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid())
  )
  with check (
    teacher_id = auth.uid()
    and exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid())
    and (class_auto_homework.folder_id is null or exists (
      select 1 from teacher_folders f
        join class_library_assignments a on a.folder_id = f.id and a.class_id = class_auto_homework.class_id
       where f.id = class_auto_homework.folder_id and f.teacher_id = auth.uid()))
  );

revoke all on public.class_auto_homework from anon, authenticated;
grant select, insert, update, delete on public.class_auto_homework to authenticated;

-- ── One day's step for one schedule ─────────────────────────────────────────
-- Returns the status it recorded. Idempotent per day (last_run_on).
create or replace function public.auto_homework_step(p_id uuid, p_today date)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  s            class_auto_homework%rowtype;
  v_due        date;
  v_last_batch date;
  v_members    int;
  v_finished   int;
  v_since      timestamptz;
  v_count      int := 0;
begin
  select * into s from class_auto_homework where id = p_id for update;
  if not found then return null; end if;
  if s.last_run_on = p_today then return s.last_status; end if;

  v_due := case when s.due_days is null then null else p_today + s.due_days end;

  -- 1. Backlog cap: did at least half the class finish the previous batch?
  select max((created_at at time zone 'Asia/Tashkent')::date) into v_last_batch
    from class_homework where auto_schedule_id = s.id;

  if v_last_batch is not null and v_last_batch < p_today then
    select count(*) into v_members
      from class_members where class_id = s.class_id and status = 'approved';

    select count(*) into v_finished
      from class_members m
     where m.class_id = s.class_id and m.status = 'approved'
       and not exists (
         select 1 from class_homework h
          where h.auto_schedule_id = s.id
            and (h.created_at at time zone 'Asia/Tashkent')::date = v_last_batch
            and (select count(distinct p.mode) from class_homework_progress p
                  where p.homework_id = h.id and p.student_id = m.student_id
                    and p.mode = any(h.modes)) < cardinality(h.modes));

    if v_members > 0 and v_finished * 2 < v_members then
      update class_auto_homework
         set last_run_on = p_today, last_status = 'held', last_count = 0
       where id = s.id;
      return 'held';
    end if;
  end if;

  -- 2. Review day: quiz-only copies of everything released since the last one.
  if s.review_every is not null and s.days_since_review >= s.review_every - 1 then
    select max(created_at) into v_since
      from class_homework where auto_schedule_id = s.id and is_review;

    insert into class_homework (class_id, collection_name, day_number, unit_id, modes,
                                due_date, student_ids, assigned_by, auto_schedule_id, is_review)
    select s.class_id, h.collection_name, h.day_number, h.unit_id, '{quiz}',
           v_due, null, s.teacher_id, s.id, true
      from class_homework h
     where h.auto_schedule_id = s.id and not h.is_review
       and h.created_at > coalesce(v_since, '-infinity'::timestamptz)
     order by h.created_at, h.day_number;
    get diagnostics v_count = row_count;

    if v_count > 0 then
      update class_auto_homework
         set last_run_on = p_today, last_status = 'review', last_count = v_count,
             days_since_review = 0, push_pending = true
       where id = s.id;
      return 'review';
    end if;
  end if;

  -- 3. New units: the first ones not yet assigned to the whole class.
  if s.collection_name is not null then
    insert into class_homework (class_id, collection_name, day_number, modes,
                                due_date, student_ids, assigned_by, auto_schedule_id)
    select s.class_id, s.collection_name, x.d, s.modes, v_due, null, s.teacher_id, s.id
      from unnest(s.day_numbers) with ordinality as x(d, ord)
     where not exists (
       select 1 from class_homework h
        where h.class_id = s.class_id and h.collection_name = s.collection_name
          and h.day_number = x.d and h.student_ids is null and not h.is_review)
     order by x.ord
     limit s.units_per_day;
  else
    insert into class_homework (class_id, unit_id, modes,
                                due_date, student_ids, assigned_by, auto_schedule_id)
    select s.class_id, u.id, s.modes, v_due, null, s.teacher_id, s.id
      from teacher_units u
     where u.folder_id = s.folder_id
       and exists (select 1 from class_library_assignments a
                    where a.folder_id = s.folder_id and a.class_id = s.class_id)
       and not exists (
         select 1 from class_homework h
          where h.class_id = s.class_id and h.unit_id = u.id
            and h.student_ids is null and not h.is_review)
     order by u.position, u.created_at
     limit s.units_per_day;
  end if;
  get diagnostics v_count = row_count;

  update class_auto_homework
     set last_run_on = p_today,
         last_status = case when v_count > 0 then 'released' else 'done' end,
         last_count = v_count,
         days_since_review = days_since_review + case when v_count > 0 then 1 else 0 end,
         push_pending = v_count > 0
   where id = s.id;
  return case when v_count > 0 then 'released' else 'done' end;
end;
$$;

revoke execute on function public.auto_homework_step(uuid, date) from public, anon, authenticated;

-- ── Nightly run over every active schedule ─────────────────────────────────
create or replace function public.run_daily_auto_homework(
  p_today date default (now() at time zone 'Asia/Tashkent')::date
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  for r in
    select id from class_auto_homework
     where not paused
       and start_date <= p_today
       and extract(isodow from p_today)::int = any(weekdays)
       and last_run_on is distinct from p_today
  loop
    begin
      perform auto_homework_step(r.id, p_today);
    exception when others then
      raise warning 'auto homework failed for %: %', r.id, sqlerrm;
    end;
  end loop;
end;
$$;

revoke execute on function public.run_daily_auto_homework(date) from public, anon, authenticated;

-- ── Push (one per schedule) ────────────────────────────────────────────────
create or replace function public.auto_homework_push(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  s              class_auto_homework%rowtype;
  v_source       text;
  trigger_secret text;
begin
  update class_auto_homework set push_pending = false
   where id = p_id and push_pending
  returning * into s;
  if not found then return; end if;

  v_source := coalesce(s.collection_name,
                       (select name from teacher_folders where id = s.folder_id), 'Uy vazifasi');

  begin
    select decrypted_secret into trigger_secret
      from vault.decrypted_secrets where name = 'push_trigger_secret';
    perform net.http_post(
      url := 'https://jzozrqbzhagezlwncktf.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || trigger_secret
      ),
      body := jsonb_build_object(
        'kind', 'homework',
        'class_id', s.class_id,
        'student_ids', null,
        'title', v_source || ' · ' || case when s.last_status = 'review'
                                          then 'Takrorlash kuni'
                                          else s.last_count || ' ta yangi unit' end
      )
    );
  exception when others then
    raise warning 'auto homework push failed for %: %', p_id, sqlerrm;
  end;
end;
$$;

revoke execute on function public.auto_homework_push(uuid) from public, anon, authenticated;

create or replace function public.send_auto_homework_morning_push()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  for r in select id from class_auto_homework where push_pending loop
    perform auto_homework_push(r.id);
  end loop;
end;
$$;

revoke execute on function public.send_auto_homework_morning_push() from public, anon, authenticated;

-- ── Teacher: "start today" right after saving a schedule ───────────────────
-- Runs today's step now (if today is one of its days) and pushes at once.
create or replace function public.auto_homework_run_today(p_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today  date := (now() at time zone 'Asia/Tashkent')::date;
  v_status text;
begin
  if not exists (
    select 1 from class_auto_homework s join classes c on c.id = s.class_id
     where s.id = p_id and s.teacher_id = auth.uid() and c.teacher_id = auth.uid()
       and not s.paused and s.start_date <= v_today
       and extract(isodow from v_today)::int = any(s.weekdays)
  ) then
    return null;
  end if;
  v_status := auto_homework_step(p_id, v_today);
  perform auto_homework_push(p_id);
  return v_status;
end;
$$;

revoke execute on function public.auto_homework_run_today(uuid) from public, anon;
grant execute on function public.auto_homework_run_today(uuid) to authenticated;

-- ── Auto rows don't push one by one at midnight ────────────────────────────
-- Same as 20261102000002_class_chat_photos.sql, plus the auto_schedule_id
-- check in the class_homework branch.
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
      if new.auto_schedule_id is null then
        payload := jsonb_build_object(
          'kind', 'homework',
          'class_id', new.class_id,
          'student_ids', new.student_ids,
          'title', coalesce(new.collection_name, 'New homework')
        );
      end if;
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

-- 19:02 UTC = 00:02 Tashkent; 03:01 UTC = 08:01 Tashkent (no DST).
select cron.schedule('auto-homework-daily', '2 19 * * *',
  $$ select public.run_daily_auto_homework(); $$);
select cron.schedule('auto-homework-morning-push', '1 3 * * *',
  $$ select public.send_auto_homework_morning_push(); $$);
