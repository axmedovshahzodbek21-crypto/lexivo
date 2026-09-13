-- get_class_activity and get_student_study_calendar both read from
-- unit_completions, which nothing has written to since 2026-07-27 (its
-- trigger, log_unit_completion, fired on a `unit_progress` table that was
-- since dropped in favor of the unit_progress JSONB column on user_data —
-- the trigger went with it). Both RPCs also only filtered by "who's in the
-- class" via class_members, not "what was done for this class" — the same
-- leak pattern fixed elsewhere in this series.
--
-- Rather than reviving unit_completions (which was never class-scoped to
-- begin with — there's no way to know which class, if any, a personal
-- collection completion belonged to), redirect both to data that already
-- carries real class attribution:
--
-- - get_student_study_calendar's caller (_StreakCalendarSheet in
--   class_dashboard_screen.dart) only ever reads `study_date`, never
--   `completion_count` — so class_study_days (already correctly scoped,
--   same table the student's own streak screen uses) is a direct
--   replacement.
-- - get_class_activity now reads learn_session_analytics filtered by the
--   class_id added in the prior migration. This narrows the feed to Learn
--   completions only (flashcard/quiz completions were never separately
--   tracked anywhere class-scoped, so there's nothing else to source them
--   from) — a real, live, correctly-scoped feed instead of a stale,
--   globally-scoped one. The caller's completion_type icon logic already
--   only special-cases 'daily'/'collection' (never matched the old
--   'learn'/'flashcard'/'quiz' values either), so this is not a visible
--   regression.

create or replace function public.get_class_activity(p_class_id uuid, p_limit integer default 40)
 returns table(student_name text, avatar_url text, completion_type text, collection_name text, day_number integer, completed_at timestamp with time zone)
 language plpgsql
 security definer
as $function$
declare
  v_teacher_id uuid;
begin
  select teacher_id into v_teacher_id from classes where id = p_class_id;
  if v_teacher_id is null or v_teacher_id != auth.uid() then return; end if;
  return query
  select pr.name::text, pr.avatar_url::text, 'learn'::text,
         lsa.collection_name, lsa.day_number, lsa.completed_at
  from learn_session_analytics lsa
  join profiles pr on pr.id = lsa.student_id
  where lsa.class_id = p_class_id
    and lsa.completed_at is not null
  order by lsa.completed_at desc
  limit p_limit;
end;
$function$;

create or replace function public.get_student_study_calendar(p_class_id uuid, p_student_id uuid)
 returns table(study_date date, completion_count integer)
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if not exists (select 1 from classes where id = p_class_id and teacher_id = auth.uid())
  then raise exception 'Not authorized'; end if;
  return query
  select csd.study_date, 1 as completion_count
  from class_study_days csd
  where csd.student_id = p_student_id
    and csd.class_id = p_class_id
    and csd.study_date >= current_date - interval '70 days'
  order by csd.study_date;
end;
$function$;
