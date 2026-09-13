-- Closes a reconciliation gap: pushSettings() (Flutter's sync_service.dart,
-- web's lib/sync.ts) writes the same settings — including avatar_url — to
-- two independent tables via two separate upserts (Future.wait/Promise.all).
-- If one succeeds and the other fails (network blip, RLS hiccup, anything),
-- `user_data` (this account's own devices, via pullAll) and `profiles`
-- (what other users see — leaderboard, class roster, etc.) permanently
-- diverge. Nothing ever re-reconciles them: the next successful push just
-- upserts both again with whatever the device currently has, so a
-- transient one-sided failure is never retried or detected.
--
-- This RPC does both upserts in one transaction, so they can no longer
-- partially apply — either both tables get the new settings, or neither
-- does (client retries the whole push on any failure, same as today).
--
-- avatar_url and language_level: passing NULL preserves the existing
-- column value (COALESCE) for avatar_url, matching the client's current
-- "omit the key if not set locally" behavior for that field — this is what
-- stops a second device's first pushSettings() (before it has pulled the
-- cloud avatar into its own local prefs yet) from wiping out an avatar set
-- on another device. language_level has no such fallback client-side today
-- (a null local value already overwrites both tables with null), so it's
-- applied directly — not a behavior change, just moved server-side.
--
-- p_clear_avatar is the one case that *should* force avatar_url to NULL:
-- the user explicitly removing their photo. Without it, an intentional
-- removal (which also passes p_avatar_url = NULL) would look identical to
-- "no avatar set locally yet" and the COALESCE would silently keep the old
-- photo forever — see settings_screen.dart's remove-photo flow / web's
-- handleRemovePhoto, which both pass p_clear_avatar = true.
--
-- Run this in the Supabase SQL editor.

create or replace function sync_profile_settings(
  p_user_id uuid,
  p_daily_word_goal int,
  p_quiz_direction text,
  p_reduce_motion boolean,
  p_show_on_leaderboard boolean,
  p_notifications_enabled boolean,
  p_notif_time text,
  p_user_name text,
  p_language_level text,
  p_avatar_url text,
  p_settings_updated_at text,
  p_clear_avatar boolean default false
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into user_data (
    id, daily_word_goal, quiz_direction, reduce_motion, show_on_leaderboard,
    notifications_enabled, notif_time, user_name, language_level, avatar_url,
    settings_updated_at
  )
  values (
    p_user_id, p_daily_word_goal, p_quiz_direction, p_reduce_motion, p_show_on_leaderboard,
    p_notifications_enabled, p_notif_time, p_user_name, p_language_level, p_avatar_url,
    p_settings_updated_at
  )
  on conflict (id) do update set
    daily_word_goal        = excluded.daily_word_goal,
    quiz_direction          = excluded.quiz_direction,
    reduce_motion           = excluded.reduce_motion,
    show_on_leaderboard     = excluded.show_on_leaderboard,
    notifications_enabled   = excluded.notifications_enabled,
    notif_time              = excluded.notif_time,
    user_name               = excluded.user_name,
    language_level          = excluded.language_level,
    avatar_url              = case when p_clear_avatar then null
                                    else coalesce(excluded.avatar_url, user_data.avatar_url) end,
    settings_updated_at     = excluded.settings_updated_at;

  insert into profiles (id, name, show_on_leaderboard, language_level, avatar_url)
  values (p_user_id, p_user_name, p_show_on_leaderboard, p_language_level, p_avatar_url)
  on conflict (id) do update set
    name                 = excluded.name,
    show_on_leaderboard  = excluded.show_on_leaderboard,
    language_level       = excluded.language_level,
    avatar_url           = case when p_clear_avatar then null
                                 else coalesce(excluded.avatar_url, profiles.avatar_url) end;
end;
$$;

grant execute on function sync_profile_settings(
  uuid, int, text, boolean, boolean, boolean, text, text, text, text, text, boolean
) to authenticated;
