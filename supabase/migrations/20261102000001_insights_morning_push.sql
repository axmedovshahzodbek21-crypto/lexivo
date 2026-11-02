-- ─────────────────────────────────────────────────────────────────────────────
-- Smart insights: 8:00 morning push to teachers
-- Run in the Supabase SQL Editor — AFTER deploying the updated send-push
-- Edge Function (it needs the new 'insights_morning' kind), still with
-- --no-verify-jwt.
--
-- User's rule (2026-11-02): one push per class, only when someone needs
-- attention ("2-sinf: 3 o'quvchi e'tibor talab qiladi"). Silent when the
-- whole class is fine. "Needs attention" = the nightly snapshot's
-- attention_count (skipper, or level 1-3), built at 00:05 Tashkent by
-- run_daily_class_insights().
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.send_insights_morning_push()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  trigger_secret text;
  r record;
begin
  select decrypted_secret into trigger_secret
    from vault.decrypted_secrets where name = 'push_trigger_secret';

  for r in
    select cs.class_id, cs.attention_count
      from class_insight_class_snapshots cs
     where cs.snapshot_date = (now() at time zone 'Asia/Tashkent')::date
       and cs.attention_count > 0
  loop
    begin
      perform net.http_post(
        url := 'https://jzozrqbzhagezlwncktf.supabase.co/functions/v1/send-push',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || trigger_secret
        ),
        body := jsonb_build_object(
          'kind', 'insights_morning',
          'class_id', r.class_id,
          'count', r.attention_count
        )
      );
    exception when others then
      raise warning 'insights morning push failed for %: %', r.class_id, sqlerrm;
    end;
  end loop;
end;
$$;

revoke execute on function public.send_insights_morning_push() from public, anon, authenticated;

-- 03:00 UTC = 08:00 Asia/Tashkent (no DST). Re-running updates the schedule.
select cron.schedule(
  'class-insights-morning-push',
  '0 3 * * *',
  $$ select public.send_insights_morning_push(); $$
);
