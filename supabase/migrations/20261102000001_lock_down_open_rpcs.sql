-- ─────────────────────────────────────────────────────────────────────────────
-- Lock down SECURITY DEFINER functions that never checked who was calling.
-- Run this in Supabase SQL Editor (whole file at once — it's one transaction
-- per statement block; the DO block aborts itself if anything is off).
--
-- The anon key ships in the APK and the web bundle, so every one of these was
-- callable by anyone on the internet, for any user / any class:
--   sync_user_stats        — set anyone's XP, streak, leaderboard visibility
--   sync_profile_settings  — rename anyone, change their avatar
--   sync_learning_prefs    — change anyone's study settings
--   get_class_analytics, get_class_progress_over_time, get_hard_words,
--   get_active_students    — read any class's per-student data
--   get_class_member_ids   — list any class's members
--   get_student_xp_history — read any student's class XP log
--   advance_class_srs_word (old 4-arg overload) — move/delete any student's
--     class review cards. No client calls it any more (web uses the 5-arg
--     one, Flutter uses record_class_review_once), so it's dropped.
--
-- Not touched here (needs a server-only service role key first):
--   check_rate_limit, bot_users RLS, bot_broadcasts, classes read policy.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. sync_* : caller may only write their own row ──────────────────────────
-- Patched in place from the LIVE definition (pg_get_functiondef) instead of
-- re-typing the bodies from older migration files, so nothing else about
-- them can drift. The guard is inserted right after the body's first BEGIN.
-- service_role (no auth.uid()) stays allowed for server-side jobs.
do $$
declare
  fn  text;
  def text;
  new_def text;
  guard text := chr(10) ||
    '  if auth.uid() is distinct from p_user_id and coalesce(auth.role(), '''') <> ''service_role'' then' || chr(10) ||
    '    raise exception ''not authorized'';' || chr(10) ||
    '  end if;';
begin
  foreach fn in array array['sync_user_stats', 'sync_profile_settings', 'sync_learning_prefs'] loop
    for def in
      select pg_get_functiondef(p.oid)
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = fn
    loop
      if position('auth.uid()' in def) > 0 then
        continue; -- already guarded (re-run safe)
      end if;
      new_def := regexp_replace(def, '(\$function\$.*?\mbegin\M)', '\1' || guard, 'i');
      if new_def = def then
        raise exception 'could not find BEGIN in %', fn;
      end if;
      execute new_def;
    end loop;
  end loop;

  -- Abort everything if any overload is still unguarded.
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('sync_user_stats', 'sync_profile_settings', 'sync_learning_prefs')
      and position('auth.uid()' in pg_get_functiondef(p.oid)) = 0
  ) then
    raise exception 'a sync_* function is still unguarded';
  end if;
end $$;

-- ── 2. Teacher-only class reads ──────────────────────────────────────────────
-- Bodies are the live ones, plus the "caller teaches this class" condition.
-- A non-teacher now gets zero rows (not an error), same as an empty class.

create or replace function public.get_class_analytics(p_class_id uuid)
 returns table(student_id uuid, total_sessions integer, avg_session_seconds double precision, total_words_learned integer, total_gate_attempts integer, total_gate_correct_first integer, genuine_mastery_pct double precision, speed_flag_sessions integer, last_session_at timestamp with time zone, per_word_data_all jsonb)
 language sql
 security definer
 set search_path = public
as $function$
  select
    lsa.student_id,
    count(*)::int                                            as total_sessions,
    avg(lsa.session_seconds)::float                         as avg_session_seconds,
    sum(lsa.words_learned)::int                             as total_words_learned,
    sum(lsa.gate_attempts)::int                             as total_gate_attempts,
    sum(lsa.gate_correct_first_try)::int                   as total_gate_correct_first,
    case when sum(lsa.gate_attempts) > 0
      then round((sum(lsa.gate_correct_first_try)::numeric / sum(lsa.gate_attempts) * 100), 1)::float
      else null
    end                                                      as genuine_mastery_pct,
    count(case
      when lsa.words_learned > 0
        and lsa.session_seconds > 0
        and (lsa.words_learned::float / lsa.session_seconds * 60) > 10
      then 1 end
    )::int                                                   as speed_flag_sessions,
    max(lsa.completed_at)                                    as last_session_at,
    jsonb_agg(lsa.per_word_data)                            as per_word_data_all
  from learn_session_analytics lsa
  where lsa.class_id = p_class_id
    and lsa.completed_at is not null
    and exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid())
  group by lsa.student_id
$function$;

create or replace function public.get_class_progress_over_time(p_class_id uuid, p_days integer default 30)
 returns table(study_date date, words_learned integer, sessions_count integer, active_students integer)
 language sql
 security definer
 set search_path = public
as $function$
  select
    date(lsa.completed_at at time zone 'UTC') as study_date,
    sum(lsa.words_learned)::int               as words_learned,
    count(*)::int                              as sessions_count,
    count(distinct lsa.student_id)::int        as active_students
  from learn_session_analytics lsa
  where lsa.class_id = p_class_id
    and lsa.completed_at is not null
    and lsa.completed_at > now() - (p_days || ' days')::interval
    and exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid())
  group by date(lsa.completed_at at time zone 'UTC')
  order by study_date asc
$function$;

create or replace function public.get_hard_words(p_class_id uuid, p_min_attempts integer default 3, p_limit integer default 10)
 returns table(word_id uuid, word text, translation text, attempts bigint, correct_count bigint, accuracy_pct numeric)
 language sql
 security definer
 set search_path = public
as $function$
  select
    w.id as word_id,
    w.word,
    w.translation,
    count(*) as attempts,
    sum(case when s.is_correct then 1 else 0 end) as correct_count,
    round(100.0 * sum(case when s.is_correct then 1 else 0 end) / count(*), 0) as accuracy_pct
  from study_word_times s
  join class_words w on w.id = s.word_id
  where s.class_id = p_class_id
    and exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid())
  group by w.id, w.word, w.translation
  having count(*) >= p_min_attempts
  order by accuracy_pct asc
  limit p_limit;
$function$;

create or replace function public.get_active_students(p_class_id uuid)
 returns table(student_id uuid, student_name text, avatar_url text, activity text, collection_name text, day_number integer, started_at timestamp with time zone)
 language sql
 security definer
 set search_path = public
as $function$
  select
    sp.student_id,
    p.name        as student_name,
    p.avatar_url,
    sp.activity,
    sp.collection_name,
    sp.day_number,
    sp.started_at
  from student_presence sp
  join class_members cm
    on cm.student_id = sp.student_id and cm.class_id = p_class_id
  left join profiles p on p.id = sp.student_id
  where sp.last_heartbeat > now() - interval '2 minutes'
    and exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid());
$function$;

-- ── 3. Teacher or approved member ────────────────────────────────────────────
-- Flutter's class home calls this for both teacher and students.
create or replace function public.get_class_member_ids(p_class_id uuid)
 returns table(student_id uuid)
 language plpgsql
 security definer
 set search_path = public
as $function$
begin
  if not (
    exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid())
    or is_approved_class_member(p_class_id, auth.uid())
  ) then
    return;
  end if;
  return query
  select cm.student_id from class_members cm
  where cm.class_id = p_class_id;
end;
$function$;

-- ── 4. The student themself or their teacher ─────────────────────────────────
create or replace function public.get_student_xp_history(p_class_id uuid, p_student_id uuid)
 returns table(id uuid, amount integer, reason text, created_at timestamp with time zone)
 language sql
 security definer
 set search_path = public
as $function$
  select h.id, h.amount, h.reason, h.created_at
  from class_xp_history h
  where h.class_id = p_class_id and h.user_id = p_student_id
    and (
      p_student_id = auth.uid()
      or exists (select 1 from classes c where c.id = p_class_id and c.teacher_id = auth.uid())
    )
  order by h.created_at desc
  limit 50;
$function$;

-- ── 5. Drop the unguarded 4-arg advance_class_srs_word ───────────────────────
-- The guarded 5-arg version (p_today) is untouched — SRS rules don't change.
drop function if exists public.advance_class_srs_word(uuid, uuid, text, boolean);
