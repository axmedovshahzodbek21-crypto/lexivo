-- ─────────────────────────────────────────────────────────────────────────────
-- Fix: "seed one example folder" re-triggered after a teacher deleted all folders
-- Run this in Supabase SQL Editor
--
-- lib/screens/teacher_library_screen.dart's _seedExampleFolder gated seeding
-- purely on "does this teacher currently have zero folders", not a
-- persistent one-time flag. A teacher who deletes every folder they own
-- would, on their next visit to My Library, silently get "Vocabulary 101"
-- recreated — data reappearing right after a delete they explicitly
-- performed. Adds a persistent per-teacher flag on profiles instead.
-- ─────────────────────────────────────────────────────────────────────────────

alter table profiles add column if not exists has_seeded_library boolean not null default false;
