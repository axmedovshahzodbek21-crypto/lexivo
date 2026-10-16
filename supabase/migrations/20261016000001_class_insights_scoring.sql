-- ─────────────────────────────────────────────────────────────────────────────
-- Smart insights, step 1: scoring functions (no UI, nothing calls these yet)
-- Run in the Supabase SQL Editor
--
-- Score = tasks done on time / tasks whose deadline passed, over the 7 days
-- ending p_day (normally yesterday, Asia/Tashkent). Learn and review pooled.
--
-- - Learn task: a class_homework row with 'learn' in modes, a due_date in the
--   window, assigned to the student (student_ids null = whole class). Done on
--   time if a 'learn' class_homework_progress row exists with completed_at on
--   or before due_date (Tashkent date).
-- - Review task: one per day on which the student had at least one class
--   review due. class_srs_states.next_due is overwritten on every review, so
--   past due-ness can't be reconstructed — class_review_due_log records it
--   going forward (filled by the daily job in step 2). Done if every review
--   due that day was cleared by end of day (remaining_count = 0).
-- - Tasks due on or before the student's join date are ignored.
-- - Trend: +10 points or more vs the previous 7 days = rising, -10 or more =
--   falling, otherwise steady; null when either window has no tasks.
--
-- None of these are callable from the app: they read every student in a
-- class, so execute is revoked from anon/authenticated. Only the daily job
-- (step 2) and the SQL Editor use them.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.class_review_due_log (
  class_id        uuid not null references classes(id)    on delete cascade,
  student_id      uuid not null references auth.users(id) on delete cascade,
  log_date        date not null,               -- Tashkent date the reviews were due
  due_count       int  not null,               -- due (next_due <= log_date) at 00:05 that day
  remaining_count int,                         -- still due at 00:05 next day; null until measured
  primary key (class_id, student_id, log_date)
);

-- RLS on with no policies = deny all, on purpose. Only the daily job (runs as
-- the table owner) writes or reads this; teachers see the results through the
-- snapshot tables added in step 2.
alter table public.class_review_due_log enable row level security;
revoke all on public.class_review_due_log from anon, authenticated;

-- Score (0-100) -> level 1-6. Null score (no tasks due) -> null level.
create or replace function public.insight_level(p_score int)
returns int
language sql
immutable
as $$
  select case
    when p_score is null then null
    when p_score <= 9  then 1
    when p_score <= 20 then 2
    when p_score <= 40 then 3
    when p_score <= 60 then 4
    when p_score <= 80 then 5
    else 6
  end;
$$;

-- Task counts for one student over [p_from, p_to]. p_from > p_to = empty.
create or replace function public.insight_window_counts(
  p_class_id uuid,
  p_student_id uuid,
  p_from date,
  p_to date
) returns table(learn_due int, learn_done int, review_due int, review_done int, skipped_days int)
language sql
stable
set search_path = public
as $$
  with learn as (
    select h.due_date,
           exists (
             select 1 from class_homework_progress p
              where p.homework_id = h.id
                and p.student_id = p_student_id
                and p.mode = 'learn'
                and (p.completed_at at time zone 'Asia/Tashkent')::date <= h.due_date
           ) as done
      from class_homework h
     where h.class_id = p_class_id
       and 'learn' = any(h.modes)
       and h.due_date between p_from and p_to
       and (h.student_ids is null or p_student_id = any(h.student_ids))
  ),
  review as (
    select l.log_date as due_date, l.remaining_count = 0 as done
      from class_review_due_log l
     where l.class_id = p_class_id
       and l.student_id = p_student_id
       and l.log_date between p_from and p_to
       and l.due_count > 0
       and l.remaining_count is not null
  ),
  missed_days as (
    select due_date from learn where not done
    union
    select due_date from review where not done
  )
  select (select count(*) from learn)::int,
         (select count(*) from learn where done)::int,
         (select count(*) from review)::int,
         (select count(*) from review where done)::int,
         (select count(*) from missed_days)::int;
$$;

-- Everything the insight for one student on one day needs. Returns no row
-- for a non-member or a pending member.
create or replace function public.compute_student_insight(
  p_class_id uuid,
  p_student_id uuid,
  p_day date
) returns table(
  window_start date,
  learn_due int, learn_done int,
  review_due int, review_done int,
  done int, total int,
  score int, level int,
  days_skipped int,
  prev_score int,
  trend text
)
language plpgsql
stable
set search_path = public
as $$
#variable_conflict use_column
declare
  v_join date;
  v_from date;
  v_cur record;
  v_prev record;
  v_score int;
  v_prev_score int;
begin
  select coalesce((m.joined_at  at time zone 'Asia/Tashkent')::date,
                  (c.created_at at time zone 'Asia/Tashkent')::date)
    into v_join
    from class_members m
    join classes c on c.id = m.class_id
   where m.class_id = p_class_id
     and m.student_id = p_student_id
     and m.status = 'approved';

  if not found then
    return;
  end if;

  -- greatest() ignores nulls, so a null join date just means "no cut-off".
  v_from := greatest(p_day - 6, v_join + 1);

  select * into v_cur  from insight_window_counts(p_class_id, p_student_id, v_from, p_day);
  select * into v_prev from insight_window_counts(p_class_id, p_student_id, greatest(p_day - 13, v_join + 1), p_day - 7);

  if v_cur.learn_due + v_cur.review_due > 0 then
    v_score := round(100.0 * (v_cur.learn_done + v_cur.review_done)
                           / (v_cur.learn_due + v_cur.review_due))::int;
  end if;

  if v_prev.learn_due + v_prev.review_due > 0 then
    v_prev_score := round(100.0 * (v_prev.learn_done + v_prev.review_done)
                                / (v_prev.learn_due + v_prev.review_due))::int;
  end if;

  return query select
    v_from,
    v_cur.learn_due, v_cur.learn_done,
    v_cur.review_due, v_cur.review_done,
    v_cur.learn_done + v_cur.review_done,
    v_cur.learn_due + v_cur.review_due,
    v_score,
    insight_level(v_score),
    v_cur.skipped_days,
    v_prev_score,
    case
      when v_score is null or v_prev_score is null then null
      when v_score - v_prev_score >= 10  then 'rising'
      when v_score - v_prev_score <= -10 then 'falling'
      else 'steady'
    end;
end;
$$;

-- Words marked Hard by at least p_min_students different approved students.
-- Rows are deleted on unmark, so this is always the current count.
create or replace function public.class_hard_word_counts(
  p_class_id uuid,
  p_min_students int default 3
) returns table(word text, student_count int)
language sql
stable
set search_path = public
as $$
  select h.word, count(distinct h.user_id)::int
    from class_hard_words h
    join class_members m
      on m.class_id = h.class_id and m.student_id = h.user_id and m.status = 'approved'
   where h.class_id = p_class_id
   group by h.word
  having count(distinct h.user_id) >= p_min_students
   order by 2 desc, 1;
$$;

revoke execute on function public.insight_level(int)                                  from public, anon, authenticated;
revoke execute on function public.insight_window_counts(uuid, uuid, date, date)       from public, anon, authenticated;
revoke execute on function public.compute_student_insight(uuid, uuid, date)           from public, anon, authenticated;
revoke execute on function public.class_hard_word_counts(uuid, int)                   from public, anon, authenticated;
