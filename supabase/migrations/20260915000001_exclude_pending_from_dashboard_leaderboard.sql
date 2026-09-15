-- get_class_dashboard and get_class_leaderboard both join class_members
-- without filtering status = 'approved' — a student with a pending join
-- request (not yet approved by the teacher) showed up as a full member:
-- counted in the teacher's roster/dashboard and ranked in the student-facing
-- leaderboard, even though they have no other access to the class (every
-- write path already gates on is_approved_class_member). This closes that
-- last read-side gap: a pending student should not appear anywhere in the
-- class until approved.
--
-- get_class_leaderboard's own "am I allowed to call this" check also only
-- verified *a* class_members row exists for the caller, not an approved
-- one — so a pending student could call the RPC directly and see the whole
-- class's ranking before they'd even been let in.

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
  where cm.class_id = p_class_id and cm.status = 'approved'
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
    where cm2.class_id = p_class_id and cm2.student_id = v_uid and cm2.status = 'approved'
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
  where cm.class_id = p_class_id and cm.status = 'approved'
  group by cm.student_id, cm.class_id, p.name, p.avatar_url, cm.class_xp
  order by coalesce(cm.class_xp, 0) desc
  limit 200;
end;
$function$;
