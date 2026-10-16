-- ─────────────────────────────────────────────────────────────────────────────
-- Smart insights, step 2: saved daily snapshots + the nightly job
-- Run in the Supabase SQL Editor (after 20261016000001_class_insights_scoring.sql)
--
-- run_daily_class_insights() runs at 00:05 Asia/Tashkent and:
--   1. measures yesterday's class_review_due_log rows (how many reviews left)
--   2. logs today's due reviews per student
--   3. saves one class_insight_snapshots row per approved student per class,
--      scored on data up to the end of yesterday
--   4. saves one class_insight_class_snapshots row per class
-- The class page only reads these rows, so a sentence stays fixed all day.
-- template ids stay null until step 3 adds the templates.
--
-- Turn the job off:  select cron.unschedule('class-insights-daily');
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.class_insight_snapshots (
  class_id      uuid not null references classes(id)    on delete cascade,
  student_id    uuid not null references auth.users(id) on delete cascade,
  snapshot_date date not null,           -- Tashkent day the insight is shown
  kind          text not null check (kind in ('skipper', 'level', 'neutral')),
  level         int,                     -- 1-6, null = nothing due
  trend         text check (trend in ('rising', 'steady', 'falling')),
  score         int,
  done          int not null,
  total         int not null,
  learn_due     int not null,
  learn_done    int not null,
  review_due    int not null,
  review_done   int not null,
  days_skipped  int not null,
  prev_score    int,
  window_start  date not null,
  template_id   int,                     -- filled from step 3
  created_at    timestamptz not null default now(),
  primary key (class_id, student_id, snapshot_date)
);

create table if not exists public.class_insight_class_snapshots (
  class_id             uuid not null references classes(id) on delete cascade,
  snapshot_date        date not null,
  student_count        int  not null,
  scored_count         int  not null,    -- students with a score (something was due)
  behind_count         int  not null,    -- levels 1-3
  well_count           int  not null,    -- levels 5-6
  skipper_count        int  not null,    -- skipped on 3+ of the last 7 days
  hard_words           jsonb not null default '[]'::jsonb,  -- [{word, students}], 3+ students
  summary_template_id  int,              -- filled from step 3
  behind_template_id   int,
  well_template_id     int,
  hard_template_id     int,
  skipper_template_id  int,
  created_at           timestamptz not null default now(),
  primary key (class_id, snapshot_date)
);

alter table public.class_insight_snapshots       enable row level security;
alter table public.class_insight_class_snapshots enable row level security;

-- Only the class's teacher reads. Nobody writes from the app; the nightly job
-- runs as the table owner.
drop policy if exists class_insight_snapshots_teacher_read on public.class_insight_snapshots;
create policy class_insight_snapshots_teacher_read
  on public.class_insight_snapshots for select to authenticated
  using (exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid()));

drop policy if exists class_insight_class_snapshots_teacher_read on public.class_insight_class_snapshots;
create policy class_insight_class_snapshots_teacher_read
  on public.class_insight_class_snapshots for select to authenticated
  using (exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid()));

revoke all on public.class_insight_snapshots       from anon, authenticated;
revoke all on public.class_insight_class_snapshots from anon, authenticated;
grant select on public.class_insight_snapshots       to authenticated;
grant select on public.class_insight_class_snapshots to authenticated;

-- p_today defaults to the current Tashkent date. Passing a past date rebuilds
-- that day's snapshots (handy for testing) but skips the review diary, which
-- can only be recorded live — class_srs_states holds no history.
create or replace function public.run_daily_class_insights(
  p_today date default (now() at time zone 'Asia/Tashkent')::date
) returns void
language plpgsql
set search_path = public
as $$
declare
  v_live boolean := p_today = (now() at time zone 'Asia/Tashkent')::date;
begin
  if v_live then
    -- 1. Yesterday's due reviews: how many are still due now.
    update class_review_due_log l
       set remaining_count = (
             select count(*) from class_srs_states s
              where s.user_id = l.student_id
                and s.class_id = l.class_id
                and s.next_due <= l.log_date)
     where l.log_date = p_today - 1
       and l.remaining_count is null;

    -- 2. Today's due reviews.
    insert into class_review_due_log (class_id, student_id, log_date, due_count)
    select m.class_id, m.student_id, p_today, count(s.*)
      from class_members m
      join class_srs_states s
        on s.class_id = m.class_id and s.user_id = m.student_id and s.next_due <= p_today
     where m.status = 'approved'
     group by m.class_id, m.student_id
    on conflict (class_id, student_id, log_date) do nothing;
  end if;

  -- 3. One row per approved student per class, scored up to end of yesterday.
  --    Priority: frequent skipping, then level, then (no score) neutral.
  insert into class_insight_snapshots (
    class_id, student_id, snapshot_date, kind, level, trend, score, done, total,
    learn_due, learn_done, review_due, review_done, days_skipped, prev_score, window_start)
  select m.class_id, m.student_id, p_today,
         case when i.days_skipped >= 3 then 'skipper'
              when i.level is null     then 'neutral'
              else 'level' end,
         i.level, i.trend, i.score, i.done, i.total,
         i.learn_due, i.learn_done, i.review_due, i.review_done,
         i.days_skipped, i.prev_score, i.window_start
    from class_members m
   cross join lateral compute_student_insight(m.class_id, m.student_id, p_today - 1) i
   where m.status = 'approved'
  on conflict (class_id, student_id, snapshot_date) do update set
    kind = excluded.kind, level = excluded.level, trend = excluded.trend,
    score = excluded.score, done = excluded.done, total = excluded.total,
    learn_due = excluded.learn_due, learn_done = excluded.learn_done,
    review_due = excluded.review_due, review_done = excluded.review_done,
    days_skipped = excluded.days_skipped, prev_score = excluded.prev_score,
    window_start = excluded.window_start, created_at = now();

  -- 4. One row per class (empty classes included, with zero counts).
  insert into class_insight_class_snapshots (
    class_id, snapshot_date, student_count, scored_count, behind_count,
    well_count, skipper_count, hard_words)
  select c.id, p_today,
         count(s.student_id),
         count(s.score),
         count(*) filter (where s.level between 1 and 3),
         count(*) filter (where s.level >= 5),
         count(*) filter (where s.days_skipped >= 3),
         coalesce((select jsonb_agg(jsonb_build_object('word', h.word, 'students', h.student_count))
                     from class_hard_word_counts(c.id, 3) h), '[]'::jsonb)
    from classes c
    left join class_insight_snapshots s on s.class_id = c.id and s.snapshot_date = p_today
   group by c.id
  on conflict (class_id, snapshot_date) do update set
    student_count = excluded.student_count, scored_count = excluded.scored_count,
    behind_count = excluded.behind_count, well_count = excluded.well_count,
    skipper_count = excluded.skipper_count, hard_words = excluded.hard_words,
    created_at = now();
end;
$$;

revoke execute on function public.run_daily_class_insights(date) from public, anon, authenticated;

-- 19:05 UTC = 00:05 Asia/Tashkent (no DST there, so the offset is stable).
-- Re-running this file just updates the existing schedule.
select cron.schedule(
  'class-insights-daily',
  '5 19 * * *',
  $$ select public.run_daily_class_insights(); $$
);
