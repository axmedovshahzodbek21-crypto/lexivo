-- ─────────────────────────────────────────────────────────────────────────────
-- Server-side word counts for collection-based homework
-- Run this in Supabase SQL Editor
--
-- record_class_homework_progress (20260818_secure_class_homework_progress.sql)
-- computes homework XP from a word count that Postgres itself verifies for
-- every content source except one: collection_name + day_number homework,
-- whose words live only in the static JSON files bundled with each client
-- (word_data.json, a1/a2/b1_collection.json), not in a Postgres table. That
-- path clamps the client-supplied count to 50 but otherwise trusts it — a
-- modified client can claim up to 50 words on an 8-word day (learn mode: 10
-- xp/word, so up to 500 xp for content that should pay ~80), acknowledged as
-- a deliberate but incomplete trade-off in that migration's own comment.
--
-- This mirrors the (collection_name, day_number) -> word_count mapping from
-- both apps' bundled JSON into Postgres (extracted 2026-08-21; Flutter's
-- lib/data/*.dart and web's public/data/*.json agree on day counts for all
-- six collections) so the RPC can verify this path server-side exactly like
-- every other one, closing the last client-trusted XP input.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists collection_day_word_counts (
  collection_name text not null,
  day_number integer not null,
  word_count integer not null,
  primary key (collection_name, day_number)
);

alter table collection_day_word_counts enable row level security;

do $$ begin
  create policy collection_day_word_counts_read on collection_day_word_counts for select
    using (true);
exception when duplicate_object then null; end $$;

insert into collection_day_word_counts (collection_name, day_number, word_count) values
  ('30 Days of Powerful Words', 1, 15),
  ('30 Days of Powerful Words', 2, 15),
  ('30 Days of Powerful Words', 3, 15),
  ('30 Days of Powerful Words', 4, 15),
  ('30 Days of Powerful Words', 5, 15),
  ('30 Days of Powerful Words', 6, 15),
  ('30 Days of Powerful Words', 7, 15),
  ('30 Days of Powerful Words', 8, 15),
  ('30 Days of Powerful Words', 9, 15),
  ('30 Days of Powerful Words', 10, 15),
  ('30 Days of Powerful Words', 11, 15),
  ('30 Days of Powerful Words', 12, 15),
  ('30 Days of Powerful Words', 13, 15),
  ('30 Days of Powerful Words', 14, 15),
  ('30 Days of Powerful Words', 15, 15),
  ('30 Days of Powerful Words', 16, 15),
  ('30 Days of Powerful Words', 17, 15),
  ('30 Days of Powerful Words', 18, 15),
  ('30 Days of Powerful Words', 19, 15),
  ('30 Days of Powerful Words', 20, 15),
  ('30 Days of Powerful Words', 21, 15),
  ('30 Days of Powerful Words', 22, 15),
  ('30 Days of Powerful Words', 23, 15),
  ('30 Days of Powerful Words', 24, 15),
  ('30 Days of Powerful Words', 25, 15),
  ('30 Days of Powerful Words', 26, 15),
  ('30 Days of Powerful Words', 27, 15),
  ('30 Days of Powerful Words', 28, 15),
  ('30 Days of Powerful Words', 29, 15),
  ('30 Days of Powerful Words', 30, 15),
  ('24 Vocabulary Challenge', 1, 30),
  ('24 Vocabulary Challenge', 2, 30),
  ('24 Vocabulary Challenge', 3, 30),
  ('24 Vocabulary Challenge', 4, 30),
  ('24 Vocabulary Challenge', 5, 30),
  ('24 Vocabulary Challenge', 6, 30),
  ('24 Vocabulary Challenge', 7, 30),
  ('24 Vocabulary Challenge', 8, 30),
  ('24 Vocabulary Challenge', 9, 30),
  ('24 Vocabulary Challenge', 10, 30),
  ('24 Vocabulary Challenge', 11, 30),
  ('24 Vocabulary Challenge', 12, 30),
  ('24 Vocabulary Challenge', 13, 30),
  ('24 Vocabulary Challenge', 14, 30),
  ('24 Vocabulary Challenge', 15, 30),
  ('24 Vocabulary Challenge', 16, 30),
  ('24 Vocabulary Challenge', 17, 30),
  ('24 Vocabulary Challenge', 18, 30),
  ('24 Vocabulary Challenge', 19, 30),
  ('24 Vocabulary Challenge', 20, 30),
  ('24 Vocabulary Challenge', 21, 30),
  ('24 Vocabulary Challenge', 22, 30),
  ('24 Vocabulary Challenge', 23, 30),
  ('24 Vocabulary Challenge', 24, 30),
  ('Word Mastery', 1, 10),
  ('Word Mastery', 2, 10),
  ('Word Mastery', 3, 10),
  ('Word Mastery', 4, 10),
  ('Word Mastery', 5, 10),
  ('Word Mastery', 6, 10),
  ('Word Mastery', 7, 10),
  ('Word Mastery', 8, 10),
  ('Word Mastery', 9, 10),
  ('Word Mastery', 10, 10),
  ('Word Mastery', 11, 10),
  ('Word Mastery', 12, 10),
  ('Word Mastery', 13, 10),
  ('Word Mastery', 14, 10),
  ('Word Mastery', 15, 10),
  ('Word Mastery', 16, 10),
  ('Word Mastery', 17, 10),
  ('Word Mastery', 18, 10),
  ('Word Mastery', 19, 10),
  ('Word Mastery', 20, 10),
  ('Word Mastery', 21, 10),
  ('Word Mastery', 22, 10),
  ('Word Mastery', 23, 10),
  ('Word Mastery', 24, 10),
  ('Word Mastery', 25, 10),
  ('Word Mastery', 26, 10),
  ('Word Mastery', 27, 10),
  ('Word Mastery', 28, 10),
  ('Word Mastery', 29, 10),
  ('Word Mastery', 30, 10),
  ('Word Mastery', 31, 10),
  ('Word Mastery', 32, 10),
  ('A1', 1, 40),
  ('A1', 2, 40),
  ('A1', 3, 40),
  ('A1', 4, 40),
  ('A1', 5, 40),
  ('A1', 6, 40),
  ('A1', 7, 40),
  ('A1', 8, 40),
  ('A1', 9, 40),
  ('A1', 10, 40),
  ('A1', 11, 40),
  ('A1', 12, 40),
  ('A1', 13, 40),
  ('A1', 14, 40),
  ('A1', 15, 40),
  ('A1', 16, 40),
  ('A1', 17, 40),
  ('A1', 18, 0),
  ('A1', 19, 0),
  ('A1', 20, 0),
  ('A1', 21, 0),
  ('A1', 22, 0),
  ('A1', 23, 0),
  ('A2', 1, 40),
  ('A2', 2, 40),
  ('A2', 3, 40),
  ('A2', 4, 40),
  ('A2', 5, 40),
  ('A2', 6, 40),
  ('A2', 7, 40),
  ('A2', 8, 40),
  ('A2', 9, 40),
  ('A2', 10, 40),
  ('A2', 11, 40),
  ('A2', 12, 40),
  ('A2', 13, 0),
  ('A2', 14, 0),
  ('A2', 15, 0),
  ('A2', 16, 0),
  ('A2', 17, 0),
  ('A2', 18, 0),
  ('A2', 19, 0),
  ('A2', 20, 0),
  ('A2', 21, 0),
  ('A2', 22, 0),
  ('A2', 23, 0),
  ('A2', 24, 0),
  ('A2', 25, 0),
  ('A2', 26, 0),
  ('A2', 27, 0),
  ('A2', 28, 0),
  ('A2', 29, 0),
  ('A2', 30, 0),
  ('B1', 1, 40),
  ('B1', 2, 40),
  ('B1', 3, 40),
  ('B1', 4, 40),
  ('B1', 5, 40),
  ('B1', 6, 40),
  ('B1', 7, 40),
  ('B1', 8, 40),
  ('B1', 9, 40),
  ('B1', 10, 40),
  ('B1', 11, 40),
  ('B1', 12, 40),
  ('B1', 13, 0),
  ('B1', 14, 0),
  ('B1', 15, 0),
  ('B1', 16, 0),
  ('B1', 17, 0),
  ('B1', 18, 0),
  ('B1', 19, 0),
  ('B1', 20, 0),
  ('B1', 21, 0),
  ('B1', 22, 0),
  ('B1', 23, 0),
  ('B1', 24, 0),
  ('B1', 25, 0),
  ('B1', 26, 0)
on conflict (collection_name, day_number) do update set word_count = excluded.word_count;

create or replace function record_class_homework_progress(
  p_homework_id uuid,
  p_mode text,
  p_client_word_count integer default null
)
returns table(recorded boolean, xp_awarded integer)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_uid uuid := auth.uid();
  v_hw record;
  v_is_member boolean;
  v_word_count integer := 0;
  v_xp integer := 0;
  v_xp_per_word integer;
  v_row_count integer;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select id, class_id, unit_id, class_unit_id, collection_name, day_number,
         passage_id, modes, student_ids
    into v_hw
    from class_homework
   where id = p_homework_id;

  if not found then
    raise exception 'homework not found';
  end if;

  if v_hw.student_ids is not null and not (v_uid = any(v_hw.student_ids)) then
    raise exception 'not assigned this homework';
  end if;

  select exists(
    select 1 from class_members
     where class_id = v_hw.class_id and student_id = v_uid
  ) into v_is_member;
  if not v_is_member then
    raise exception 'not a member of this class';
  end if;

  if not (
    p_mode = any(coalesce(v_hw.modes, array[]::text[]))
    or (p_mode = 'read' and v_hw.passage_id is not null)
  ) then
    raise exception 'invalid mode for this homework';
  end if;

  insert into class_homework_progress (homework_id, student_id, mode)
  values (p_homework_id, v_uid, p_mode)
  on conflict (homework_id, student_id, mode) do nothing;
  get diagnostics v_row_count = row_count;

  if v_row_count = 0 then
    -- already recorded — idempotent no-op, no double XP
    return query select false, 0;
    return;
  end if;

  if v_hw.passage_id is not null then
    v_xp := 15;
  else
    if v_hw.class_unit_id is not null then
      select count(*) into v_word_count from class_words where unit_id = v_hw.class_unit_id;
    elsif v_hw.unit_id is not null then
      select count(*) into v_word_count from teacher_unit_words where unit_id = v_hw.unit_id;
    else
      -- collection_name + day_number: word count now verified server-side
      -- via collection_day_word_counts instead of trusting the client.
      -- Falls back to the old clamped client value only if this specific
      -- (collection, day) pair isn't in the table for some reason.
      select word_count into v_word_count
        from collection_day_word_counts
       where collection_name = v_hw.collection_name and day_number = v_hw.day_number;
      if not found then
        v_word_count := least(greatest(coalesce(p_client_word_count, 0), 0), 50);
      end if;
    end if;

    v_xp_per_word := case p_mode
      when 'learn' then 10
      when 'flashcard' then 3
      when 'quiz' then 5
      when 'match' then 4
      else 3
    end;
    v_xp := v_word_count * v_xp_per_word;
  end if;

  if v_xp > 0 then
    update class_members
       set class_xp = coalesce(class_xp, 0) + v_xp
     where class_id = v_hw.class_id and student_id = v_uid;

    insert into class_xp_history (user_id, class_id, amount, reason)
    values (v_uid, v_hw.class_id, v_xp, p_mode);

    insert into class_study_days (student_id, class_id, study_date)
    values (v_uid, v_hw.class_id, current_date)
    on conflict (student_id, class_id, study_date) do nothing;
  end if;

  return query select true, v_xp;
end;
$function$;

grant execute on function record_class_homework_progress(uuid, text, integer) to authenticated;
grant select on collection_day_word_counts to authenticated;
