-- ─────────────────────────────────────────────────────────────────────────────
-- class_hard_word_archive: Hard words a teacher has taught ("archived")
-- Run in the Supabase SQL Editor
--
-- The teacher's Hard words page (/classes/[id]/hard-words) moves a word here
-- once it's been taught in class. From taught_at on, the page reads
-- class_review_events: a student no longer finds the word hard after 2
-- correct reviews in a row; a wrong answer puts it back on the to-teach list.
-- Archiving again moves taught_at to now. Students' own class_hard_words
-- rows are never touched.
--
-- Kept for as long as the class exists; deleting the class deletes its rows.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.class_hard_word_archive (
  id         uuid primary key default gen_random_uuid(),
  class_id   uuid not null references classes(id) on delete cascade,
  word       text not null,
  taught_at  timestamptz not null default now(),
  unique (class_id, word)
);

alter table public.class_hard_word_archive enable row level security;

-- Only the class's teacher reads or changes it; students have no access.
drop policy if exists class_hard_word_archive_teacher on public.class_hard_word_archive;
create policy class_hard_word_archive_teacher
  on public.class_hard_word_archive for all to authenticated
  using      (exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid()))
  with check (exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid()));

grant select, insert, update, delete on public.class_hard_word_archive to authenticated;
