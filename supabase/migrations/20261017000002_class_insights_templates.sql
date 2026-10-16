-- ─────────────────────────────────────────────────────────────────────────────
-- Smart insights, step 3: sentence templates + template picking
-- Run in the Supabase SQL Editor (after 20261017000001_class_insights_daily_job.sql)
--
-- insight_templates holds every sentence (Uzbek + English). Edit wording in
-- Table Editor → insight_templates; set active = false to retire a sentence
-- (don't delete — old snapshots point at it). Changes show from the next
-- nightly run.
--
-- Placeholders, filled by the app when it draws the page:
--   student: {name} {score} {done} {total} {days_skipped} {date} {prev_score}
--   class:   {count} {total_students} {names} {words}
--   {date} = last missed day, shown DD.MM.YYYY, plus (Bugun)/(Kecha) when it
--   is today or yesterday.
--
-- Picking (in run_daily_class_insights): students in the same class and the
-- same group (kind + level + trend) are shuffled by md5(student + date) and
-- take templates in turn, skipping the one they had yesterday. The choice is
-- saved, so it's stable all day. A missing trend (no previous week) uses the
-- 'steady' set, so steady sentences never claim a comparison. Level 1 has no
-- 'rising' set: a 0-9 score can't be 10+ points above the week before.
--
-- Also adds last_missed (for {date}) and attention_count, which changes
-- compute_student_insight's output — hence drop + recreate below.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.insight_templates (
  id         int generated always as identity primary key,
  code       text not null unique,
  kind       text not null check (kind in (
               'level', 'skipper', 'neutral',
               'class_summary', 'class_all_good', 'class_no_data', 'class_empty',
               'class_behind', 'class_well', 'class_hard', 'class_skipper')),
  level      int  check (level between 1 and 6),
  trend      text check (trend in ('rising', 'steady', 'falling')),
  text_uz    text not null,
  text_en    text,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.insight_templates enable row level security;

-- Wording only, nothing private: any signed-in user may read. Nobody writes
-- from the app; edit in the Supabase dashboard.
drop policy if exists insight_templates_read on public.insight_templates;
create policy insight_templates_read
  on public.insight_templates for select to authenticated
  using (true);

revoke all on public.insight_templates from anon, authenticated;
grant select on public.insight_templates to authenticated;

-- ── Snapshot columns ─────────────────────────────────────────────────────────

alter table public.class_insight_snapshots
  add column if not exists last_missed date;

alter table public.class_insight_class_snapshots
  add column if not exists attention_count int not null default 0;

do $$ begin
  alter table public.class_insight_snapshots
    add constraint class_insight_snapshots_template_fk
    foreign key (template_id) references insight_templates(id) on delete set null;
exception when duplicate_object then null; end $$;

do $$ begin
  alter table public.class_insight_class_snapshots
    add constraint cics_summary_template_fk foreign key (summary_template_id) references insight_templates(id) on delete set null,
    add constraint cics_behind_template_fk  foreign key (behind_template_id)  references insight_templates(id) on delete set null,
    add constraint cics_well_template_fk    foreign key (well_template_id)    references insight_templates(id) on delete set null,
    add constraint cics_hard_template_fk    foreign key (hard_template_id)    references insight_templates(id) on delete set null,
    add constraint cics_skipper_template_fk foreign key (skipper_template_id) references insight_templates(id) on delete set null;
exception when duplicate_object then null; end $$;

-- ── Scoring functions, now also returning last_missed ───────────────────────

drop function if exists public.compute_student_insight(uuid, uuid, date);
drop function if exists public.insight_window_counts(uuid, uuid, date, date);

create function public.insight_window_counts(
  p_class_id uuid,
  p_student_id uuid,
  p_from date,
  p_to date
) returns table(learn_due int, learn_done int, review_due int, review_done int, skipped_days int, last_missed date)
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
         (select count(*) from missed_days)::int,
         (select max(due_date) from missed_days);
$$;

create function public.compute_student_insight(
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
  last_missed date,
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
    v_cur.last_missed,
    v_prev_score,
    case
      when v_score is null or v_prev_score is null then null
      when v_score - v_prev_score >= 10  then 'rising'
      when v_score - v_prev_score <= -10 then 'falling'
      else 'steady'
    end;
end;
$$;

-- ── Template picking ────────────────────────────────────────────────────────

-- The template at position (hash(p_seed) + p_rank) in the group, moving one
-- along if that is p_avoid (yesterday's). Null if the group has no templates.
create or replace function public.pick_insight_template(
  p_kind text,
  p_level int,
  p_trend text,
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
   where active and kind = p_kind
     and level is not distinct from p_level
     and trend is not distinct from p_trend;

  if v_ids is null and p_kind = 'level' then
    select array_agg(id order by id) into v_ids
      from insight_templates
     where active and kind = 'level' and level = p_level and trend = 'steady';
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

-- ── Nightly job, now also picking templates ─────────────────────────────────

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
    learn_due, learn_done, review_due, review_done, days_skipped, last_missed,
    prev_score, window_start)
  select m.class_id, m.student_id, p_today,
         case when i.days_skipped >= 3 then 'skipper'
              when i.level is null     then 'neutral'
              else 'level' end,
         i.level, i.trend, i.score, i.done, i.total,
         i.learn_due, i.learn_done, i.review_due, i.review_done,
         i.days_skipped, i.last_missed, i.prev_score, i.window_start
    from class_members m
   cross join lateral compute_student_insight(m.class_id, m.student_id, p_today - 1) i
   where m.status = 'approved'
  on conflict (class_id, student_id, snapshot_date) do update set
    kind = excluded.kind, level = excluded.level, trend = excluded.trend,
    score = excluded.score, done = excluded.done, total = excluded.total,
    learn_due = excluded.learn_due, learn_done = excluded.learn_done,
    review_due = excluded.review_due, review_done = excluded.review_done,
    days_skipped = excluded.days_skipped, last_missed = excluded.last_missed,
    prev_score = excluded.prev_score, window_start = excluded.window_start,
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

revoke execute on function public.insight_window_counts(uuid, uuid, date, date)         from public, anon, authenticated;
revoke execute on function public.compute_student_insight(uuid, uuid, date)             from public, anon, authenticated;
revoke execute on function public.pick_insight_template(text, int, text, text, int, int) from public, anon, authenticated;
revoke execute on function public.run_daily_class_insights(date)                        from public, anon, authenticated;

-- ── Sentences ───────────────────────────────────────────────────────────────
-- Re-running this file never overwrites a sentence you edited (on conflict
-- do nothing, matched by code).

insert into public.insight_templates (code, kind, level, trend, text_uz, text_en)
select t.code, t.kind, t.level, t.trend, t.uz, t.en
  from jsonb_to_recordset($json$[
  {"code":"L1-steady-1","kind":"level","level":1,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan {done} tasini bajardi. Qisqa suhbat nima xalaqit berayotganini bilishga yordam berishi mumkin.","en":"{name} completed {done} of {total} tasks this week. A short chat may help find out what is getting in the way."},
  {"code":"L1-steady-2","kind":"level","level":1,"trend":"steady","uz":"{name} so'nggi 7 kunda deyarli vazifa bajarmadi ({done}/{total}). Bitta kichik vazifadan boshlashni taklif qilish mumkin.","en":"{name} did almost no tasks in the last 7 days ({done}/{total}). Suggesting one small task to start with may help."},
  {"code":"L1-steady-3","kind":"level","level":1,"trend":"steady","uz":"{name}: bu haftalik natija {score}% ({done}/{total}). Shaxsiy eslatma yuborish yordam berishi mumkin.","en":"{name}: this week's result is {score}% ({done}/{total}). A personal reminder may help."},
  {"code":"L1-steady-4","kind":"level","level":1,"trend":"steady","uz":"{name} hozircha vazifalarni deyarli boshlamayapti ({done}/{total}). Vazifalar ilovaning qayerida ekanini ko'rsatib berish mumkin.","en":"{name} is barely starting tasks right now ({done}/{total}). Showing them where tasks are in the app may help."},
  {"code":"L1-steady-5","kind":"level","level":1,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan faqat {done} tasini o'z vaqtida topshirdi. Vazifalarni kichikroq qismlarga bo'lish foydali bo'lishi mumkin.","en":"{name} handed in only {done} of {total} tasks on time this week. Splitting tasks into smaller pieces may help."},
  {"code":"L1-steady-6","kind":"level","level":1,"trend":"steady","uz":"{name} bu hafta faol bo'lmadi: {total} tadan {done} ta vazifa bajarildi. Hammasi joyidami, deb so'rab qo'yish mumkin.","en":"{name} was not active this week: {done} of {total} tasks done. It may be worth checking that everything is okay."},

  {"code":"L1-falling-1","kind":"level","level":1,"trend":"falling","uz":"{name} bu hafta {done}/{total} vazifani bajardi, o'tgan hafta esa {prev_score}% edi. Biror narsa o'zgarganini so'rab ko'rish mumkin.","en":"{name} completed {done}/{total} tasks this week, compared with {prev_score}% last week. Asking whether something changed may help."},
  {"code":"L1-falling-2","kind":"level","level":1,"trend":"falling","uz":"{name}: natija {prev_score}% dan {score}% ga tushdi. Imkon qadar tezroq suhbatlashish foydali bo'lishi mumkin.","en":"{name}: result dropped from {prev_score}% to {score}%. Talking soon may help."},
  {"code":"L1-falling-3","kind":"level","level":1,"trend":"falling","uz":"{name} o'tgan haftada ko'proq vazifa bajargan edi, bu hafta esa deyarli bajarmadi ({done}/{total}). Hammasi joyidami, deb so'rash mumkin.","en":"{name} did more tasks last week, but almost none this week ({done}/{total}). Checking that everything is okay may help."},
  {"code":"L1-falling-4","kind":"level","level":1,"trend":"falling","uz":"{name}: faollik keskin pasaydi ({prev_score}% → {score}%). Shaxsiy xabar yuborish mumkin.","en":"{name}: activity dropped sharply ({prev_score}% → {score}%). A personal message may help."},
  {"code":"L1-falling-5","kind":"level","level":1,"trend":"falling","uz":"{name} bu hafta {total} ta vazifadan {done} tasini topshirdi — avvalgi haftadan ancha kam. Vazifalarni qayta tushuntirib berish yordam berishi mumkin.","en":"{name} handed in {done} of {total} tasks this week, far fewer than the week before. Explaining the tasks again may help."},
  {"code":"L1-falling-6","kind":"level","level":1,"trend":"falling","uz":"{name} so'nggi 7 kunda {score}% vazifani bajardi (avval {prev_score}%). Qo'llab-quvvatlash hozir ayniqsa muhim bo'lishi mumkin.","en":"{name} completed {score}% of tasks in the last 7 days (before {prev_score}%). Support may matter most right now."},

  {"code":"L2-steady-1","kind":"level","level":2,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan {done} tasini o'z vaqtida bajardi. Vazifalar muddatini unga yana bir bor eslatish foydali bo'lishi mumkin.","en":"{name} completed {done} of {total} tasks on time this week. Reminding them of the deadlines once more may help."},
  {"code":"L2-steady-2","kind":"level","level":2,"trend":"steady","uz":"{name} vazifalarni kamdan-kam bajarmoqda: {done}/{total} ({score}%). Har kuni 5 daqiqalik qisqa mashg'ulot taklif qilish mumkin.","en":"{name} is rarely completing tasks: {done}/{total} ({score}%). Suggesting a short 5-minute daily session may help."},
  {"code":"L2-steady-3","kind":"level","level":2,"trend":"steady","uz":"{name}: so'nggi 7 kunda {score}% vazifa bajarildi. Qaysi vaqtda o'qish qulay ekanini so'rab ko'rish mumkin.","en":"{name}: {score}% of tasks done in the last 7 days. Asking which time of day suits them for studying may help."},
  {"code":"L2-steady-4","kind":"level","level":2,"trend":"steady","uz":"{name} {total} ta vazifadan atigi {done} tasini topshirdi. Keyingi vazifani dars paytida birga boshlab berish yordam berishi mumkin.","en":"{name} handed in only {done} of {total} tasks. Starting the next task together in class may help."},
  {"code":"L2-steady-5","kind":"level","level":2,"trend":"steady","uz":"{name} har o'nta vazifadan bir-ikkitasini bajarmoqda ({done}/{total}). Kuniga bitta vazifa kabi kichik maqsad qo'yish foydali bo'lishi mumkin.","en":"{name} is completing one or two of every ten tasks ({done}/{total}). A small goal, like one task a day, may help."},
  {"code":"L2-steady-6","kind":"level","level":2,"trend":"steady","uz":"{name}: {done}/{total} vazifa o'z vaqtida. Vazifalarni ilovada qanday topishni qisqacha ko'rsatib berish mumkin.","en":"{name}: {done}/{total} tasks on time. A quick demo of where tasks are in the app may help."},

  {"code":"L2-rising-1","kind":"level","level":2,"trend":"rising","uz":"{name} bu hafta {done}/{total} vazifani bajardi — o'tgan haftadagi {prev_score}% dan yuqori. Bu kichik qadamni e'tirof etish uni ruhlantirishi mumkin.","en":"{name} completed {done}/{total} tasks this week, up from {prev_score}% last week. Acknowledging this small step may encourage them."},
  {"code":"L2-rising-2","kind":"level","level":2,"trend":"rising","uz":"{name} asta-sekin faollashmoqda: {prev_score}% dan {score}% ga. Shu sur'atni saqlashga yordam berish mumkin.","en":"{name} is slowly becoming more active: from {prev_score}% to {score}%. Helping them keep this pace may be useful."},
  {"code":"L2-rising-3","kind":"level","level":2,"trend":"rising","uz":"{name} o'tgan haftaga qaraganda ko'proq vazifa bajardi ({score}%). Qisqa maqtov keyingi haftaga turtki bo'lishi mumkin.","en":"{name} did more tasks than last week ({score}%). A short word of praise may motivate them for next week."},
  {"code":"L2-rising-4","kind":"level","level":2,"trend":"rising","uz":"{name}: natija {prev_score}% dan {score}% ga ko'tarildi. Hali past, ammo o'sish bor — buni unga aytib qo'yish mumkin.","en":"{name}: result rose from {prev_score}% to {score}%. Still low, but growing — it may help to tell them so."},
  {"code":"L2-rising-5","kind":"level","level":2,"trend":"rising","uz":"{name} bu hafta {total} tadan {done} ta vazifani bajardi, bu o'tgan haftadan yaxshiroq. Keyingi maqsad sifatida kuniga bitta vazifani taklif qilish mumkin.","en":"{name} completed {done} of {total} tasks this week, better than last week. A next goal of one task a day may help."},
  {"code":"L2-rising-6","kind":"level","level":2,"trend":"rising","uz":"{name} vazifalarga qaytishni boshladi: {score}% (o'tgan hafta {prev_score}%). Qo'llab-quvvatlash bildirish foydali bo'lishi mumkin.","en":"{name} has started coming back to tasks: {score}% (last week {prev_score}%). Showing support may help."},

  {"code":"L2-falling-1","kind":"level","level":2,"trend":"falling","uz":"{name} bu hafta {done}/{total} vazifani bajardi, o'tgan hafta esa {prev_score}% edi. Biror narsa o'zgarganini so'rab ko'rish mumkin.","en":"{name} completed {done}/{total} tasks this week, compared with {prev_score}% last week. Asking whether something has changed may help."},
  {"code":"L2-falling-2","kind":"level","level":2,"trend":"falling","uz":"{name}: natija {prev_score}% dan {score}% ga tushdi. Qisqa suhbat sababini aniqlashga yordam berishi mumkin.","en":"{name}: result dropped from {prev_score}% to {score}%. A short chat may help find out why."},
  {"code":"L2-falling-3","kind":"level","level":2,"trend":"falling","uz":"{name} o'tgan haftaga nisbatan kamroq vazifa bajarmoqda ({score}%). Shaxsiy eslatma yuborish mumkin.","en":"{name} is doing fewer tasks than last week ({score}%). Sending a personal reminder may help."},
  {"code":"L2-falling-4","kind":"level","level":2,"trend":"falling","uz":"{name} bu hafta {total} ta vazifadan {done} tasini topshirdi — avvalgi haftadan kam. Vazifalar hajmi unga mos ekanini tekshirib ko'rish mumkin.","en":"{name} handed in {done} of {total} tasks this week, fewer than the week before. Checking whether the workload suits them may help."},
  {"code":"L2-falling-5","kind":"level","level":2,"trend":"falling","uz":"{name}: faollik pasaymoqda ({prev_score}% → {score}%). Buni erta muhokama qilish keyingi qiyinchiliklarning oldini olishi mumkin.","en":"{name}: activity is dropping ({prev_score}% → {score}%). Talking about it early may prevent bigger problems later."},
  {"code":"L2-falling-6","kind":"level","level":2,"trend":"falling","uz":"{name} so'nggi 7 kunda {done}/{total} vazifani bajardi, bu oldingisidan past. Unga yordam kerakmi, deb so'rash mumkin.","en":"{name} completed {done}/{total} tasks in the last 7 days, lower than before. Asking if they need help may be useful."},

  {"code":"L3-steady-1","kind":"level","level":3,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan {done} tasini bajardi ({score}%). Qolgan vazifalarni birga rejalashtirish foydali bo'lishi mumkin.","en":"{name} completed {done} of {total} tasks this week ({score}%). Planning the remaining tasks together may help."},
  {"code":"L3-steady-2","kind":"level","level":3,"trend":"steady","uz":"{name} vazifalarning kam qismini bajarmoqda ({done}/{total}). Muddatdan bir kun oldin eslatma yuborish yordam berishi mumkin.","en":"{name} is completing a small share of tasks ({done}/{total}). A reminder one day before the deadline may help."},
  {"code":"L3-steady-3","kind":"level","level":3,"trend":"steady","uz":"{name}: so'nggi 7 kunda {score}% vazifa o'z vaqtida bajarildi. Qaysi vazifalar qiyin tuyulayotganini so'rab ko'rish mumkin.","en":"{name}: {score}% of tasks done on time in the last 7 days. Asking which tasks feel hard may help."},
  {"code":"L3-steady-4","kind":"level","level":3,"trend":"steady","uz":"{name} ba'zi vazifalarni bajaryapti, ba'zilarini o'tkazib yubormoqda ({done}/{total}). Muntazam o'qish vaqtini belgilashni taklif qilish mumkin.","en":"{name} does some tasks and misses others ({done}/{total}). Suggesting a regular study time may help."},
  {"code":"L3-steady-5","kind":"level","level":3,"trend":"steady","uz":"{name} bu hafta {done} ta vazifani topshirdi, muddati o'tganlari esa {total} ta edi. Kichik va aniq maqsad qo'yish yordam berishi mumkin.","en":"{name} handed in {done} tasks this week, out of {total} that were due. A small, clear goal may help."},
  {"code":"L3-steady-6","kind":"level","level":3,"trend":"steady","uz":"{name}: {done}/{total}. Rag'batlantiruvchi so'z va bitta aniq vazifa keyingi haftada natijani oshirishi mumkin.","en":"{name}: {done}/{total}. A few words of encouragement and one clear task may lift next week's result."},

  {"code":"L3-rising-1","kind":"level","level":3,"trend":"rising","uz":"{name} bu hafta {done}/{total} vazifani bajardi — o'tgan haftadagi {prev_score}% dan yuqori. Bu o'sishni e'tirof etish mumkin.","en":"{name} completed {done}/{total} tasks this week, up from {prev_score}% last week. This progress is worth acknowledging."},
  {"code":"L3-rising-2","kind":"level","level":3,"trend":"rising","uz":"{name} faollashmoqda: {prev_score}% dan {score}% ga. Shu yo'nalishda davom etishga undash mumkin.","en":"{name} is getting more active: from {prev_score}% to {score}%. Encouraging them to keep going may help."},
  {"code":"L3-rising-3","kind":"level","level":3,"trend":"rising","uz":"{name}: natija ko'tarildi ({prev_score}% → {score}%). Qisqa maqtov foydali bo'lishi mumkin.","en":"{name}: result went up ({prev_score}% → {score}%). A short word of praise may help."},
  {"code":"L3-rising-4","kind":"level","level":3,"trend":"rising","uz":"{name} o'tgan haftaga qaraganda ko'proq vazifa topshirdi ({done}/{total}). Keyingi maqsadni birga belgilash mumkin.","en":"{name} handed in more tasks than last week ({done}/{total}). Setting the next goal together may help."},
  {"code":"L3-rising-5","kind":"level","level":3,"trend":"rising","uz":"{name} bu hafta yaxshi tomonga o'zgardi: {score}% (avval {prev_score}%). Shu odatni mustahkamlashga yordam berish mumkin.","en":"{name} changed for the better this week: {score}% (before {prev_score}%). Helping them keep this habit may be useful."},
  {"code":"L3-rising-6","kind":"level","level":3,"trend":"rising","uz":"{name} {total} ta vazifadan {done} tasini bajardi va o'tgan haftadan oldinda. Buni unga aytib qo'yish rag'bat bo'lishi mumkin.","en":"{name} completed {done} of {total} tasks, ahead of last week. Telling them so may motivate them."},

  {"code":"L3-falling-1","kind":"level","level":3,"trend":"falling","uz":"{name} bu hafta {done}/{total} vazifani bajardi, o'tgan hafta {prev_score}% edi. Biror narsa xalaqit berayotganini so'rab ko'rish mumkin.","en":"{name} completed {done}/{total} tasks this week; last week it was {prev_score}%. Asking whether something is getting in the way may help."},
  {"code":"L3-falling-2","kind":"level","level":3,"trend":"falling","uz":"{name}: natija {prev_score}% dan {score}% ga tushdi. Qisqa suhbat yordam berishi mumkin.","en":"{name}: result fell from {prev_score}% to {score}%. A short chat may help."},
  {"code":"L3-falling-3","kind":"level","level":3,"trend":"falling","uz":"{name} o'tgan haftaga nisbatan kamroq vazifa topshirmoqda ({score}%). Eslatma yuborish mumkin.","en":"{name} is handing in fewer tasks than last week ({score}%). A reminder may help."},
  {"code":"L3-falling-4","kind":"level","level":3,"trend":"falling","uz":"{name}: faollik pasaydi — {total} tadan {done} ta vazifa. Vazifalar hajmini qayta ko'rib chiqish mumkin.","en":"{name}: activity dropped — {done} of {total} tasks. Reviewing the workload may help."},
  {"code":"L3-falling-5","kind":"level","level":3,"trend":"falling","uz":"{name} bu hafta avvalgidan kam ishladi ({prev_score}% → {score}%). Erta qo'llab-quvvatlash vaziyatni tez o'nglashi mumkin.","en":"{name} did less this week than before ({prev_score}% → {score}%). Early support may turn this around quickly."},
  {"code":"L3-falling-6","kind":"level","level":3,"trend":"falling","uz":"{name} so'nggi 7 kunda {score}% vazifani bajardi, bu oldingi haftadan past. Unga yordam kerakmi, deb so'rash mumkin.","en":"{name} completed {score}% of tasks in the last 7 days, lower than the week before. Asking if they need help may be useful."},

  {"code":"L4-steady-1","kind":"level","level":4,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan {done} tasini bajardi ({score}%). Ko'pchilik vazifalarni muntazam bajarishga undash mumkin.","en":"{name} completed {done} of {total} tasks this week ({score}%). Encouraging them to do most tasks regularly may help."},
  {"code":"L4-steady-2","kind":"level","level":4,"trend":"steady","uz":"{name} vazifalarning taxminan yarmini bajarmoqda ({done}/{total}). Qolgan yarmiga nima xalaqit berayotganini so'rash mumkin.","en":"{name} is completing about half of the tasks ({done}/{total}). Asking what stops the other half may help."},
  {"code":"L4-steady-3","kind":"level","level":4,"trend":"steady","uz":"{name}: {score}% vazifa o'z vaqtida. Muddatlarni eslatib turish natijani yaxshilashi mumkin.","en":"{name}: {score}% of tasks on time. Deadline reminders may improve the result."},
  {"code":"L4-steady-4","kind":"level","level":4,"trend":"steady","uz":"{name} vazifalarning bir qismini bajarib, bir qismini o'tkazib yubormoqda ({done}/{total}). Kundalik qisqa reja tuzishni taklif qilish mumkin.","en":"{name} completes some tasks and skips others ({done}/{total}). Suggesting a short daily plan may help."},
  {"code":"L4-steady-5","kind":"level","level":4,"trend":"steady","uz":"{name} bu hafta {total} tadan {done} ta vazifani o'z vaqtida topshirdi. Yana bir nechta vazifa bajarilsa, natija yaxshi darajaga chiqadi.","en":"{name} handed in {done} of {total} tasks on time this week. A few more would bring them to a good level."},
  {"code":"L4-steady-6","kind":"level","level":4,"trend":"steady","uz":"{name}: {done}/{total}. Asos bor; muntazamlik ustida birga ishlash mumkin.","en":"{name}: {done}/{total}. There is a base to build on; working on consistency together may help."},

  {"code":"L4-rising-1","kind":"level","level":4,"trend":"rising","uz":"{name} bu hafta {done}/{total} vazifani bajardi — o'tgan haftadagi {prev_score}% dan yuqori. Bu o'sishni qayd etish mumkin.","en":"{name} completed {done}/{total} tasks this week, up from {prev_score}% last week. This progress is worth noting."},
  {"code":"L4-rising-2","kind":"level","level":4,"trend":"rising","uz":"{name} yaxshilanmoqda: {prev_score}% dan {score}% ga. Yana ozgina harakat bilan yaxshi darajaga yetadi.","en":"{name} is improving: from {prev_score}% to {score}%. A little more effort will reach a good level."},
  {"code":"L4-rising-3","kind":"level","level":4,"trend":"rising","uz":"{name}: natija ko'tarildi ({prev_score}% → {score}%). Maqtov va keyingi kichik maqsad foydali bo'lishi mumkin.","en":"{name}: result went up ({prev_score}% → {score}%). Praise and a small next goal may help."},
  {"code":"L4-rising-4","kind":"level","level":4,"trend":"rising","uz":"{name} o'tgan haftaga qaraganda ko'proq vazifa topshirdi ({done}/{total}). Shu sur'atni saqlashga undash mumkin.","en":"{name} handed in more tasks than last week ({done}/{total}). Encouraging them to keep this pace may help."},
  {"code":"L4-rising-5","kind":"level","level":4,"trend":"rising","uz":"{name} bu hafta oldinga siljidi: {score}% (avval {prev_score}%). Buni unga aytib qo'yish mumkin.","en":"{name} moved forward this week: {score}% (before {prev_score}%). It may help to tell them."},
  {"code":"L4-rising-6","kind":"level","level":4,"trend":"rising","uz":"{name} {total} ta vazifadan {done} tasini bajardi, o'tgan haftadan ko'proq, va yaxshi darajaga yaqinlashmoqda. Kichik rag'bat foydali bo'lishi mumkin.","en":"{name} completed {done} of {total} tasks, more than last week, and is getting close to a good level. A little encouragement may help."},

  {"code":"L4-falling-1","kind":"level","level":4,"trend":"falling","uz":"{name} bu hafta {done}/{total} vazifani bajardi, o'tgan hafta {prev_score}% edi. Sababini so'rab ko'rish mumkin.","en":"{name} completed {done}/{total} tasks this week; last week it was {prev_score}%. Asking why may help."},
  {"code":"L4-falling-2","kind":"level","level":4,"trend":"falling","uz":"{name}: natija {prev_score}% dan {score}% ga tushdi. Erta eslatma yordam berishi mumkin.","en":"{name}: result fell from {prev_score}% to {score}%. An early reminder may help."},
  {"code":"L4-falling-3","kind":"level","level":4,"trend":"falling","uz":"{name} o'tgan haftaga nisbatan kamroq vazifa topshirdi ({score}%). Qisqa suhbat foydali bo'lishi mumkin.","en":"{name} handed in fewer tasks than last week ({score}%). A short chat may help."},
  {"code":"L4-falling-4","kind":"level","level":4,"trend":"falling","uz":"{name}: faollik pasaymoqda ({prev_score}% → {score}%). Vazifalar hajmi mos ekanini tekshirish mumkin.","en":"{name}: activity is going down ({prev_score}% → {score}%). Checking that the workload fits may help."},
  {"code":"L4-falling-5","kind":"level","level":4,"trend":"falling","uz":"{name} bu hafta avvalgidan kam vazifa bajardi ({done}/{total}). Hozir qo'llab-quvvatlash pasayishni to'xtatishi mumkin.","en":"{name} did fewer tasks than before this week ({done}/{total}). Support now may stop the drop."},
  {"code":"L4-falling-6","kind":"level","level":4,"trend":"falling","uz":"{name} so'nggi 7 kunda {score}% vazifani bajardi, oldingi haftadan past. Unga yordam kerakmi, deb so'rash mumkin.","en":"{name} completed {score}% of tasks in the last 7 days, lower than the week before. Asking if they need help may be useful."},

  {"code":"L5-steady-1","kind":"level","level":5,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan {done} tasini bajardi ({score}%). Yaxshi natija; qolganlarini ham bajarishga undash mumkin.","en":"{name} completed {done} of {total} tasks this week ({score}%). A good result; encouraging them to finish the rest may help."},
  {"code":"L5-steady-2","kind":"level","level":5,"trend":"steady","uz":"{name} vazifalarning ko'pini o'z vaqtida bajarmoqda ({done}/{total}). Kichik maqtov shu odatni mustahkamlaydi.","en":"{name} is completing most tasks on time ({done}/{total}). A little praise will strengthen this habit."},
  {"code":"L5-steady-3","kind":"level","level":5,"trend":"steady","uz":"{name}: {score}% vazifa o'z vaqtida. Eng yuqori darajaga oz qoldi.","en":"{name}: {score}% of tasks on time. Not far from the top level."},
  {"code":"L5-steady-4","kind":"level","level":5,"trend":"steady","uz":"{name} yaxshi ishlamoqda ({done}/{total}). Biroz qiyinroq vazifa taklif qilish ham mumkin.","en":"{name} is working well ({done}/{total}). Offering a slightly harder task is also an option."},
  {"code":"L5-steady-5","kind":"level","level":5,"trend":"steady","uz":"{name} bu hafta {total} tadan {done} ta vazifani o'z vaqtida topshirdi. Shu yo'lda davom etishga undash mumkin.","en":"{name} handed in {done} of {total} tasks on time this week. Encouraging them to keep going may help."},
  {"code":"L5-steady-6","kind":"level","level":5,"trend":"steady","uz":"{name}: {done}/{total}. Yaxshi daraja; o'tkazib yuborilgan vazifalarni birga ko'rib chiqish mumkin.","en":"{name}: {done}/{total}. A good level; reviewing the missed tasks together may help."},

  {"code":"L5-rising-1","kind":"level","level":5,"trend":"rising","uz":"{name} bu hafta {done}/{total} vazifani bajardi — o'tgan haftadagi {prev_score}% dan yuqori. Bu yutuqni e'tirof etish mumkin.","en":"{name} completed {done}/{total} tasks this week, up from {prev_score}% last week. This achievement is worth recognising."},
  {"code":"L5-rising-2","kind":"level","level":5,"trend":"rising","uz":"{name} yaxshilanmoqda: {prev_score}% dan {score}% ga. Maqtov bilan rag'batlantirish mumkin.","en":"{name} is improving: from {prev_score}% to {score}%. Some praise may motivate them."},
  {"code":"L5-rising-3","kind":"level","level":5,"trend":"rising","uz":"{name}: natija ko'tarildi ({prev_score}% → {score}%) va eng yuqori darajaga yaqin. Kichik qo'shimcha maqsad qo'yish mumkin.","en":"{name}: result went up ({prev_score}% → {score}%), close to the top level. A small extra goal may help."},
  {"code":"L5-rising-4","kind":"level","level":5,"trend":"rising","uz":"{name} o'tgan haftaga qaraganda ko'proq vazifa topshirdi ({done}/{total}). Buni sinf oldida qayd etish mumkin.","en":"{name} handed in more tasks than last week ({done}/{total}). It could be mentioned in front of the class."},
  {"code":"L5-rising-5","kind":"level","level":5,"trend":"rising","uz":"{name} bu hafta yaxshi tomonga o'zgardi: {score}% (avval {prev_score}%). Shu odatni saqlashga undash mumkin.","en":"{name} changed for the better this week: {score}% (before {prev_score}%). Encouraging them to keep it up may help."},
  {"code":"L5-rising-6","kind":"level","level":5,"trend":"rising","uz":"{name} {total} ta vazifadan {done} tasini bajardi, o'tgan haftadan ko'proq. Yaxshi o'sish — buni unga aytib qo'yish mumkin.","en":"{name} completed {done} of {total} tasks, more than last week. Good growth — it may help to tell them."},

  {"code":"L5-falling-1","kind":"level","level":5,"trend":"falling","uz":"{name} bu hafta {done}/{total} vazifani bajardi, o'tgan hafta {prev_score}% edi. Hali yaxshi daraja, ammo pasayishga e'tibor berish mumkin.","en":"{name} completed {done}/{total} tasks this week; last week it was {prev_score}%. Still a good level, but the drop may be worth a look."},
  {"code":"L5-falling-2","kind":"level","level":5,"trend":"falling","uz":"{name}: natija {prev_score}% dan {score}% ga tushdi. Qisqa eslatma yetarli bo'lishi mumkin.","en":"{name}: result fell from {prev_score}% to {score}%. A short reminder may be enough."},
  {"code":"L5-falling-3","kind":"level","level":5,"trend":"falling","uz":"{name} o'tgan haftaga nisbatan kamroq vazifa topshirdi ({score}%). Hammasi joyidami, deb so'rash mumkin.","en":"{name} handed in fewer tasks than last week ({score}%). Checking that all is well may help."},
  {"code":"L5-falling-4","kind":"level","level":5,"trend":"falling","uz":"{name}: natija pasaydi ({prev_score}% → {score}%), ammo hali yaxshi darajada. Kuzatib borish mumkin.","en":"{name}: result dropped ({prev_score}% → {score}%) but is still at a good level. Worth keeping an eye on."},
  {"code":"L5-falling-5","kind":"level","level":5,"trend":"falling","uz":"{name} bu hafta avvalgidan kam vazifa bajardi ({done}/{total}). O'tkazib yuborilganlarini eslatib qo'yish mumkin.","en":"{name} did fewer tasks than before this week ({done}/{total}). Reminding them of the missed ones may help."},
  {"code":"L5-falling-6","kind":"level","level":5,"trend":"falling","uz":"{name} so'nggi 7 kunda {score}% vazifani bajardi, oldingi haftadan past. Yordam kerakmi, deb so'rash mumkin.","en":"{name} completed {score}% of tasks in the last 7 days, lower than the week before. Asking if they need help may be useful."},

  {"code":"L6-steady-1","kind":"level","level":6,"trend":"steady","uz":"{name} bu hafta {total} ta vazifadan {done} tasini o'z vaqtida bajardi. Ajoyib natija — buni e'tirof etish mumkin.","en":"{name} completed {done} of {total} tasks on time this week. An excellent result worth recognising."},
  {"code":"L6-steady-2","kind":"level","level":6,"trend":"steady","uz":"{name} deyarli barcha vazifalarni bajarmoqda ({done}/{total}). Qo'shimcha, qiyinroq vazifa taklif qilish mumkin.","en":"{name} is completing almost every task ({done}/{total}). Offering an extra, harder task may suit them."},
  {"code":"L6-steady-3","kind":"level","level":6,"trend":"steady","uz":"{name}: {score}% vazifa o'z vaqtida. Maqtov shu odatni mustahkamlashi mumkin.","en":"{name}: {score}% of tasks on time. Praise may help keep this habit."},
  {"code":"L6-steady-4","kind":"level","level":6,"trend":"steady","uz":"{name} juda yaxshi ishlamoqda ({done}/{total}). Unga kichik yetakchilik vazifasi berish mumkin, masalan, sinfdoshlariga yordam.","en":"{name} is doing very well ({done}/{total}). They could be given a small leading role, like helping classmates."},
  {"code":"L6-steady-5","kind":"level","level":6,"trend":"steady","uz":"{name} bu hafta {total} tadan {done} ta vazifani o'z vaqtida topshirdi. Shu sur'atni saqlashga undash mumkin.","en":"{name} handed in {done} of {total} tasks on time this week. Encouraging them to keep this pace may help."},
  {"code":"L6-steady-6","kind":"level","level":6,"trend":"steady","uz":"{name}: {done}/{total}. Yuqori natija; keyingi bosqichga o'tishni o'ylab ko'rish mumkin.","en":"{name}: {done}/{total}. A high result; moving them on to the next stage could be considered."},

  {"code":"L6-rising-1","kind":"level","level":6,"trend":"rising","uz":"{name} bu hafta {done}/{total} vazifani bajardi — o'tgan haftadagi {prev_score}% dan ancha yuqori. Bu yutuqni nishonlash mumkin.","en":"{name} completed {done}/{total} tasks this week, well up from {prev_score}% last week. This success is worth celebrating."},
  {"code":"L6-rising-2","kind":"level","level":6,"trend":"rising","uz":"{name} katta qadam tashladi: {prev_score}% dan {score}% ga. Maqtov bilan rag'batlantirish mumkin.","en":"{name} made a big step: from {prev_score}% to {score}%. Some praise may motivate them."},
  {"code":"L6-rising-3","kind":"level","level":6,"trend":"rising","uz":"{name}: natija eng yuqori darajaga ko'tarildi ({prev_score}% → {score}%). Buni unga aytib qo'yish mumkin.","en":"{name}: result rose to the top level ({prev_score}% → {score}%). It may help to tell them."},
  {"code":"L6-rising-4","kind":"level","level":6,"trend":"rising","uz":"{name} o'tgan haftaga qaraganda ancha ko'p vazifa topshirdi ({done}/{total}). Shu odatni saqlashga undash mumkin.","en":"{name} handed in many more tasks than last week ({done}/{total}). Encouraging them to keep this habit may help."},
  {"code":"L6-rising-5","kind":"level","level":6,"trend":"rising","uz":"{name} bu hafta eng yuqori darajaga chiqdi: {score}% (avval {prev_score}%). Sinf oldida qayd etish mumkin.","en":"{name} reached the top level this week: {score}% (before {prev_score}%). It could be mentioned in front of the class."},
  {"code":"L6-rising-6","kind":"level","level":6,"trend":"rising","uz":"{name} {total} ta vazifadan {done} tasini bajardi va o'tgan haftadan sezilarli oldinda. Ajoyib o'sish — uni tabriklash mumkin.","en":"{name} completed {done} of {total} tasks, clearly ahead of last week. Great growth — a quick congratulation may help."},

  {"code":"L6-falling-1","kind":"level","level":6,"trend":"falling","uz":"{name} bu hafta {done}/{total} vazifani bajardi, o'tgan hafta {prev_score}% edi. Hali ham juda yaxshi natija; qisqa eslatma yetarli.","en":"{name} completed {done}/{total} tasks this week; last week it was {prev_score}%. Still a very good result; a short reminder is enough."},
  {"code":"L6-falling-2","kind":"level","level":6,"trend":"falling","uz":"{name}: natija {prev_score}% dan {score}% ga tushdi, ammo yuqori darajada qoldi. Kuzatib borish mumkin.","en":"{name}: result dipped from {prev_score}% to {score}% but stays at the top level. Worth keeping an eye on."},
  {"code":"L6-falling-3","kind":"level","level":6,"trend":"falling","uz":"{name} o'tgan haftaga nisbatan biroz kamroq vazifa topshirdi ({score}%). Hozircha xavotirga sabab yo'q.","en":"{name} handed in slightly fewer tasks than last week ({score}%). No cause for concern for now."},
  {"code":"L6-falling-4","kind":"level","level":6,"trend":"falling","uz":"{name} bu hafta {total} ta vazifadan {done} tasini bajardi. Natija biroz pasaydi ({prev_score}% → {score}%), lekin hali a'lo; o'tkazib yuborilganini eslatish mumkin.","en":"{name} completed {done} of {total} tasks this week. The result dipped a little ({prev_score}% → {score}%) but is still great; a reminder about the missed ones may help."},
  {"code":"L6-falling-5","kind":"level","level":6,"trend":"falling","uz":"{name}: {done}/{total}. Avvalgi haftadan biroz past, ammo hali eng yuqori darajada. Rag'batlantiruvchi so'z foydali bo'lishi mumkin.","en":"{name}: {done}/{total}. A little lower than last week, but still at the top level. A word of encouragement may help."},
  {"code":"L6-falling-6","kind":"level","level":6,"trend":"falling","uz":"{name} so'nggi 7 kunda {score}% vazifani bajardi (avval {prev_score}%). Hammasi joyidami, deb so'rab qo'yish mumkin.","en":"{name} completed {score}% of tasks in the last 7 days (before {prev_score}%). Checking that all is well may help."},

  {"code":"skipper-1","kind":"skipper","uz":"{name} so'nggi 7 kundan {days_skipped} kunida vazifani o'tkazib yubordi, oxirgisi {date}. Qisqa eslatma yordam berishi mumkin.","en":"{name} missed tasks on {days_skipped} of the last 7 days, most recently {date}. A short reminder may help."},
  {"code":"skipper-2","kind":"skipper","uz":"{name} bu hafta {days_skipped} kun vazifa yoki takrorlashni bajarmadi, oxirgi marta {date}. Kundalik qisqa odat taklif qilish mumkin.","en":"{name} skipped tasks or reviews on {days_skipped} days this week, most recently {date}. Suggesting a short daily habit may help."},
  {"code":"skipper-3","kind":"skipper","uz":"{name}: {days_skipped} kun o'tkazib yuborilgan, oxirgisi {date}. Qaysi vaqt o'qish uchun qulay ekanini so'rash mumkin.","en":"{name}: {days_skipped} days missed, the last on {date}. Asking which time suits them for study may help."},
  {"code":"skipper-4","kind":"skipper","uz":"{name} vazifalarni muntazam o'tkazib yubormoqda: 7 kundan {days_skipped} kuni. Eslatmalarni yoqishni taklif qilish mumkin.","en":"{name} is regularly missing tasks: {days_skipped} of 7 days. Suggesting they turn on reminders may help."},
  {"code":"skipper-5","kind":"skipper","uz":"{name} so'nggi haftada {days_skipped} kun vazifasiz qoldi ({done}/{total} bajarildi). Qisqa suhbat sababini aniqlashga yordam berishi mumkin.","en":"{name} had {days_skipped} days without doing tasks last week ({done}/{total} done). A short chat may help find the reason."},
  {"code":"skipper-6","kind":"skipper","uz":"{name}: oxirgi o'tkazib yuborilgan kun — {date}, jami {days_skipped} kun. Har kuni 5 daqiqa ajratishni taklif qilish mumkin.","en":"{name}: last missed day was {date}, {days_skipped} days in total. Suggesting 5 minutes a day may help."},

  {"code":"neutral-1","kind":"neutral","uz":"{name}: so'nggi 7 kunda muddati o'tgan vazifa bo'lmadi.","en":"{name}: no tasks were due in the last 7 days."},
  {"code":"neutral-2","kind":"neutral","uz":"{name} uchun bu hafta baholanadigan vazifa yo'q edi.","en":"{name} had no tasks due this week."},
  {"code":"neutral-3","kind":"neutral","uz":"{name}: hozircha xulosa uchun ma'lumot yetarli emas.","en":"{name}: not enough data for a summary yet."},
  {"code":"neutral-4","kind":"neutral","uz":"{name} bu hafta topshirishi kerak bo'lgan vazifa bo'lmadi. Yangi vazifa berish mumkin.","en":"{name} had nothing due this week. A new task could be assigned."},
  {"code":"neutral-5","kind":"neutral","uz":"{name}: so'nggi haftada muddatli vazifa yo'q. Natija vazifalar berilgandan keyin ko'rinadi.","en":"{name}: no tasks with a deadline last week. Results will show once tasks are assigned."},
  {"code":"neutral-6","kind":"neutral","uz":"{name} uchun hali hisoblanadigan vazifalar yo'q.","en":"{name} has no tasks to count yet."},

  {"code":"class-summary-1","kind":"class_summary","uz":"Bugun {count} nafar o'quvchiga e'tibor kerak.","en":"{count} students need attention today."},
  {"code":"class-summary-2","kind":"class_summary","uz":"{total_students} nafar o'quvchidan {count} nafari bugun e'tiborga muhtoj.","en":"{count} of {total_students} students need attention today."},
  {"code":"class-summary-3","kind":"class_summary","uz":"Bugun {count} nafar o'quvchi bilan bog'lanish foydali bo'lishi mumkin.","en":"It may help to reach out to {count} students today."},
  {"code":"class-summary-4","kind":"class_summary","uz":"Sinfda {count} nafar o'quvchi orqada qolmoqda yoki vazifalarni o'tkazib yubormoqda.","en":"{count} students in the class are falling behind or missing tasks."},
  {"code":"class-summary-5","kind":"class_summary","uz":"{count} nafar o'quvchi uchun qisqa eslatma foydali bo'lishi mumkin.","en":"A short reminder may help {count} students."},
  {"code":"class-summary-6","kind":"class_summary","uz":"Bugungi ro'yxat: {count} nafar o'quvchi e'tiborni talab qiladi.","en":"Today's list: {count} students need attention."},

  {"code":"class-all-good-1","kind":"class_all_good","uz":"Bugun barcha o'quvchilar yaxshi ketmoqda. Ajoyib!","en":"All students are on track today. Great!"},
  {"code":"class-all-good-2","kind":"class_all_good","uz":"Hech kim orqada qolmayapti — sinf yaxshi ishlamoqda.","en":"Nobody is falling behind — the class is doing well."},
  {"code":"class-all-good-3","kind":"class_all_good","uz":"Bugun e'tibor talab qiladigan o'quvchi yo'q.","en":"No students need attention today."},
  {"code":"class-all-good-4","kind":"class_all_good","uz":"Barcha o'quvchilar vazifalarni yetarli darajada bajarmoqda.","en":"All students are keeping up with their tasks."},
  {"code":"class-all-good-5","kind":"class_all_good","uz":"Sinf yaxshi holatda: hech kim vazifalarni muntazam o'tkazib yubormayapti.","en":"The class is in good shape: nobody is regularly missing tasks."},
  {"code":"class-all-good-6","kind":"class_all_good","uz":"Bugun hamma joyida. Sinfni maqtash uchun yaxshi kun!","en":"Everyone is on track today. A good day to praise the class!"},

  {"code":"class-no-data-1","kind":"class_no_data","uz":"So'nggi 7 kunda muddati o'tgan vazifa bo'lmadi, shuning uchun hozircha xulosa yo'q.","en":"No tasks were due in the last 7 days, so there are no insights yet."},
  {"code":"class-no-data-2","kind":"class_no_data","uz":"Xulosalar muddatli vazifalar berilgandan keyin paydo bo'ladi.","en":"Insights appear once tasks with a deadline are assigned."},
  {"code":"class-no-data-3","kind":"class_no_data","uz":"Bu hafta baholanadigan vazifalar yo'q edi. Muddat bilan yangi vazifa berib ko'ring.","en":"There were no tasks due this week. Try assigning a new task with a deadline."},

  {"code":"class-empty-1","kind":"class_empty","uz":"Sinfda hali o'quvchi yo'q.","en":"There are no students in this class yet."},
  {"code":"class-empty-2","kind":"class_empty","uz":"O'quvchilar qo'shilgandan keyin xulosalar shu yerda chiqadi.","en":"Insights will appear here once students join."},

  {"code":"class-behind-1","kind":"class_behind","uz":"Orqada qolayotganlar ({count}): {names}.","en":"Falling behind ({count}): {names}."},
  {"code":"class-behind-2","kind":"class_behind","uz":"Bu hafta vazifalarning kam qismini bajarganlar: {names}.","en":"Completed few of their tasks this week: {names}."},
  {"code":"class-behind-3","kind":"class_behind","uz":"{count} nafar o'quvchi vazifalarning 40% dan kamini bajardi: {names}.","en":"{count} students completed less than 40% of their tasks: {names}."},
  {"code":"class-behind-4","kind":"class_behind","uz":"Qo'shimcha yordam kerak bo'lishi mumkin: {names}.","en":"These students may need extra help: {names}."},
  {"code":"class-behind-5","kind":"class_behind","uz":"Bu hafta past natija: {names}. Ular bilan qisqa suhbat foydali bo'lishi mumkin.","en":"Low results this week: {names}. A short chat with them may help."},
  {"code":"class-behind-6","kind":"class_behind","uz":"{count} nafar o'quvchiga eslatma yuborish mumkin: {names}.","en":"A reminder could be sent to {count} students: {names}."},

  {"code":"class-well-1","kind":"class_well","uz":"Yaxshi ishlayotganlar ({count}): {names}.","en":"Doing well ({count}): {names}."},
  {"code":"class-well-2","kind":"class_well","uz":"Bu hafta vazifalarning ko'pini o'z vaqtida bajarganlar: {names}.","en":"Completed most of their tasks on time this week: {names}."},
  {"code":"class-well-3","kind":"class_well","uz":"{count} nafar o'quvchi 60% dan yuqori natija ko'rsatdi: {names}.","en":"{count} students scored above 60%: {names}."},
  {"code":"class-well-4","kind":"class_well","uz":"Maqtovga loyiq: {names}.","en":"Worth praising: {names}."},
  {"code":"class-well-5","kind":"class_well","uz":"Bu hafta yuqori natija: {names}. Ularni rag'batlantirish mumkin.","en":"High results this week: {names}. They could be encouraged."},
  {"code":"class-well-6","kind":"class_well","uz":"Yaxshi sur'at bilan ketayotganlar: {names}.","en":"Keeping a good pace: {names}."},

  {"code":"class-hard-1","kind":"class_hard","uz":"Bir nechta o'quvchi qiyin deb belgilagan so'zlar: {words}.","en":"Words several students marked Hard: {words}."},
  {"code":"class-hard-2","kind":"class_hard","uz":"Bu so'zlarni darsda qayta ko'rib chiqish foydali bo'lishi mumkin: {words}.","en":"Going over these words in class may help: {words}."},
  {"code":"class-hard-3","kind":"class_hard","uz":"Sinf uchun qiyin so'zlar: {words}.","en":"Hard words for the class: {words}."},
  {"code":"class-hard-4","kind":"class_hard","uz":"{count} ta so'z kamida 3 nafar o'quvchi tomonidan qiyin deb belgilandi: {words}.","en":"{count} words were marked Hard by at least 3 students: {words}."},
  {"code":"class-hard-5","kind":"class_hard","uz":"Qiyin so'zlar: {words}. Ular uchun qo'shimcha misollar foydali bo'lishi mumkin.","en":"Hard words: {words}. Extra examples for them may help."},
  {"code":"class-hard-6","kind":"class_hard","uz":"O'quvchilar ko'proq qiynalayotgan so'zlar: {words}.","en":"Words students are struggling with most: {words}."},

  {"code":"class-skipper-1","kind":"class_skipper","uz":"Tez-tez o'tkazib yuborayotganlar ({count}): {names}.","en":"Often missing tasks ({count}): {names}."},
  {"code":"class-skipper-2","kind":"class_skipper","uz":"So'nggi 7 kunning kamida 3 kunida vazifani o'tkazib yuborganlar: {names}.","en":"Missed tasks on at least 3 of the last 7 days: {names}."},
  {"code":"class-skipper-3","kind":"class_skipper","uz":"{count} nafar o'quvchi vazifalarni muntazam o'tkazib yubormoqda: {names}.","en":"{count} students are regularly missing tasks: {names}."},
  {"code":"class-skipper-4","kind":"class_skipper","uz":"Eslatmalarni yoqish foydali bo'lishi mumkin: {names}.","en":"Turning on reminders may help: {names}."},
  {"code":"class-skipper-5","kind":"class_skipper","uz":"Bu hafta ko'p kun o'tkazib yuborilgan: {names}. Kundalik qisqa odat taklif qilish mumkin.","en":"Many missed days this week: {names}. Suggesting a short daily habit may help."},
  {"code":"class-skipper-6","kind":"class_skipper","uz":"{count} nafar o'quvchi bilan muntazamlik haqida gaplashish mumkin: {names}.","en":"It may help to talk about consistency with {count} students: {names}."}
]$json$::jsonb) as t(code text, kind text, level int, trend text, uz text, en text)
on conflict (code) do nothing;
