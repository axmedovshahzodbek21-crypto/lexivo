-- Smart insights: students in the same class could get the same paragraph
-- sentence when their tones differed — 3c shuffled within (class, part,
-- pattern, tone), so a 'positive' and a 'concern' student were each first in
-- their own group. The shuffle is now per (class, part, pattern); tone only
-- decides which sentence pool is used. Same function otherwise.
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

  -- 3b. Pick each student's one-line sentence (kept for the banner/fallback).
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

  -- 3c. Build each student's paragraph: list the parts, then pick a sentence
  --     per part — shuffled within (class, part, pattern), never the
  --     one this student had for the same pattern yesterday.
  with parts as (
    select s.class_id, s.student_id, s.tone, v.ord, v.part, v.pattern
      from class_insight_snapshots s
     cross join lateral (
       select 0 as ord, 'special' as part, s.patterns[1] as pattern where s.total = 0
       union all
       select 1, 'headline', 'L' || s.level || '-' || coalesce(s.trend, 'steady') where s.total > 0
       union all
       select 2, 'compare', case s.trend when 'rising'  then 'compare_up'
                                         when 'falling' then 'compare_down'
                                         when 'steady'  then 'compare_same'
                                         else 'compare_first' end
        where s.total > 0
       union all
       select 3, 'rhythm', s.patterns[1] where s.total > 0
       union all
       select 3 + u.k::int,
              case when u.p in ('shared_hard', 'many_hard') then 'words' else 'habit' end,
              u.p
         from unnest(s.patterns) with ordinality as u(p, k)
        where s.total > 0 and u.k > 1
       union all
       select 9, 'action', case when 'open_homework' = any(s.patterns) then 'act_reminder'
                                when s.patterns[1] = 'stopped'         then 'act_checkin'
                                when s.level >= 5                      then 'act_praise'
                                else 'act_message' end
        where s.total > 0
     ) v
     where s.snapshot_date = p_today
  ),
  ranked as (
    select pt.*,
           (row_number() over (partition by pt.class_id, pt.part, pt.pattern
                               order by md5(pt.student_id::text || p_today::text)) - 1)::int as rn,
           (select (e.v->>'template_id')::int
              from class_insight_snapshots y
             cross join jsonb_array_elements(coalesce(y.paragraph, '[]'::jsonb)) as e(v)
             where y.class_id = pt.class_id and y.student_id = pt.student_id
               and y.snapshot_date = p_today - 1
               and e.v->>'part' = pt.part and e.v->>'pattern' = pt.pattern
             limit 1) as yesterday_id
      from parts pt
  ),
  picked as (
    select class_id, student_id,
           jsonb_agg(jsonb_build_object(
             'part', part, 'pattern', pattern,
             'template_id', pick_part_template(part, pattern, tone,
                              class_id::text || p_today::text || part || pattern, rn, yesterday_id))
             order by ord) as paragraph
      from ranked
     group by class_id, student_id
  )
  update class_insight_snapshots s
     set paragraph = p.paragraph
    from picked p
   where s.class_id = p.class_id
     and s.student_id = p.student_id
     and s.snapshot_date = p_today;

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

revoke execute on function public.run_daily_class_insights(date) from public, anon, authenticated;
