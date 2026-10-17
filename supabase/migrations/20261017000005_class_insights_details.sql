-- ─────────────────────────────────────────────────────────────────────────────
-- Smart insights v2, step A1: the facts behind each student's paragraph
-- Run in the Supabase SQL Editor (after 20261017000004_class_insights_english_counts.sql)
--
-- Adds to every class_insight_snapshots row:
--   days        7 entries (oldest first) — what was due, done, late, open,
--               missed, and whether the student did anything that day
--   tasks       this week's and last week's Learn homework (done / late /
--               open) and review days (done / missed), for the pop-ups
--   patterns    which of the paragraph patterns apply (codes below)
--   tone        'concern' (levels 1-4) or 'positive' (5-6)
--   hard_words  {own: [...], shared: [...]} — shared = also marked Hard by
--               3+ classmates in total
-- and to class_review_due_log the due words and the still-due words, so the
-- "Friday" pop-up can list what wasn't reviewed (from tonight onwards).
--
-- Pattern codes
--   rhythm (exactly one): stopped, restarted, every_day, weekend_gap,
--                         slow_start, block, spread, one_off
--   habits (0-2):         open_homework, late, learn_no_review, review_no_learn
--   words  (0-1):         shared_hard, many_hard
--   special (alone):      new_student, nothing_due
-- Score, level, trend and the existing sentence picking are unchanged.
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.class_review_due_log
  add column if not exists words           text[],   -- due at 00:05 that day
  add column if not exists remaining_words text[];   -- still due at 00:05 next day

alter table public.class_insight_snapshots
  add column if not exists days       jsonb,
  add column if not exists tasks      jsonb,
  add column if not exists patterns   text[] not null default '{}',
  add column if not exists tone       text check (tone in ('concern', 'positive')),
  add column if not exists hard_words jsonb;

-- Learn homework due in [p_from, p_to] for one student, with its status as
-- of now: done (on time), late (finished after the deadline), open (not yet).
create or replace function public.insight_learn_tasks(
  p_class_id uuid,
  p_student_id uuid,
  p_from date,
  p_to date
) returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'homework_id',     x.id,
           'due_date',        x.due_date,
           'unit_name',       x.unit_name,
           'collection_name', x.collection_name,
           'day_number',      x.day_number,
           'passage_id',      x.passage_id,
           'completed_at',    x.completed_at,
           'status', case
             when x.completed_at is null then 'open'
             when (x.completed_at at time zone 'Asia/Tashkent')::date <= x.due_date then 'done'
             else 'late' end)
         order by x.due_date, x.created_at), '[]'::jsonb)
    from (
      select h.id, h.due_date, h.created_at, h.collection_name, h.day_number, h.passage_id,
             coalesce(cwu.name, tu.name) as unit_name,
             (select min(p.completed_at) from class_homework_progress p
               where p.homework_id = h.id and p.student_id = p_student_id and p.mode = 'learn') as completed_at
        from class_homework h
        left join class_word_units cwu on cwu.id = h.class_unit_id
        left join teacher_units tu     on tu.id  = h.unit_id
       where h.class_id = p_class_id
         and 'learn' = any(h.modes)
         and h.due_date between p_from and p_to
         and (h.student_ids is null or p_student_id = any(h.student_ids))
    ) x;
$$;

-- Measured review days in [p_from, p_to] for one student.
create or replace function public.insight_review_days(
  p_class_id uuid,
  p_student_id uuid,
  p_from date,
  p_to date
) returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'date',            l.log_date,
           'due_count',       l.due_count,
           'remaining_count', l.remaining_count,
           'words',           coalesce(to_jsonb(l.words), '[]'::jsonb),
           'remaining_words', coalesce(to_jsonb(l.remaining_words), '[]'::jsonb),
           'status', case when l.remaining_count = 0 then 'done' else 'missed' end)
         order by l.log_date), '[]'::jsonb)
    from class_review_due_log l
   where l.class_id = p_class_id
     and l.student_id = p_student_id
     and l.log_date between p_from and p_to
     and l.due_count > 0
     and l.remaining_count is not null;
$$;

-- Days, tasks, patterns and Hard words for one student, for the 7 days
-- ending p_day. Same window and join cut-off as compute_student_insight.
create or replace function public.insight_student_details(
  p_class_id uuid,
  p_student_id uuid,
  p_day date
) returns table(days jsonb, tasks jsonb, patterns text[], hard_words jsonb)
language plpgsql
stable
set search_path = public
as $$
#variable_conflict use_column
declare
  v_join date;
  v_from date;
  v_prev_from date;
  v_learn jsonb;
  v_review jsonb;
  v_days jsonb := '[]'::jsonb;
  v_patterns text[] := '{}';
  v_habits text[] := '{}';
  d date;
  v_l_due int; v_l_done int; v_l_late int; v_l_open int;
  v_r_due boolean; v_r_done boolean;
  v_missed boolean; v_active boolean;
  v_missed_dates date[] := '{}';
  v_first_active boolean := false; v_last_active boolean := false;
  v_first_missed boolean := false; v_last_missed boolean := false;
  v_run int := 0; v_max_run int := 0;
  v_ld int; v_ldone int; v_rd int; v_rdone int;
  v_own text[]; v_shared text[]; v_avg numeric;
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

  v_from      := greatest(p_day - 6,  v_join + 1);
  v_prev_from := greatest(p_day - 13, v_join + 1);
  v_learn  := insight_learn_tasks(p_class_id, p_student_id, v_from, p_day);
  v_review := insight_review_days(p_class_id, p_student_id, v_from, p_day);

  -- One entry per day. "First" = the first 4 days of the week, "last" = the
  -- last 3; stopped/restarted compare the two.
  for d in select generate_series(p_day - 6, p_day, interval '1 day')::date loop
    if d < v_from then
      v_days := v_days || jsonb_build_array(jsonb_build_object('date', d, 'before_join', true));
      v_run := 0;
      continue;
    end if;

    select count(*),
           count(*) filter (where t.v->>'status' = 'done'),
           count(*) filter (where t.v->>'status' = 'late'),
           count(*) filter (where t.v->>'status' = 'open')
      into v_l_due, v_l_done, v_l_late, v_l_open
      from jsonb_array_elements(v_learn) as t(v)
     where (t.v->>'due_date')::date = d;

    select count(*) > 0, coalesce(bool_and(r.v->>'status' = 'done'), false)
      into v_r_due, v_r_done
      from jsonb_array_elements(v_review) as r(v)
     where (r.v->>'date')::date = d;

    v_missed := v_l_due > v_l_done or (v_r_due and not v_r_done);
    v_active := exists (
                  select 1 from class_review_events e
                   where e.class_id = p_class_id and e.user_id = p_student_id
                     and (e.created_at at time zone 'Asia/Tashkent')::date = d)
             or exists (
                  select 1 from class_homework_progress p
                  join class_homework h on h.id = p.homework_id
                   where h.class_id = p_class_id and p.student_id = p_student_id
                     and (p.completed_at at time zone 'Asia/Tashkent')::date = d);

    v_days := v_days || jsonb_build_array(jsonb_build_object(
      'date', d, 'before_join', false,
      'learn_due', v_l_due, 'learn_done', v_l_done, 'learn_late', v_l_late, 'learn_open', v_l_open,
      'review_due', v_r_due, 'review_done', v_r_done,
      'missed', v_missed, 'active', v_active));

    if v_missed then
      v_missed_dates := v_missed_dates || d;
      v_run := v_run + 1;
      v_max_run := greatest(v_max_run, v_run);
    else
      v_run := 0;
    end if;

    if d <= p_day - 3 then
      v_first_active := v_first_active or v_active;
      v_first_missed := v_first_missed or v_missed;
    else
      v_last_active := v_last_active or v_active;
      v_last_missed := v_last_missed or v_missed;
    end if;
  end loop;

  v_ld    := jsonb_array_length(v_learn);
  v_rd    := jsonb_array_length(v_review);
  v_ldone := (select count(*) from jsonb_array_elements(v_learn) as t(v) where t.v->>'status' = 'done');
  v_rdone := (select count(*) from jsonb_array_elements(v_review) as r(v) where r.v->>'status' = 'done');

  v_own := array(select h.word from class_hard_words h
                  where h.class_id = p_class_id and h.user_id = p_student_id
                  order by h.created_at desc);
  v_shared := array(select w from unnest(v_own) w
                     where w in (select c.word from class_hard_word_counts(p_class_id, 3) c));

  if v_ld + v_rd = 0 then
    -- Nothing was due: one special paragraph instead of the usual parts.
    v_patterns := array[case when v_from > p_day - 6 then 'new_student' else 'nothing_due' end];
  else
    -- Rhythm: exactly one, first match wins.
    v_patterns := array[case
      when v_last_missed and not v_last_active and v_first_active then 'stopped'
      when v_first_missed and not v_first_active and v_last_active then 'restarted'
      when cardinality(v_missed_dates) = 0 then 'every_day'
      when not exists (select 1 from unnest(v_missed_dates) m where extract(isodow from m) not in (5, 6, 7)) then 'weekend_gap'
      when not exists (select 1 from unnest(v_missed_dates) m where extract(isodow from m) not in (1, 2)) then 'slow_start'
      when v_max_run >= 3 then 'block'
      when cardinality(v_missed_dates) >= 2 then 'spread'
      else 'one_off'
    end];

    -- Habits: up to two, in this priority.
    if exists (select 1 from jsonb_array_elements(v_learn) as t(v) where t.v->>'status' = 'open') then
      v_habits := v_habits || 'open_homework'::text;
    end if;
    if exists (select 1 from jsonb_array_elements(v_learn) as t(v) where t.v->>'status' = 'late') then
      v_habits := v_habits || 'late'::text;
    end if;
    if v_ld > 0 and v_rd > 0 and v_ldone >= 0.8 * v_ld and v_rdone < 0.5 * v_rd then
      v_habits := v_habits || 'learn_no_review'::text;
    end if;
    if v_ld > 0 and v_rd > 0 and v_rdone >= 0.8 * v_rd and v_ldone < 0.5 * v_ld then
      v_habits := v_habits || 'review_no_learn'::text;
    end if;
    v_patterns := v_patterns || v_habits[1:2];

    -- Words: at most one. v_avg = Hard words per approved student in the class.
    select (select count(*) from class_hard_words h
              join class_members m on m.class_id = h.class_id and m.student_id = h.user_id and m.status = 'approved'
             where h.class_id = p_class_id)::numeric
           / nullif((select count(*) from class_members m
                      where m.class_id = p_class_id and m.status = 'approved'), 0)
      into v_avg;

    if cardinality(v_shared) > 0 then
      v_patterns := v_patterns || 'shared_hard'::text;
    elsif cardinality(v_own) >= 5 and cardinality(v_own) >= 2 * coalesce(v_avg, 0) then
      v_patterns := v_patterns || 'many_hard'::text;
    end if;
  end if;

  return query select
    v_days,
    jsonb_build_object(
      'this_week', jsonb_build_object('learn', v_learn, 'review', v_review),
      'last_week', jsonb_build_object(
        'learn',  insight_learn_tasks(p_class_id, p_student_id, v_prev_from, p_day - 7),
        'review', insight_review_days(p_class_id, p_student_id, v_prev_from, p_day - 7))),
    v_patterns,
    jsonb_build_object('own', to_jsonb(v_own), 'shared', to_jsonb(v_shared));
end;
$$;

-- ── Nightly job: same as before, plus the new columns and diary words ───────

create or replace function public.run_daily_class_insights(
  p_today date default (now() at time zone 'Asia/Tashkent')::date
) returns void
language plpgsql
set search_path = public
as $$
declare
  v_live boolean := p_today = (now() at time zone 'Asia/Tashkent')::date;
  r record;
begin
  if v_live then
    -- 1. Yesterday's due reviews: how many (and which) are still due now.
    update class_review_due_log l
       set remaining_count = (
             select count(*) from class_srs_states s
              where s.user_id = l.student_id
                and s.class_id = l.class_id
                and s.next_due <= l.log_date),
           remaining_words = array(
             select s.word from class_srs_states s
              where s.user_id = l.student_id
                and s.class_id = l.class_id
                and s.next_due <= l.log_date
              order by s.word)
     where l.log_date = p_today - 1
       and l.remaining_count is null;

    -- 2. Today's due reviews.
    insert into class_review_due_log (class_id, student_id, log_date, due_count, words)
    select m.class_id, m.student_id, p_today, count(s.*), array_agg(s.word order by s.word)
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
    learn_due, learn_done, review_due, review_done, days_skipped, last_missed,
    prev_score, window_start, days, tasks, patterns, tone, hard_words)
  select m.class_id, m.student_id, p_today,
         case when i.days_skipped >= 3 then 'skipper'
              when i.level is null     then 'neutral'
              else 'level' end,
         i.level, i.trend, i.score, i.done, i.total,
         i.learn_due, i.learn_done, i.review_due, i.review_done,
         i.days_skipped, i.last_missed, i.prev_score, i.window_start,
         d.days, d.tasks, d.patterns,
         case when i.level >= 5 then 'positive' when i.level is not null then 'concern' end,
         d.hard_words
    from class_members m
   cross join lateral compute_student_insight(m.class_id, m.student_id, p_today - 1) i
   cross join lateral insight_student_details(m.class_id, m.student_id, p_today - 1) d
   where m.status = 'approved'
  on conflict (class_id, student_id, snapshot_date) do update set
    kind = excluded.kind, level = excluded.level, trend = excluded.trend,
    score = excluded.score, done = excluded.done, total = excluded.total,
    learn_due = excluded.learn_due, learn_done = excluded.learn_done,
    review_due = excluded.review_due, review_done = excluded.review_done,
    days_skipped = excluded.days_skipped, last_missed = excluded.last_missed,
    prev_score = excluded.prev_score, window_start = excluded.window_start,
    days = excluded.days, tasks = excluded.tasks, patterns = excluded.patterns,
    tone = excluded.tone, hard_words = excluded.hard_words,
    created_at = now();

  -- 3b. Pick each student's sentence.
  for r in
    select g.*,
           (row_number() over (partition by g.class_id, g.kind, g.g_level, g.g_trend
                               order by md5(g.student_id::text || p_today::text)) - 1)::int as rn
      from (
        select s.class_id, s.student_id, s.kind,
               case when s.kind = 'level' then s.level end                    as g_level,
               case when s.kind = 'level' then coalesce(s.trend, 'steady') end as g_trend,
               y.template_id                                                   as yesterday_id
          from class_insight_snapshots s
          left join class_insight_snapshots y
            on y.class_id = s.class_id and y.student_id = s.student_id
           and y.snapshot_date = p_today - 1
         where s.snapshot_date = p_today
      ) g
  loop
    update class_insight_snapshots
       set template_id = pick_insight_template(
             r.kind, r.g_level, r.g_trend,
             r.class_id::text || p_today::text || r.kind
               || coalesce(r.g_level::text, '') || coalesce(r.g_trend, ''),
             r.rn, r.yesterday_id)
     where class_id = r.class_id
       and student_id = r.student_id
       and snapshot_date = p_today;
  end loop;

  -- 4. One row per class (empty classes included, with zero counts).
  insert into class_insight_class_snapshots (
    class_id, snapshot_date, student_count, scored_count, attention_count,
    behind_count, well_count, skipper_count, hard_words)
  select c.id, p_today,
         count(s.student_id),
         count(s.score),
         count(*) filter (where s.kind = 'skipper' or s.level between 1 and 3),
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
    attention_count = excluded.attention_count,
    behind_count = excluded.behind_count, well_count = excluded.well_count,
    skipper_count = excluded.skipper_count, hard_words = excluded.hard_words,
    created_at = now();

  -- 4b. Pick each class's sentences. A section with nothing to say gets null.
  update class_insight_class_snapshots cs
     set summary_template_id = pick_insight_template(
           case when cs.student_count = 0   then 'class_empty'
                when cs.scored_count = 0    then 'class_no_data'
                when cs.attention_count = 0 then 'class_all_good'
                else 'class_summary' end,
           null, null, cs.class_id::text || p_today::text || 'summary', 0, y.summary_template_id),
         behind_template_id = case when cs.behind_count > 0 then pick_insight_template(
           'class_behind', null, null, cs.class_id::text || p_today::text || 'behind', 0, y.behind_template_id) end,
         well_template_id = case when cs.well_count > 0 then pick_insight_template(
           'class_well', null, null, cs.class_id::text || p_today::text || 'well', 0, y.well_template_id) end,
         hard_template_id = case when jsonb_array_length(cs.hard_words) > 0 then pick_insight_template(
           'class_hard', null, null, cs.class_id::text || p_today::text || 'hard', 0, y.hard_template_id) end,
         skipper_template_id = case when cs.skipper_count > 0 then pick_insight_template(
           'class_skipper', null, null, cs.class_id::text || p_today::text || 'skipper', 0, y.skipper_template_id) end
    from classes c
    left join class_insight_class_snapshots y
      on y.class_id = c.id and y.snapshot_date = p_today - 1
   where c.id = cs.class_id
     and cs.snapshot_date = p_today;
end;
$$;

revoke execute on function public.insight_learn_tasks(uuid, uuid, date, date)    from public, anon, authenticated;
revoke execute on function public.insight_review_days(uuid, uuid, date, date)    from public, anon, authenticated;
revoke execute on function public.insight_student_details(uuid, uuid, date)      from public, anon, authenticated;
revoke execute on function public.run_daily_class_insights(date)                 from public, anon, authenticated;
