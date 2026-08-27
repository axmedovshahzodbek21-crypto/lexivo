-- ─────────────────────────────────────────────────────────────────────────────
-- class_review_events: one row per graded review card (for pacing analytics)
-- Run in the Supabase SQL Editor
--
-- Captures reveal->grade response time per answer so we can measure whether
-- students are racing through cards and tune the client's anti-mash gate
-- constants (REVEAL_BEAT_MS / CARD_LOCKOUT_MS) with real data rather than a
-- guessed 800ms. Nothing reads it yet; it's groundwork for a future teacher
-- view. Written fire-and-forget by both review clients.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists public.class_review_events (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  class_id    uuid not null references classes(id)    on delete cascade,
  word        text not null,
  knew        boolean not null,
  response_ms int,                                  -- reveal -> grade; null if not measured
  created_at  timestamptz not null default now()
);

create index if not exists class_review_events_class_created_idx
  on public.class_review_events (class_id, created_at desc);

alter table public.class_review_events enable row level security;

-- A student inserts only their own events.
drop policy if exists class_review_events_insert_own on public.class_review_events;
create policy class_review_events_insert_own
  on public.class_review_events for insert to authenticated
  with check (user_id = auth.uid());

-- A student reads their own; the class teacher reads the whole class.
drop policy if exists class_review_events_select_own on public.class_review_events;
create policy class_review_events_select_own
  on public.class_review_events for select to authenticated
  using (
    user_id = auth.uid()
    or exists (select 1 from classes c where c.id = class_id and c.teacher_id = auth.uid())
  );

grant insert, select on public.class_review_events to authenticated;
