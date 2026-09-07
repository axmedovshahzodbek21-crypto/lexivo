# Lexivo

English vocabulary learning app for Uzbek speakers. Flutter/Dart, Supabase backend.
Solo-maintained.

## Environment

- Dev machine is Windows, shell is PowerShell. Don't hand me bash-only commands
  (`rm -rf`, `export VAR=`, `$(...)` substitution).
- Never edit anything in `.dart_tool/`, `build/`, or `.flutter-plugins-dependencies`.
  Those are generated. If something looks wrong in there, the fix is upstream.
- Don't suggest `flutter clean` as a first move. It throws away the build cache and
  costs several minutes on this machine. Try the targeted fix first.

## Dependencies

- **Don't add a package to `pubspec.yaml` without asking me.** Every dependency is APK
  size, a possible Android build break, and one more thing to keep updated.
- Before writing a helper, check whether it already exists in `lib/`.
- Don't guess at a package's API. Check the version pinned in `pubspec.yaml` first —
  the API you remember may be from a different major version.

## Supabase

- **The anon key ships inside the APK.** Anyone can extract it from a released build.
  RLS is not defence in depth here — it is the only security boundary. Treat it that way.
- Every table has RLS enabled. **A new table needs its policies written in the same
  change.** A table without policies is a bug, not a TODO.
- The service role key never appears in Dart code, anywhere, for any reason.
- Don't guess at column names or table shapes. Ask me to paste the schema, or read the
  SQL in the supabase folder. Wrong guesses cost me a full rebuild cycle to discover.

## SRS rules (business logic — do not "improve" these)

These intervals are deliberate. Changing them silently breaks every learner's schedule.

- Review intervals: **+1, +5, +7, +14, +30 days**.
- A missed day propagates forward — it does not reset the card to zero.
- **3 consecutive missed reviews → the word is unlearned** and re-enters the queue.
- "Vaziyat cards" (situation-based comprehension cards) unlock at the **4th successful
  review**. That is the mastery gate; don't move it.

If a change touches scheduling, walk me through one card across all five intervals
before and after, in plain text, before you write any code.

## Content conventions

- UI copy is Uzbek. English appears as the learning material, not as interface text.
- Reading content targets B1–B2 and embeds all 15 target vocabulary words per story.
- Vocabulary lists are split A1 / A2 / B1. Words must be deduplicated **across** levels,
  not just within one — a B1 list repeating an A2 word is a content bug.
- Brand identity is purple. Primary domain is lexivo.uz.

## Known traps

<!-- Add to this section every time something breaks. Fastest way: start a message in
     Claude Code with # and the line gets saved here automatically. -->

- (empty — fill as you hit them)

## TODO: fill these in yourself

<!-- I don't know these. Replace each line, then delete this comment. -->

- Build/release command for Android, and where the output goes.
- Whether web is a real target (there's a .vercel folder) or a leftover.
- Which platform folders are actually used — ios, macos, linux and windows all exist.
  If they're unused, say so here so Claude stops offering to fix them.

## How I want you to work

- Smallest change that solves the problem. No abstraction for cases we don't have yet.
- If you're unsure which of two approaches I want, ask before writing 200 lines.
- When you finish a change, tell me in one line what I need to test on the device.
