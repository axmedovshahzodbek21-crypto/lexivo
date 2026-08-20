-- ─────────────────────────────────────────────────────────────────────────────
-- Baseline schema for the homework/curriculum tables
-- Run this in Supabase SQL Editor
--
-- class_homework, class_homework_progress, class_words, class_word_units,
-- teacher_units, teacher_unit_words, and teacher_folders were created before
-- this repo's supabase/migrations/ history began — only later patches to
-- them exist in source control (20260818_class_homework_passage.sql,
-- 20260818_secure_class_homework_progress.sql, the RLS fix-ups, etc.), so
-- the actual base schema and RLS policies were unreviewable from the repo.
-- That's the same class of gap that let the RLS bugs those later migrations
-- had to fix go unnoticed in the first place.
--
-- Reconstructed from the live database (information_schema.columns,
-- pg_constraint, pg_policies, pg_indexes) on 2026-08-21. Every statement is
-- guarded (IF NOT EXISTS / DO+EXCEPTION) so this is safe to run against the
-- already-live database as a no-op, or against a fresh one to recreate the
-- schema from scratch.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists teacher_folders (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references auth.users(id),
  name text not null,
  position integer default 0,
  created_at timestamptz default now()
);

create table if not exists teacher_units (
  id uuid primary key default gen_random_uuid(),
  folder_id uuid not null references teacher_folders(id) on delete cascade,
  teacher_id uuid not null references auth.users(id),
  name text not null,
  position integer default 0,
  created_at timestamptz default now()
);

create table if not exists teacher_unit_words (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references teacher_units(id) on delete cascade,
  teacher_id uuid not null references auth.users(id),
  word text not null,
  translation text not null,
  definition text,
  examples jsonb default '[]'::jsonb,
  position integer default 0,
  created_at timestamptz default now(),
  part_of_speech text,
  pronunciation text,
  definition_uz text
);

create table if not exists class_word_units (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  teacher_id uuid not null references auth.users(id),
  name text not null,
  position integer default 0,
  created_at timestamptz default now()
);

create table if not exists class_words (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  teacher_id uuid not null references auth.users(id),
  word text not null,
  translation text not null,
  definition text,
  example1 text,
  example1_translation text,
  example2 text,
  example2_translation text,
  language text default 'en-US',
  created_at timestamptz not null default now(),
  folder_name text,
  collection_name text,
  examples jsonb default '[]'::jsonb,
  unit_id uuid references class_word_units(id) on delete set null
);

create table if not exists class_homework (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  unit_id uuid references teacher_units(id) on delete cascade,
  modes text[] not null default '{learn,flashcard,quiz}'::text[],
  due_date date,
  student_ids uuid[],
  assigned_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  class_unit_id uuid references class_word_units(id) on delete cascade,
  collection_name text,
  day_number integer,
  passage_id integer,
  constraint class_homework_student_ids_not_empty
    check (student_ids is null or array_length(student_ids, 1) > 0)
);

create table if not exists class_homework_progress (
  id uuid primary key default gen_random_uuid(),
  homework_id uuid not null references class_homework(id) on delete cascade,
  student_id uuid not null references auth.users(id),
  mode text not null,
  completed_at timestamptz not null default now(),
  unique (homework_id, student_id, mode)
);

alter table teacher_folders enable row level security;
alter table teacher_units enable row level security;
alter table teacher_unit_words enable row level security;
alter table class_word_units enable row level security;
alter table class_words enable row level security;
alter table class_homework enable row level security;
alter table class_homework_progress enable row level security;

do $$ begin
  create policy teacher_folders_own on teacher_folders for all
    using (auth.uid() = teacher_id);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_folders_read on teacher_folders for select
    using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_assigned_folders on teacher_folders for select
    using (exists (
      select 1 from class_library_assignments cla
      join class_members cm on cm.class_id = cla.class_id
      where cla.folder_id = teacher_folders.id and cm.student_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_units_own on teacher_units for all
    using (auth.uid() = teacher_id);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_units_read on teacher_units for select
    using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_assigned_units on teacher_units for select
    using (exists (
      select 1 from class_library_assignments cla
      join class_members cm on cm.class_id = cla.class_id
      where cla.folder_id = teacher_units.folder_id and cm.student_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_unit_words_own on teacher_unit_words for all
    using (auth.uid() = teacher_id);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_unit_words_read on teacher_unit_words for select
    using (true);
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_assigned_unit_words on teacher_unit_words for select
    using (exists (
      select 1 from teacher_units tu
      join class_library_assignments cla on cla.folder_id = tu.folder_id
      join class_members cm on cm.class_id = cla.class_id
      where tu.id = teacher_unit_words.unit_id and cm.student_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_manage_class_word_units on class_word_units for all
    using (teacher_id = auth.uid() and exists (
      select 1 from classes where classes.id = class_word_units.class_id and classes.teacher_id = auth.uid()
    ))
    with check (teacher_id = auth.uid() and exists (
      select 1 from classes where classes.id = class_word_units.class_id and classes.teacher_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_class_word_units on class_word_units for select
    using (exists (
      select 1 from class_members where class_members.class_id = class_word_units.class_id and class_members.student_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_manage_class_words on class_words for all
    using (teacher_id = auth.uid() and exists (
      select 1 from classes where classes.id = class_words.class_id and classes.teacher_id = auth.uid()
    ))
    with check (teacher_id = auth.uid() and exists (
      select 1 from classes where classes.id = class_words.class_id and classes.teacher_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_class_words on class_words for select
    using (class_id in (select class_members.class_id from class_members where class_members.student_id = auth.uid()));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_manage_homework on class_homework for all
    using (exists (
      select 1 from classes where classes.id = class_homework.class_id and classes.teacher_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_homework on class_homework for select
    using (exists (
      select 1 from class_members where class_members.class_id = class_homework.class_id and class_members.student_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_class_homework on class_homework for select
    using (exists (
      select 1 from class_members cm where cm.class_id = class_homework.class_id and cm.student_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy teacher_read_progress on class_homework_progress for select
    using (exists (
      select 1 from class_homework h join classes c on c.id = h.class_id
      where h.id = class_homework_progress.homework_id and c.teacher_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_read_own_progress on class_homework_progress for select
    using (student_id = auth.uid());
exception when duplicate_object then null; end $$;

do $$ begin
  create policy student_insert_own_progress on class_homework_progress for insert
    with check (student_id = auth.uid());
exception when duplicate_object then null; end $$;

-- This policy is currently unreachable for the `authenticated` role: the
-- table-level INSERT grant was revoked in
-- 20260818_secure_class_homework_progress.sql to close the direct-insert
-- exploit path, so only the SECURITY DEFINER record_class_homework_progress
-- RPC (which runs as its owner, bypassing this grant) can write rows.
-- Re-asserted here (a no-op if already revoked) so the live security
-- posture is visible from this file alone, not just from a later patch.
revoke insert on class_homework_progress from authenticated;
