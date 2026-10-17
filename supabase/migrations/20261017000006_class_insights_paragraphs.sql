-- ─────────────────────────────────────────────────────────────────────────────
-- Smart insights v2, step A2: paragraph sentences + paragraph picking
-- Run in the Supabase SQL Editor (after 20261017000005_class_insights_details.sql)
--
-- A student's paragraph is built from parts, in this order:
--   headline  level + trend verdict, no numbers         (pattern L<level>-<trend>)
--   compare   this week vs last week                    (compare_up/down/same/first)
--   rhythm    which days                                (patterns[1])
--   habit     0-2: open_homework, late, learn_no_review, review_no_learn
--   words     0-1: shared_hard, many_hard
--   action    act_reminder / act_checkin / act_praise / act_message
-- or, when nothing was due, one 'special' part (new_student / nothing_due).
--
-- Templates are insight_templates rows with kind = 'part'. tone null = fits
-- both tones; a tone-specific row wins over a tone-null one.
--
-- Placeholders the page fills in (most become clickable):
--   {name} {this_week} {last_week} {missed_days} {active_days} {open_days}
--   {late_tasks} {hard_words} {hard_count}
--   {reminder:text} {checkin:text} {praise:text} {message:text} — action
--   buttons; the text after ':' is what the teacher sees in the sentence.
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.insight_templates
  add column if not exists part    text,
  add column if not exists pattern text,
  add column if not exists tone    text check (tone in ('concern', 'positive'));

alter table public.insight_templates drop constraint if exists insight_templates_kind_check;
alter table public.insight_templates add constraint insight_templates_kind_check check (kind in (
  'level', 'skipper', 'neutral',
  'class_summary', 'class_all_good', 'class_no_data', 'class_empty',
  'class_behind', 'class_well', 'class_hard', 'class_skipper',
  'part'));

alter table public.class_insight_snapshots
  add column if not exists paragraph jsonb;   -- [{part, pattern, template_id}] in display order

-- Same rule as pick_insight_template, for paragraph parts.
create or replace function public.pick_part_template(
  p_part text,
  p_pattern text,
  p_tone text,
  p_seed text,
  p_rank int,
  p_avoid int
) returns int
language plpgsql
stable
set search_path = public
as $$
declare
  v_ids int[];
  v_n int;
  v_idx int;
begin
  select array_agg(id order by id) into v_ids
    from insight_templates
   where active and kind = 'part' and part = p_part and pattern = p_pattern
     and tone = p_tone;

  if v_ids is null then
    select array_agg(id order by id) into v_ids
      from insight_templates
     where active and kind = 'part' and part = p_part and pattern = p_pattern
       and tone is null;
  end if;

  if v_ids is null then
    return null;
  end if;

  v_n := array_length(v_ids, 1);
  v_idx := ((hashtext(p_seed)::bigint % v_n + v_n) % v_n + p_rank) % v_n;
  if v_ids[v_idx + 1] = p_avoid and v_n > 1 then
    v_idx := (v_idx + 1) % v_n;
  end if;
  return v_ids[v_idx + 1];
end;
$$;

-- ── Nightly job: as before, plus 3c (paragraphs) ────────────────────────────

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
  --     per part — shuffled within (class, part, pattern, tone), never the
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

revoke execute on function public.pick_part_template(text, text, text, text, int, int) from public, anon, authenticated;
revoke execute on function public.run_daily_class_insights(date)                       from public, anon, authenticated;

-- ── Sentences ───────────────────────────────────────────────────────────────
-- Re-running never overwrites an edited sentence (matched by code).

insert into public.insight_templates (code, kind, part, pattern, tone, text_uz, text_en)
select t.code, 'part', t.part, t.pattern, t.tone, t.uz, t.en
  from jsonb_to_recordset($json$[
  {"code":"P-headline-L1-steady-1","part":"headline","pattern":"L1-steady","uz":"{name} hozircha deyarli vazifa bajarmayapti.","en":"{name} is barely doing any tasks right now."},
  {"code":"P-headline-L1-steady-2","part":"headline","pattern":"L1-steady","uz":"{name} bu hafta juda kam faol bo'ldi.","en":"{name} was hardly active this week."},
  {"code":"P-headline-L1-steady-3","part":"headline","pattern":"L1-steady","uz":"{name} vazifalardan ancha orqada qolmoqda.","en":"{name} is far behind on tasks."},
  {"code":"P-headline-L1-falling-1","part":"headline","pattern":"L1-falling","uz":"{name} bu hafta keskin orqaga ketdi.","en":"{name} dropped sharply this week."},
  {"code":"P-headline-L1-falling-2","part":"headline","pattern":"L1-falling","uz":"{name} deyarli to'xtab qoldi.","en":"{name} has almost stopped."},
  {"code":"P-headline-L1-falling-3","part":"headline","pattern":"L1-falling","uz":"{name} o'tgan haftaga qaraganda ancha kam ishladi.","en":"{name} did far less than last week."},

  {"code":"P-headline-L2-steady-1","part":"headline","pattern":"L2-steady","uz":"{name} vazifalarni kamdan-kam bajarmoqda.","en":"{name} rarely completes tasks."},
  {"code":"P-headline-L2-steady-2","part":"headline","pattern":"L2-steady","uz":"{name} vazifalarning ozginasini bajarmoqda.","en":"{name} does only a few of the tasks."},
  {"code":"P-headline-L2-steady-3","part":"headline","pattern":"L2-steady","uz":"{name} hali muntazam ishlay olmayapti.","en":"{name} hasn't found a routine yet."},
  {"code":"P-headline-L2-rising-1","part":"headline","pattern":"L2-rising","uz":"{name} asta-sekin faollashmoqda.","en":"{name} is slowly picking up."},
  {"code":"P-headline-L2-rising-2","part":"headline","pattern":"L2-rising","uz":"{name} kichik qadam oldinga tashladi.","en":"{name} took a small step forward."},
  {"code":"P-headline-L2-rising-3","part":"headline","pattern":"L2-rising","uz":"{name} vazifalarga qaytishni boshladi.","en":"{name} is starting to come back to tasks."},
  {"code":"P-headline-L2-falling-1","part":"headline","pattern":"L2-falling","uz":"{name} bu hafta yana kamroq ishladi.","en":"{name} did even less this week."},
  {"code":"P-headline-L2-falling-2","part":"headline","pattern":"L2-falling","uz":"{name} orqaga ketmoqda.","en":"{name} is slipping back."},
  {"code":"P-headline-L2-falling-3","part":"headline","pattern":"L2-falling","uz":"{name}: faollik pasaymoqda.","en":"{name}: activity is dropping."},

  {"code":"P-headline-L3-steady-1","part":"headline","pattern":"L3-steady","uz":"{name} vazifalarning kam qismini bajarmoqda.","en":"{name} completes a small share of tasks."},
  {"code":"P-headline-L3-steady-2","part":"headline","pattern":"L3-steady","uz":"{name} ba'zi vazifalarni bajarib, ko'pini o'tkazib yubormoqda.","en":"{name} does some tasks but misses most."},
  {"code":"P-headline-L3-steady-3","part":"headline","pattern":"L3-steady","uz":"{name} hali yetarlicha ishlamayapti.","en":"{name} isn't doing enough yet."},
  {"code":"P-headline-L3-rising-1","part":"headline","pattern":"L3-rising","uz":"{name} yaxshi tomonga o'zgarmoqda.","en":"{name} is changing for the better."},
  {"code":"P-headline-L3-rising-2","part":"headline","pattern":"L3-rising","uz":"{name} faollashmoqda.","en":"{name} is getting more active."},
  {"code":"P-headline-L3-rising-3","part":"headline","pattern":"L3-rising","uz":"{name} o'tgan haftadan ko'proq ishladi.","en":"{name} did more than last week."},
  {"code":"P-headline-L3-falling-1","part":"headline","pattern":"L3-falling","uz":"{name} bu hafta orqaga ketdi.","en":"{name} slipped this week."},
  {"code":"P-headline-L3-falling-2","part":"headline","pattern":"L3-falling","uz":"{name} kamroq ishlay boshladi.","en":"{name} is doing less."},
  {"code":"P-headline-L3-falling-3","part":"headline","pattern":"L3-falling","uz":"{name}: natija pasaymoqda.","en":"{name}: the result is dropping."},

  {"code":"P-headline-L4-steady-1","part":"headline","pattern":"L4-steady","uz":"{name} vazifalarning taxminan yarmini bajarmoqda.","en":"{name} completes about half of the tasks."},
  {"code":"P-headline-L4-steady-2","part":"headline","pattern":"L4-steady","uz":"{name} yarim yo'lda: asos bor, muntazamlik yetishmayapti.","en":"{name} is halfway there: the base is there, consistency is missing."},
  {"code":"P-headline-L4-steady-3","part":"headline","pattern":"L4-steady","uz":"{name} hali yaxshi darajaga yetmagan.","en":"{name} isn't quite at a good level yet."},
  {"code":"P-headline-L4-rising-1","part":"headline","pattern":"L4-rising","uz":"{name} yaxshilanmoqda va yaxshi darajaga yaqinlashmoqda.","en":"{name} is improving and getting close to a good level."},
  {"code":"P-headline-L4-rising-2","part":"headline","pattern":"L4-rising","uz":"{name} oldinga siljimoqda.","en":"{name} is moving forward."},
  {"code":"P-headline-L4-rising-3","part":"headline","pattern":"L4-rising","uz":"{name} o'tgan haftadan yaxshiroq ishladi.","en":"{name} did better than last week."},
  {"code":"P-headline-L4-falling-1","part":"headline","pattern":"L4-falling","uz":"{name} bu hafta biroz orqaga ketdi, lekin o'qishni to'xtatmagan.","en":"{name} slipped this week, but hasn't stopped working."},
  {"code":"P-headline-L4-falling-2","part":"headline","pattern":"L4-falling","uz":"{name}: natija pasaydi, ammo ish davom etmoqda.","en":"{name}: the result dropped, but the work goes on."},
  {"code":"P-headline-L4-falling-3","part":"headline","pattern":"L4-falling","uz":"{name} o'tgan haftadagidan kamroq bajardi.","en":"{name} did less than last week."},

  {"code":"P-headline-L5-steady-1","part":"headline","pattern":"L5-steady","uz":"{name} yaxshi ishlamoqda.","en":"{name} is doing well."},
  {"code":"P-headline-L5-steady-2","part":"headline","pattern":"L5-steady","uz":"{name} vazifalarning ko'pini vaqtida bajarmoqda.","en":"{name} completes most tasks on time."},
  {"code":"P-headline-L5-steady-3","part":"headline","pattern":"L5-steady","uz":"{name} yaxshi darajada.","en":"{name} is at a good level."},
  {"code":"P-headline-L5-rising-1","part":"headline","pattern":"L5-rising","uz":"{name} sezilarli o'sdi.","en":"{name} improved noticeably."},
  {"code":"P-headline-L5-rising-2","part":"headline","pattern":"L5-rising","uz":"{name} to'g'ri yo'nalishda ketmoqda.","en":"{name} is heading the right way."},
  {"code":"P-headline-L5-rising-3","part":"headline","pattern":"L5-rising","uz":"{name} o'tgan haftadan ancha yaxshi ishladi.","en":"{name} did much better than last week."},
  {"code":"P-headline-L5-falling-1","part":"headline","pattern":"L5-falling","uz":"{name} hali yaxshi darajada, lekin biroz pasaydi.","en":"{name} is still doing well, but dipped a little."},
  {"code":"P-headline-L5-falling-2","part":"headline","pattern":"L5-falling","uz":"{name}: natija tushdi, ammo hali yaxshi.","en":"{name}: the result dropped but is still good."},
  {"code":"P-headline-L5-falling-3","part":"headline","pattern":"L5-falling","uz":"{name} o'tgan haftadan kamroq bajardi, lekin yaxshi darajada qolmoqda.","en":"{name} did less than last week but stays at a good level."},

  {"code":"P-headline-L6-steady-1","part":"headline","pattern":"L6-steady","uz":"{name} a'lo darajada ishlamoqda.","en":"{name} is doing excellently."},
  {"code":"P-headline-L6-steady-2","part":"headline","pattern":"L6-steady","uz":"{name} deyarli barcha vazifalarni vaqtida bajarmoqda.","en":"{name} completes almost every task on time."},
  {"code":"P-headline-L6-steady-3","part":"headline","pattern":"L6-steady","uz":"{name} juda yaxshi natija ko'rsatmoqda.","en":"{name} is getting excellent results."},
  {"code":"P-headline-L6-rising-1","part":"headline","pattern":"L6-rising","uz":"{name} eng yuqori darajaga chiqdi.","en":"{name} reached the top level."},
  {"code":"P-headline-L6-rising-2","part":"headline","pattern":"L6-rising","uz":"{name} katta qadam tashladi.","en":"{name} made a big step forward."},
  {"code":"P-headline-L6-rising-3","part":"headline","pattern":"L6-rising","uz":"{name} bu hafta ajoyib natija ko'rsatdi.","en":"{name} had an excellent week."},
  {"code":"P-headline-L6-falling-1","part":"headline","pattern":"L6-falling","uz":"{name} hali a'lo darajada, faqat biroz pasayish bor.","en":"{name} is still excellent; just a small dip."},
  {"code":"P-headline-L6-falling-2","part":"headline","pattern":"L6-falling","uz":"{name}: kichik pasayish, natija hali yuqori.","en":"{name}: a small dip, still a high result."},
  {"code":"P-headline-L6-falling-3","part":"headline","pattern":"L6-falling","uz":"{name} o'tgan haftadan biroz kam bajardi, lekin juda yaxshi.","en":"{name} did a little less than last week, still very good."},

  {"code":"P-compare-down-1","part":"compare","pattern":"compare_down","uz":"O'tgan hafta {last_week} vazifa o'z vaqtida bajarilgan edi, bu hafta esa {this_week}.","en":"Last week {last_week} of tasks were done on time; this week, {this_week}."},
  {"code":"P-compare-down-2","part":"compare","pattern":"compare_down","uz":"Natija pasaydi: o'tgan hafta {last_week}, bu hafta {this_week}.","en":"The result went down: {last_week} last week, {this_week} this week."},
  {"code":"P-compare-down-3","part":"compare","pattern":"compare_down","uz":"Bu hafta {this_week}, o'tgan haftada esa {last_week} edi.","en":"This week {this_week}, compared with {last_week} last week."},
  {"code":"P-compare-up-1","part":"compare","pattern":"compare_up","uz":"O'tgan hafta {last_week} edi, bu hafta esa {this_week} — o'sish bor.","en":"Last week {last_week}, this week {this_week} — an improvement."},
  {"code":"P-compare-up-2","part":"compare","pattern":"compare_up","uz":"Natija ko'tarildi: o'tgan hafta {last_week}, bu hafta {this_week}.","en":"The result went up: {last_week} last week, {this_week} this week."},
  {"code":"P-compare-up-3","part":"compare","pattern":"compare_up","uz":"Bu hafta {this_week} vazifa o'z vaqtida bajarildi, o'tgan haftada esa {last_week} edi.","en":"This week {this_week} of tasks were on time, up from {last_week} last week."},
  {"code":"P-compare-same-1","part":"compare","pattern":"compare_same","uz":"Bu hafta {this_week}, o'tgan hafta {last_week} — natija deyarli o'zgarmagan.","en":"This week {this_week}, last week {last_week} — about the same."},
  {"code":"P-compare-same-2","part":"compare","pattern":"compare_same","uz":"Natija barqaror: o'tgan hafta {last_week}, bu hafta {this_week}.","en":"Steady: {last_week} last week, {this_week} this week."},
  {"code":"P-compare-same-3","part":"compare","pattern":"compare_same","uz":"O'tgan haftadagidek ({last_week}), bu hafta ham {this_week}.","en":"Much like last week ({last_week}), this week is {this_week}."},
  {"code":"P-compare-first-1","part":"compare","pattern":"compare_first","uz":"Bu hafta {this_week} vazifa o'z vaqtida bajarildi; o'tgan hafta bilan solishtirish uchun ma'lumot yo'q.","en":"This week {this_week} of tasks were done on time; there's no previous week to compare with."},
  {"code":"P-compare-first-2","part":"compare","pattern":"compare_first","uz":"Bu haftalik natija: {this_week}.","en":"This week's result: {this_week}."},
  {"code":"P-compare-first-3","part":"compare","pattern":"compare_first","uz":"Hozircha faqat bir haftalik ma'lumot bor: {this_week}.","en":"There's only one week of data so far: {this_week}."},

  {"code":"P-rhythm-every_day-1","part":"rhythm","pattern":"every_day","uz":"Hafta davomida birorta ham kun o'tkazib yuborilmadi.","en":"Not a single day was missed this week."},
  {"code":"P-rhythm-every_day-2","part":"rhythm","pattern":"every_day","uz":"Barcha vazifalar o'z kunida bajarildi — bu hafta bo'sh kun yo'q.","en":"Everything was done on its day — no empty days this week."},
  {"code":"P-rhythm-every_day-3","part":"rhythm","pattern":"every_day","uz":"U hafta bo'yi muntazam ishladi.","en":"They worked steadily all week."},
  {"code":"P-rhythm-weekend_gap-c-1","part":"rhythm","pattern":"weekend_gap","tone":"concern","uz":"Muammo hafta oxirida: {missed_days} bo'sh qolgan.","en":"The trouble is at the end of the week: {missed_days} stayed empty."},
  {"code":"P-rhythm-weekend_gap-c-2","part":"rhythm","pattern":"weekend_gap","tone":"concern","uz":"Hafta ichida ishlagan, lekin hafta oxiri bo'sh qolgan ({missed_days}) — dam olish kunlari tartib buzilmoqda.","en":"They work during the week, but the weekend stayed empty ({missed_days}) — the weekend routine is slipping."},
  {"code":"P-rhythm-weekend_gap-c-3","part":"rhythm","pattern":"weekend_gap","tone":"concern","uz":"O'tkazib yuborilgan kunlar faqat hafta oxirida: {missed_days}.","en":"The missed days are all at the weekend: {missed_days}."},
  {"code":"P-rhythm-weekend_gap-p-1","part":"rhythm","pattern":"weekend_gap","tone":"positive","uz":"Hafta ichida hammasi joyida, faqat hafta oxiri bo'sh qoldi: {missed_days}.","en":"The week went well; only the weekend stayed empty: {missed_days}."},
  {"code":"P-rhythm-weekend_gap-p-2","part":"rhythm","pattern":"weekend_gap","tone":"positive","uz":"Yagona bo'shliq — hafta oxiri ({missed_days}).","en":"The only gap was the weekend ({missed_days})."},
  {"code":"P-rhythm-weekend_gap-p-3","part":"rhythm","pattern":"weekend_gap","tone":"positive","uz":"Ish kunlari muntazam, hafta oxirida esa tanaffus bo'lgan: {missed_days}.","en":"Weekdays are steady; there was a break at the weekend: {missed_days}."},
  {"code":"P-rhythm-slow_start-1","part":"rhythm","pattern":"slow_start","uz":"Hafta sekin boshlangan: {missed_days} bo'sh qolgan.","en":"The week started slowly: {missed_days} stayed empty."},
  {"code":"P-rhythm-slow_start-2","part":"rhythm","pattern":"slow_start","uz":"O'tkazib yuborilgan kunlar hafta boshida: {missed_days}.","en":"The missed days are at the start of the week: {missed_days}."},
  {"code":"P-rhythm-slow_start-3","part":"rhythm","pattern":"slow_start","uz":"Hafta boshida tanaffus bo'lgan ({missed_days}), keyin ish yo'lga tushgan.","en":"There was a break at the start of the week ({missed_days}), then things got going."},
  {"code":"P-rhythm-block-1","part":"rhythm","pattern":"block","uz":"Bir necha kun ketma-ket bo'sh qolgan: {missed_days}.","en":"Several days in a row stayed empty: {missed_days}."},
  {"code":"P-rhythm-block-2","part":"rhythm","pattern":"block","uz":"Ketma-ket kunlar davomida hech narsa qilinmagan: {missed_days}.","en":"Nothing was done for several days running: {missed_days}."},
  {"code":"P-rhythm-block-3","part":"rhythm","pattern":"block","uz":"Uzun tanaffus bo'lgan: {missed_days}.","en":"There was a long break: {missed_days}."},
  {"code":"P-rhythm-spread-1","part":"rhythm","pattern":"spread","uz":"O'tkazib yuborilgan kunlar hafta bo'ylab tarqalgan: {missed_days}. Bu ko'pincha aniq o'qish vaqti yo'qligini bildiradi.","en":"The missed days are spread across the week: {missed_days}. That usually means there's no fixed study time."},
  {"code":"P-rhythm-spread-2","part":"rhythm","pattern":"spread","uz":"Bir kun ishlab, bir kun to'xtab qolmoqda — bo'sh kunlar: {missed_days}.","en":"On one day, off the next — the empty days: {missed_days}."},
  {"code":"P-rhythm-spread-3","part":"rhythm","pattern":"spread","uz":"Bo'shliqlar bir joyda emas, hafta bo'ylab: {missed_days}.","en":"The gaps aren't in one block but across the week: {missed_days}."},
  {"code":"P-rhythm-one_off-1","part":"rhythm","pattern":"one_off","uz":"Faqat bitta kun o'tkazib yuborilgan: {missed_days}.","en":"Only one day was missed: {missed_days}."},
  {"code":"P-rhythm-one_off-2","part":"rhythm","pattern":"one_off","uz":"{missed_days} kunidan tashqari hafta muntazam o'tgan.","en":"Apart from {missed_days}, the week was steady."},
  {"code":"P-rhythm-one_off-3","part":"rhythm","pattern":"one_off","uz":"Haftada bitta bo'sh kun bor: {missed_days}.","en":"There's one empty day this week: {missed_days}."},
  {"code":"P-rhythm-stopped-1","part":"rhythm","pattern":"stopped","uz":"Hafta boshida faol bo'lgan ({active_days}), lekin so'nggi kunlarda to'xtab qolgan: {missed_days}.","en":"Active early in the week ({active_days}), but nothing in the last days: {missed_days}."},
  {"code":"P-rhythm-stopped-2","part":"rhythm","pattern":"stopped","uz":"So'nggi kunlarda hech narsa qilinmagan ({missed_days}), garchi hafta boshida ishlagan bo'lsa ham.","en":"Nothing in the last few days ({missed_days}), although they worked earlier in the week."},
  {"code":"P-rhythm-stopped-3","part":"rhythm","pattern":"stopped","uz":"Ishlagan kunlari: {active_days}. Keyin to'xtagan.","en":"Active on {active_days}, then stopped."},
  {"code":"P-rhythm-restarted-1","part":"rhythm","pattern":"restarted","uz":"Hafta boshi bo'sh qolgan ({missed_days}), lekin so'nggi kunlarda yana ishlay boshladi: {active_days}.","en":"The start of the week was empty ({missed_days}), but they got going again: {active_days}."},
  {"code":"P-rhythm-restarted-2","part":"rhythm","pattern":"restarted","uz":"Hafta boshidagi tanaffusdan keyin yana faollashgan: {active_days}.","en":"Active again after a break early in the week: {active_days}."},
  {"code":"P-rhythm-restarted-3","part":"rhythm","pattern":"restarted","uz":"Hafta boshida to'xtagan, oxirida qaytgan ({active_days}).","en":"Stopped early in the week, came back at the end ({active_days})."},

  {"code":"P-habit-open_homework-1","part":"habit","pattern":"open_homework","uz":"Muddati {open_days} bo'lgan Learn vazifasi hali bajarilmagan.","en":"The Learn homework due {open_days} is still open."},
  {"code":"P-habit-open_homework-2","part":"habit","pattern":"open_homework","uz":"Hali bajarilmagan vazifa bor, muddati: {open_days}.","en":"There's still an open task, due {open_days}."},
  {"code":"P-habit-open_homework-3","part":"habit","pattern":"open_homework","uz":"Muddati o'tgan, ammo hali bajarilmagan vazifa: {open_days}.","en":"A task is past its deadline and still not done: {open_days}."},
  {"code":"P-habit-late-1","part":"habit","pattern":"late","uz":"{late_tasks} o'tkazib yuborilmagan, balki kechikib bajarilgan — demak, qiziqish yo'qolmagan.","en":"{late_tasks} was finished late rather than skipped, so the interest is still there."},
  {"code":"P-habit-late-2","part":"habit","pattern":"late","uz":"{late_tasks} muddatdan keyin bajarilgan: ish qilinmoqda, faqat vaqtida emas.","en":"{late_tasks} was done after the deadline: the work happens, just not on time."},
  {"code":"P-habit-late-3","part":"habit","pattern":"late","uz":"Kechikib bo'lsa ham, {late_tasks} bajarilgan.","en":"Even if late, {late_tasks} got done."},
  {"code":"P-habit-learn_no_review-1","part":"habit","pattern":"learn_no_review","uz":"Yangi so'zlarni o'rganmoqda, lekin takrorlashni ko'pincha o'tkazib yubormoqda.","en":"They learn new words, but often skip the reviews."},
  {"code":"P-habit-learn_no_review-2","part":"habit","pattern":"learn_no_review","uz":"Learn vazifalari bajarilgan, takrorlash esa orqada qolmoqda.","en":"Learn tasks are done, but reviews are falling behind."},
  {"code":"P-habit-learn_no_review-3","part":"habit","pattern":"learn_no_review","uz":"Takrorlashsiz yangi so'zlar tez unutiladi — hozir aynan takrorlash yetishmayapti.","en":"Without reviews new words fade fast — and reviews are what's missing now."},
  {"code":"P-habit-review_no_learn-1","part":"habit","pattern":"review_no_learn","uz":"Takrorlashni muntazam qilmoqda, lekin yangi Learn vazifalari bajarilmayapti.","en":"Reviews are regular, but new Learn tasks aren't getting done."},
  {"code":"P-habit-review_no_learn-2","part":"habit","pattern":"review_no_learn","uz":"Eski so'zlarni takrorlayapti, yangilarini esa o'rganmayapti.","en":"They review old words but aren't learning new ones."},
  {"code":"P-habit-review_no_learn-3","part":"habit","pattern":"review_no_learn","uz":"Takrorlash yaxshi, Learn vazifalari esa orqada.","en":"Reviews are fine; Learn tasks are behind."},

  {"code":"P-words-shared_hard-1","part":"words","pattern":"shared_hard","uz":"U {hard_words} so'zlarini qiyin deb belgilagan, bir nechta sinfdoshlari ham — bu so'zlarni butun sinf bilan qayta ko'rib chiqish foydali.","en":"They marked {hard_words} as Hard, and so did several classmates — worth going over with the whole class."},
  {"code":"P-words-shared_hard-2","part":"words","pattern":"shared_hard","uz":"{hard_words} — bu so'zlar unga ham, sinfdoshlariga ham qiyin.","en":"{hard_words} — these are hard for them and for classmates too."},
  {"code":"P-words-shared_hard-3","part":"words","pattern":"shared_hard","uz":"Sinf uchun umumiy qiyin so'zlar orasida uning so'zlari ham bor: {hard_words}.","en":"Their Hard words overlap with the class's: {hard_words}."},
  {"code":"P-words-many_hard-1","part":"words","pattern":"many_hard","uz":"U ko'p so'zni qiyin deb belgilagan ({hard_count}) — sinf o'rtachasidan ancha ko'p.","en":"They marked many words as Hard ({hard_count}) — well above the class average."},
  {"code":"P-words-many_hard-2","part":"words","pattern":"many_hard","uz":"Qiyin so'zlar ro'yxati uzun: {hard_count}. Ularni kichik qismlarga bo'lib takrorlash foydali bo'lishi mumkin.","en":"Their Hard list is long: {hard_count}. Going through it in small chunks may help."},
  {"code":"P-words-many_hard-3","part":"words","pattern":"many_hard","uz":"{hard_count} qiyin deb belgilangan — so'zlar unga og'irroq kelmoqda.","en":"{hard_count} marked Hard — the words are feeling heavy for them."},

  {"code":"P-action-reminder-1","part":"action","pattern":"act_reminder","uz":"Ochiq vazifa haqida {reminder:eslatma} uni yana yo'lga solishi mumkin.","en":"{reminder:A reminder} about the open task may get them back on track."},
  {"code":"P-action-reminder-2","part":"action","pattern":"act_reminder","uz":"{reminder:Qisqa eslatma} yetarli bo'lishi mumkin.","en":"{reminder:A short reminder} may be enough."},
  {"code":"P-action-reminder-3","part":"action","pattern":"act_reminder","uz":"Muddati o'tgan vazifa haqida {reminder:eslatma yuborish} mumkin.","en":"You could {reminder:send a reminder} about the overdue task."},
  {"code":"P-action-checkin-1","part":"action","pattern":"act_checkin","uz":"{checkin:Qisqa xabar} bilan hammasi joyidami, deb so'rash mumkin.","en":"{checkin:A short message} asking if everything is okay may help."},
  {"code":"P-action-checkin-2","part":"action","pattern":"act_checkin","uz":"Hafta oxiridan oldin {checkin:qisqa xabar} yuborish foydali bo'lishi mumkin.","en":"{checkin:A short message} before the weekend may help."},
  {"code":"P-action-checkin-3","part":"action","pattern":"act_checkin","uz":"{checkin:Bir og'iz so'rab qo'yish} yetarli bo'lishi mumkin.","en":"{checkin:A quick check-in} may be enough."},
  {"code":"P-action-praise-1","part":"action","pattern":"act_praise","uz":"{praise:Maqtov} uni shu sur'atda davom etishga undaydi.","en":"{praise:A word of praise} will keep them going."},
  {"code":"P-action-praise-2","part":"action","pattern":"act_praise","uz":"Bu natija uchun {praise:qisqa tabrik} yuborish mumkin.","en":"You could {praise:send a quick congratulation}."},
  {"code":"P-action-praise-3","part":"action","pattern":"act_praise","uz":"{praise:Rag'batlantiruvchi xabar} foydali bo'ladi.","en":"{praise:An encouraging message} would be welcome."},
  {"code":"P-action-message-1","part":"action","pattern":"act_message","uz":"{message:Qisqa xabar} uni yana faollashtirishi mumkin.","en":"{message:A short message} may help them pick up again."},
  {"code":"P-action-message-2","part":"action","pattern":"act_message","uz":"{message:Shaxsiy xabar} yuborish foydali bo'lishi mumkin.","en":"{message:A personal message} may help."},
  {"code":"P-action-message-3","part":"action","pattern":"act_message","uz":"{message:Bir necha so'z} bilan qo'llab-quvvatlash mumkin.","en":"{message:A few words} of support may help."},

  {"code":"P-special-new_student-1","part":"special","pattern":"new_student","uz":"{name} yaqinda qo'shildi, hozircha muddati o'tgan vazifa yo'q. Birinchi natijalar vazifalar berilgandan keyin ko'rinadi.","en":"{name} joined recently and has nothing due yet. The first results will show once tasks are assigned."},
  {"code":"P-special-new_student-2","part":"special","pattern":"new_student","uz":"{name} — yangi o'quvchi. Hali baholanadigan vazifa bo'lmadi.","en":"{name} is new to the class. Nothing has been due yet."},
  {"code":"P-special-new_student-3","part":"special","pattern":"new_student","uz":"{name} sinfga yangi qo'shilgan; xulosa uchun hali erta.","en":"{name} has just joined; it's too early for a conclusion."},
  {"code":"P-special-nothing_due-1","part":"special","pattern":"nothing_due","uz":"{name} uchun so'nggi 7 kunda muddati o'tgan vazifa bo'lmadi, shuning uchun hozircha xulosa yo'q.","en":"Nothing was due for {name} in the last 7 days, so there's no conclusion yet."},
  {"code":"P-special-nothing_due-2","part":"special","pattern":"nothing_due","uz":"Bu hafta {name} uchun baholanadigan vazifa yo'q edi. Muddat bilan yangi vazifa berish mumkin.","en":"{name} had nothing due this week. A new task with a deadline would give a picture."},
  {"code":"P-special-nothing_due-3","part":"special","pattern":"nothing_due","uz":"{name}: so'nggi haftada muddatli vazifa yo'q.","en":"{name}: no tasks with a deadline last week."}
]$json$::jsonb) as t(code text, part text, pattern text, tone text, uz text, en text)
on conflict (code) do nothing;
