-- ─────────────────────────────────────────────────────────────────────────────
-- Auto homework: classes of 5 students or fewer are never held.
-- User's rule (2026-11-09): in a small class, units are assigned on schedule
-- whether or not the previous ones were finished. The "under half finished"
-- hold now applies only to classes with more than 5 approved students.
-- ─────────────────────────────────────────────────────────────────────────────

-- Same as 20261108000003, except for the v_members check.
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

  -- 1. Backlog cap (more than 5 students only): did at least half the class
  --    finish the previous batch?
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

    if v_members > 5 and v_finished * 2 < v_members then
      update class_auto_homework
         set last_run_on = p_today, last_status = 'held', last_count = 0
       where id = s.id;
      return 'held';
    end if;
  end if;

  -- 2. New units: not yet assigned to the whole class, in order or at random.
  if s.collection_name is not null then
    insert into class_homework (class_id, collection_name, day_number, modes,
                                due_date, student_ids, assigned_by, auto_schedule_id)
    select s.class_id, s.collection_name, x.d, s.modes, v_due, null, s.teacher_id, s.id
      from unnest(s.day_numbers) with ordinality as x(d, ord)
     where not exists (
       select 1 from class_homework h
        where h.class_id = s.class_id and h.collection_name = s.collection_name
          and h.day_number = x.d and h.student_ids is null)
     order by case when s.random_order then random() end, x.ord
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
