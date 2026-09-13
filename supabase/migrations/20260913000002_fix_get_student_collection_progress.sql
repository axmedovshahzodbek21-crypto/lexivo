-- get_student_collection_progress queried a standalone `unit_progress` table
-- that no longer exists — it was migrated to the `unit_progress` JSONB
-- column on `user_data` at some point, but this RPC was never updated to
-- match. Every call has been throwing "relation unit_progress does not
-- exist" since that migration, so the teacher dashboard's per-collection
-- drill-down (class_dashboard_screen.dart:2255) has been hard-broken.
--
-- Fix: read from user_data.unit_progress the same way get_class_dashboard's
-- collection_progress calculation already does — keys are
-- "{collection_name}_{day_number}", values are
-- {learnDone, flashcardDone, quizDone, matchDone, completedAt?}.

create or replace function public.get_student_collection_progress(p_class_id uuid, p_student_id uuid, p_collection_name text)
 returns table(day_number integer, learn_done boolean, flashcard_done boolean, quiz_done boolean, completed_at timestamp with time zone)
 language plpgsql
 security definer
as $function$
begin
  if not exists (
    select 1 from classes where id = p_class_id and teacher_id = auth.uid()
  ) then
    raise exception 'Not authorized';
  end if;

  return query
  select
    substring(kv.key from '_([0-9]+)$')::integer as day_number,
    coalesce((kv.value->>'learnDone')::boolean, false),
    coalesce((kv.value->>'flashcardDone')::boolean, false),
    coalesce((kv.value->>'quizDone')::boolean, false),
    (kv.value->>'completedAt')::timestamptz
  from user_data ud
  cross join lateral jsonb_each(coalesce(ud.unit_progress, '{}'::jsonb)) as kv(key, value)
  where ud.id = p_student_id
    and regexp_replace(kv.key, '_[0-9]+$', '') = p_collection_name
  order by day_number;
end;
$function$;
