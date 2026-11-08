-- ─────────────────────────────────────────────────────────────────────────────
-- Auto homework: tell the teacher when it stops by itself.
-- Run AFTER deploying the updated send-push Edge Function (new kinds
-- 'auto_held' and 'auto_done'), still with --no-verify-jwt.
--
-- One push at 08:01 when a schedule becomes held (under half the class
-- finished) or done (no units left). Only on the change: a class that stays
-- held for a week gets one push, not seven.
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.class_auto_homework
  add column if not exists teacher_push_pending boolean not null default false;

create or replace function public.auto_homework_flag_teacher_push()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.last_status in ('held', 'done') and new.last_status is distinct from old.last_status then
    new.teacher_push_pending := true;
  elsif new.last_status = 'released' then
    new.teacher_push_pending := false;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_auto_homework_teacher_push on public.class_auto_homework;
create trigger trg_auto_homework_teacher_push
  before update of last_status on public.class_auto_homework
  for each row execute function public.auto_homework_flag_teacher_push();

create or replace function public.auto_homework_teacher_push(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  s              class_auto_homework%rowtype;
  trigger_secret text;
begin
  update class_auto_homework set teacher_push_pending = false
   where id = p_id and teacher_push_pending
  returning * into s;
  if not found then return; end if;

  begin
    select decrypted_secret into trigger_secret
      from vault.decrypted_secrets where name = 'push_trigger_secret';
    perform net.http_post(
      url := 'https://jzozrqbzhagezlwncktf.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || trigger_secret
      ),
      body := jsonb_build_object(
        'kind', case when s.last_status = 'held' then 'auto_held' else 'auto_done' end,
        'class_id', s.class_id,
        'title', coalesce(s.collection_name,
                          (select name from teacher_folders where id = s.folder_id), '')
      )
    );
  exception when others then
    raise warning 'auto homework teacher push failed for %: %', p_id, sqlerrm;
  end;
end;
$$;

revoke execute on function public.auto_homework_teacher_push(uuid) from public, anon, authenticated;

create or replace function public.send_auto_homework_morning_push()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  for r in select id from class_auto_homework where push_pending loop
    perform auto_homework_push(r.id);
  end loop;
  for r in select id from class_auto_homework where teacher_push_pending loop
    perform auto_homework_teacher_push(r.id);
  end loop;
end;
$$;

revoke execute on function public.send_auto_homework_morning_push() from public, anon, authenticated;
