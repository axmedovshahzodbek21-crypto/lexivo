-- get_class_dashboard and get_class_leaderboard were joining class_members
-- onto user_stats (streak) and learned_words (total_words) — both are
-- global per-user tables with no class_id. A student's whole-app streak
-- and total-learned-word count showed up identically in every class they
-- belonged to, instead of reflecting activity within that specific class.
--
-- Fix: streak now comes from class_study_days (the same table the
-- student-facing class streak screen already uses correctly), and
-- total_words now comes from class_srs_states (a row is inserted there the
-- moment a word is first learned via that class, by record_class_word_learned).
--
-- class_current_streak is factored out as a shared helper so the
-- consecutive-day-count logic exists in exactly one place, rather than
-- risking the drift that already happened once between the app's client-side
-- streak implementations (see date_utils.dart's streakAdjustedNow comment).

create or replace function public.class_current_streak(p_student_id uuid, p_class_id uuid)
returns integer
language sql
stable
as $$
  with days as (
    select study_date
    from class_study_days
    where student_id = p_student_id and class_id = p_class_id
      and study_date <= current_date
  ),
  grouped as (
    select study_date,
           study_date - (row_number() over (order by study_date desc))::int as grp
    from days
  )
  select case
    when not exists (select 1 from days where study_date >= current_date - 1) then 0
    else (
      select count(*)::integer from grouped
      where grp = (select grp from grouped order by study_date desc limit 1)
    )
  end;
$$;

create or replace function public.get_class_dashboard(p_class_id uuid)
 returns table(student_id uuid, name text, avatar_url text, xp integer, streak integer, last_study_date text, total_words bigint, collection_progress jsonb, total_units_sum integer)
 language plpgsql
 security definer
as $function$
declare
  v_total_units integer;
begin
  if not exists (select 1 from classes where id = p_class_id and teacher_id = auth.uid())
  then raise exception 'Not authorized'; end if;

  select coalesce(sum(c.total_units), 0)::integer into v_total_units from collections c;

  return query
  select
    cm.student_id,
    coalesce(p.name, 'Learner')::text,
    p.avatar_url::text,
    coalesce(cm.class_xp, 0)::integer,
    class_current_streak(cm.student_id, cm.class_id),
    (select max(csd.study_date) from class_study_days csd
       where csd.student_id = cm.student_id and csd.class_id = cm.class_id)::text,
    coalesce(cw.cnt, 0)::bigint,
    coalesce(cp.progress, '{}'::jsonb),
    v_total_units
  from class_members cm
  left join profiles p on p.id = cm.student_id
  left join (
    select user_id, class_id, count(*)::bigint as cnt
    from class_srs_states
    group by user_id, class_id
  ) cw on cw.user_id = cm.student_id and cw.class_id = cm.class_id
  left join (
    select up.user_id, jsonb_object_agg(up.collection_name, up.cnt) as progress
    from (
      select
        ud.id as user_id,
        regexp_replace(kv.key, '_[0-9]+$', '') as collection_name,
        count(*)::integer as cnt
      from user_data ud
      cross join lateral jsonb_each(coalesce(ud.unit_progress, '{}'::jsonb)) as kv(key, value)
      where (kv.value->>'learnDone')::boolean is true
        and regexp_replace(kv.key, '_[0-9]+$', '') in (select collection_name from collections)
      group by ud.id, regexp_replace(kv.key, '_[0-9]+$', '')
    ) up
    group by up.user_id
  ) cp on cp.user_id = cm.student_id
  where cm.class_id = p_class_id
  order by coalesce(cm.class_xp, 0) desc;
end;
$function$;

create or replace function public.get_class_leaderboard(p_class_id uuid)
 returns table(student_id uuid, name text, avatar_url text, xp bigint, streak integer, total_words bigint)
 language plpgsql
 security definer
as $function$
declare
  v_uid uuid := auth.uid();
begin
  if not exists (
    select 1 from class_members cm2
    where cm2.class_id = p_class_id and cm2.student_id = v_uid
    union all
    select 1 from classes c2
    where c2.id = p_class_id and c2.teacher_id = v_uid
  ) then return; end if;

  return query
  select
    cm.student_id,
    p.name::text,
    p.avatar_url::text,
    coalesce(cm.class_xp, 0)::bigint as xp,
    class_current_streak(cm.student_id, cm.class_id) as streak,
    count(distinct css.word)::bigint as total_words
  from class_members cm
  join profiles p on p.id = cm.student_id
  left join class_srs_states css on css.user_id = cm.student_id and css.class_id = cm.class_id
  where cm.class_id = p_class_id
  group by cm.student_id, p.name, p.avatar_url, cm.class_xp
  order by coalesce(cm.class_xp, 0) desc
  limit 200;
end;
$function$;
