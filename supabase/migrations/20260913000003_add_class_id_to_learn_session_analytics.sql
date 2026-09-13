-- get_class_analytics and get_class_progress_over_time joined class_members
-- onto learn_session_analytics by student_id alone, which only filters
-- *who* is in the class, not *what was studied for it* — a student's
-- personal Learn sessions (unrelated to any class) counted as "class
-- analytics" identically in every class they belong to.
--
-- Fix: learn_session_analytics now has a class_id column (nullable — most
-- Learn sessions are personal, not done via a class). The Flutter client
-- already knows whether a session is class-scoped (LearningScreen takes an
-- optional classId), so the insert in learning.dart now passes it through.
-- The two RPCs filter on it directly instead of joining via class_members.
--
-- Note: existing historical rows have class_id = null, so these RPCs will
-- show no data until new class-scoped sessions are recorded going forward.
-- That's expected — there's no way to retroactively attribute old personal
-- sessions to a specific class.

alter table learn_session_analytics add column if not exists class_id uuid references classes(id) on delete set null;
create index if not exists idx_learn_session_analytics_class_id on learn_session_analytics(class_id, student_id);

create or replace function public.get_class_analytics(p_class_id uuid)
 returns table(student_id uuid, total_sessions integer, avg_session_seconds double precision, total_words_learned integer, total_gate_attempts integer, total_gate_correct_first integer, genuine_mastery_pct double precision, speed_flag_sessions integer, last_session_at timestamp with time zone, per_word_data_all jsonb)
 language sql
 security definer
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
  group by lsa.student_id
$function$;

create or replace function public.get_class_progress_over_time(p_class_id uuid, p_days integer default 30)
 returns table(study_date date, words_learned integer, sessions_count integer, active_students integer)
 language sql
 security definer
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
  group by date(lsa.completed_at at time zone 'UTC')
  order by study_date asc
$function$;
