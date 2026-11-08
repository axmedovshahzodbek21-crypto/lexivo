-- ─────────────────────────────────────────────────────────────────────────────
-- Auto homework: remove review days.
-- User's decision (2026-11-08): class Review (SRS) already brings every learned
-- word back at +1/+3/+7/+14/+30, so a quiz-only "review day" only added work.
-- The job now gives new units and nothing else.
--
-- class_homework.is_review, class_auto_homework.review_every and
-- days_since_review are left in place, unused: the web and app builds from
-- before this change still select them. Safe to drop once old APKs are gone.
-- ─────────────────────────────────────────────────────────────────────────────

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

  -- 2. New units: the first ones not yet assigned to the whole class.
  if s.collection_name is not null then
    insert into class_homework (class_id, collection_name, day_number, modes,
                                due_date, student_ids, assigned_by, auto_schedule_id)
    select s.class_id, s.collection_name, x.d, s.modes, v_due, null, s.teacher_id, s.id
      from unnest(s.day_numbers) with ordinality as x(d, ord)
     where not exists (
       select 1 from class_homework h
        where h.class_id = s.class_id and h.collection_name = s.collection_name
          and h.day_number = x.d and h.student_ids is null)
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
            and h.student_ids is null)
     order by case when s.random_order then random() end, u.position, u.created_at
     limit s.units_per_day;
  end if;
  get diagnostics v_count = row_count;

  update class_auto_homework
     set last_run_on = p_today,
         last_status = case when v_count > 0 then 'released' else 'done' end,
         last_count = v_count,
         push_pending = v_count > 0
   where id = s.id;
  return case when v_count > 0 then 'released' else 'done' end;
end;
$$;

revoke execute on function public.auto_homework_step(uuid, date) from public, anon, authenticated;

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
        'title', v_source || ' · ' || s.last_count || ' ta yangi unit'
      )
    );
  exception when others then
    raise warning 'auto homework push failed for %: %', p_id, sqlerrm;
  end;
end;
$$;

revoke execute on function public.auto_homework_push(uuid) from public, anon, authenticated;
