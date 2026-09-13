-- get_class_leaderboard (fixed for class-scoping in 20260913000001) has been
-- throwing a hard SQL error for every real caller since that migration:
-- "column cm.class_id must appear in the GROUP BY clause or be used in an
-- aggregate function". class_current_streak(cm.student_id, cm.class_id) in
-- the SELECT list references cm.class_id, which isn't in the GROUP BY —
-- Postgres doesn't exempt it just because the WHERE clause pins it to a
-- single value, only when it's functionally dependent via a primary key.
--
-- Every prior verification of this function only ever hit its early-return
-- auth guard (auth.uid() was null in that context), never actually reaching
-- the broken SELECT — so this shipped and stayed broken undetected until
-- tested as a real authenticated user.
--
-- Fix: add cm.class_id to the GROUP BY. Semantically identical result set
-- (class_id is already constant per the WHERE filter) — this is a pure
-- syntax fix.

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
  group by cm.student_id, cm.class_id, p.name, p.avatar_url, cm.class_xp
  order by coalesce(cm.class_xp, 0) desc
  limit 200;
end;
$function$;
