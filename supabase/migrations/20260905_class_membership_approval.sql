-- Class join approval gate.
--
-- Joining a class by code used to grant instant access. Anyone who obtained
-- the join code (e.g. a student's friend it wasn't meant for) could join and
-- immediately see the teacher's class content. This adds a `status` column
-- to class_members so a join creates a 'pending' row instead of an active
-- one, and every place that checks "is this user a member of this class"
-- (RLS policies + SECURITY DEFINER RPCs, which bypass RLS) is updated to
-- also require status = 'approved'.
--
-- Existing rows default to 'approved' so current students are unaffected.

alter table class_members
  add column if not exists status text not null default 'approved'
  check (status in ('pending', 'approved'));

create or replace function is_approved_class_member(p_class_id uuid, p_student_id uuid)
returns boolean
language sql
stable
as $$
  select exists(
    select 1 from class_members
     where class_id = p_class_id and student_id = p_student_id and status = 'approved'
  );
$$;

-- Let teachers flip a pending member to approved (rejection reuses the
-- existing "Teachers remove class members" delete policy).
do $$ begin
  create policy "Teachers approve class members" on class_members for update
    using (exists (
      select 1 from classes where classes.id = class_members.class_id and classes.teacher_id = auth.uid()
    ))
    with check (status in ('pending', 'approved'));
exception when duplicate_object then null; end $$;

-- Re-point the 7 baseline RLS policies (from 20260821_baseline_homework_curriculum_schema.sql)
-- at the approval-aware helper instead of an unfiltered membership check.

drop policy if exists student_read_assigned_folders on teacher_folders;
create policy student_read_assigned_folders on teacher_folders for select
  using (exists (
    select 1 from class_library_assignments cla
    join class_members cm on cm.class_id = cla.class_id
    where cla.folder_id = teacher_folders.id
      and cm.student_id = auth.uid()
      and is_approved_class_member(cla.class_id, auth.uid())
  ));

drop policy if exists student_read_assigned_units on teacher_units;
create policy student_read_assigned_units on teacher_units for select
  using (exists (
    select 1 from class_library_assignments cla
    join class_members cm on cm.class_id = cla.class_id
    where cla.folder_id = teacher_units.folder_id
      and cm.student_id = auth.uid()
      and is_approved_class_member(cla.class_id, auth.uid())
  ));

drop policy if exists student_read_assigned_unit_words on teacher_unit_words;
create policy student_read_assigned_unit_words on teacher_unit_words for select
  using (exists (
    select 1 from teacher_units tu
    join class_library_assignments cla on cla.folder_id = tu.folder_id
    join class_members cm on cm.class_id = cla.class_id
    where tu.id = teacher_unit_words.unit_id
      and cm.student_id = auth.uid()
      and is_approved_class_member(cla.class_id, auth.uid())
  ));

drop policy if exists student_read_class_word_units on class_word_units;
create policy student_read_class_word_units on class_word_units for select
  using (is_approved_class_member(class_word_units.class_id, auth.uid()));

drop policy if exists student_read_class_words on class_words;
create policy student_read_class_words on class_words for select
  using (is_approved_class_member(class_words.class_id, auth.uid()));

drop policy if exists student_read_homework on class_homework;
create policy student_read_homework on class_homework for select
  using (is_approved_class_member(class_homework.class_id, auth.uid()));

drop policy if exists student_read_class_homework on class_homework;
create policy student_read_class_homework on class_homework for select
  using (is_approved_class_member(class_homework.class_id, auth.uid()));

-- Web-only baseline policy (20260831_students_read_class_teacher_profile.sql).
drop policy if exists students_read_class_teacher_profile on profiles;
do $$ begin
  create policy students_read_class_teacher_profile on profiles for select
    using (exists (
      select 1 from classes c
      join class_members m on m.class_id = c.id
      where c.teacher_id = profiles.id
        and is_approved_class_member(c.id, auth.uid())
    ));
exception when duplicate_object then null; end $$;

-- advance_class_srs_word (5-arg, latest per 20260827_class_srs_no_auto_unlearn.sql).
-- The 4-arg overload is an unchanged thin wrapper that forwards here.
create or replace function public.advance_class_srs_word(
  p_user_id uuid,
  p_class_id uuid,
  p_word text,
  p_knew boolean,
  p_today date
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_stage int;
  v_fail_streak int;
  v_next int;
  v_next_streak int;
  v_interval int;
  v_intervals int[] := array[1, 3, 7, 14, 30];
  v_today date;
begin
  if auth.uid() is null or auth.uid() != p_user_id then
    raise exception 'not authorized';
  end if;

  if not is_approved_class_member(p_class_id, p_user_id) then
    raise exception 'not a member of this class';
  end if;

  v_today := p_today;
  if v_today is null or v_today < current_date - 2 or v_today > current_date + 2 then
    v_today := current_date;
  end if;

  select id, stage, coalesce(fail_streak, 0)
    into v_id, v_stage, v_fail_streak
  from class_srs_states
  where user_id = p_user_id and class_id = p_class_id and word = p_word
  for update;

  if v_id is null then
    return;
  end if;

  v_next := case when p_knew then least(v_stage + 1, 5) else greatest(v_stage - 1, 0) end;
  v_interval := case when v_next >= 5 then 36500 else v_intervals[v_next + 1] end;
  v_next_streak := case
                     when p_knew then 0
                     when v_next = 0 then least(v_fail_streak + 1, 9)
                     else 0
                   end;

  update class_srs_states
  set stage = v_next,
      next_due = v_today + v_interval,
      last_reviewed = now(),
      fail_streak = v_next_streak
  where id = v_id;

  if p_knew and v_next > v_stage then
    perform record_class_xp(p_user_id, p_class_id, 2, 'SRS Review');
  end if;
end;
$$;

grant execute on function advance_class_srs_word(uuid, uuid, text, boolean, date) to authenticated;

-- record_class_word_learned (latest per 20260820_fix_record_class_word_learned_auth.sql).
create or replace function record_class_word_learned(
  p_student_id uuid,
  p_class_id uuid,
  p_word text,
  p_translation text,
  p_next_due date,
  p_xp int,
  p_reason text default 'Learn'
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_new boolean;
  v_xp int;
begin
  if auth.uid() is null or auth.uid() != p_student_id then
    raise exception 'not authorized';
  end if;

  if not is_approved_class_member(p_class_id, p_student_id) then
    raise exception 'not a member of this class';
  end if;

  insert into class_srs_states (user_id, class_id, word, translation, stage, next_due)
  values (p_student_id, p_class_id, p_word, p_translation, 0, p_next_due)
  on conflict (user_id, class_id, word) do nothing;

  v_is_new := found;

  if v_is_new and p_xp > 0 then
    v_xp := least(greatest(p_xp, 0), 10);
    update class_members
      set class_xp = coalesce(class_xp, 0) + v_xp
      where student_id = p_student_id and class_id = p_class_id;
  end if;

  return v_is_new;
end;
$$;

grant execute on function record_class_word_learned(uuid, uuid, text, text, date, int, text) to authenticated;

-- record_class_xp (latest per 20260827_class_review_xp_server_awarded.sql).
-- The old body relies on UPDATE...WHERE matching zero rows -> "not found" to
-- detect non-membership; adding status filters to that WHERE would silently
-- treat a pending member as "not a member" (the desired behavior), but an
-- explicit check up front gives a clearer error path.
create or replace function public.record_class_xp(
  p_student_id uuid,
  p_class_id uuid,
  p_xp integer,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today_review_xp int;
  v_review_daily_cap constant int := 200;
begin
  if p_xp <= 0 then
    return;
  end if;

  if auth.uid() is null or auth.uid() != p_student_id then
    raise exception 'not authorized';
  end if;

  if not is_approved_class_member(p_class_id, p_student_id) then
    raise exception 'not a member of this class';
  end if;

  if p_reason = 'SRS Review' then
    select coalesce(sum(amount), 0) into v_today_review_xp
    from class_xp_history
    where user_id = p_student_id
      and class_id = p_class_id
      and reason = 'SRS Review'
      and created_at >= date_trunc('day', now());
    if v_today_review_xp >= v_review_daily_cap then
      return;
    end if;
  end if;

  update class_members
     set class_xp = coalesce(class_xp, 0) + p_xp
   where student_id = p_student_id and class_id = p_class_id;

  if not found then
    raise exception 'not a member of this class';
  end if;

  insert into class_xp_history (user_id, class_id, amount, reason)
  values (p_student_id, p_class_id, p_xp, p_reason);
end;
$$;

grant execute on function record_class_xp(uuid, uuid, integer, text) to authenticated;

-- record_class_homework_progress (latest per lexivo-web's
-- 20260904_class_homework_learn_xp_per_word.sql, not present in lexivo's
-- migration history — included here so both repos converge on it).
create or replace function record_class_homework_progress(
  p_homework_id uuid,
  p_mode text,
  p_client_word_count integer default null
)
returns table(recorded boolean, xp_awarded integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_hw record;
  v_word_count integer := 0;
  v_xp integer := 0;
  v_xp_per_word integer;
  v_row_count integer;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select id, class_id, unit_id, class_unit_id, collection_name, day_number,
         passage_id, modes, student_ids
    into v_hw
    from class_homework
   where id = p_homework_id;

  if not found then
    raise exception 'homework not found';
  end if;

  if v_hw.student_ids is not null and not (v_uid = any(v_hw.student_ids)) then
    raise exception 'not assigned this homework';
  end if;

  if not is_approved_class_member(v_hw.class_id, v_uid) then
    raise exception 'not a member of this class';
  end if;

  if not (
    p_mode = any(coalesce(v_hw.modes, array[]::text[]))
    or (p_mode = 'read' and v_hw.passage_id is not null)
  ) then
    raise exception 'invalid mode for this homework';
  end if;

  insert into class_homework_progress (homework_id, student_id, mode)
  values (p_homework_id, v_uid, p_mode)
  on conflict (homework_id, student_id, mode) do nothing;
  get diagnostics v_row_count = row_count;

  if v_row_count = 0 then
    return query select false, 0;
    return;
  end if;

  if v_hw.passage_id is not null then
    v_xp := 15;
  else
    if v_hw.class_unit_id is not null then
      select count(*) into v_word_count from class_words where unit_id = v_hw.class_unit_id;
    elsif v_hw.unit_id is not null then
      select count(*) into v_word_count from teacher_unit_words where unit_id = v_hw.unit_id;
    else
      v_word_count := least(greatest(coalesce(p_client_word_count, 0), 0), 50);
    end if;

    v_xp_per_word := case p_mode
      when 'learn' then 0
      when 'flashcard' then 3
      when 'quiz' then 5
      when 'match' then 4
      else 3
    end;
    v_xp := v_word_count * v_xp_per_word;
  end if;

  if v_xp > 0 then
    update class_members
       set class_xp = coalesce(class_xp, 0) + v_xp
     where class_id = v_hw.class_id and student_id = v_uid;

    insert into class_xp_history (user_id, class_id, amount, reason)
    values (v_uid, v_hw.class_id, v_xp, p_mode);
  end if;

  insert into class_study_days (student_id, class_id, study_date)
  values (v_uid, v_hw.class_id, current_date)
  on conflict (student_id, class_id, study_date) do nothing;

  return query select true, v_xp;
end;
$$;

grant execute on function record_class_homework_progress(uuid, text, integer) to authenticated;
