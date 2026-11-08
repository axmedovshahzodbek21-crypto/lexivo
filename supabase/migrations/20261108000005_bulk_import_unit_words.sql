-- ─────────────────────────────────────────────────────────────────────────────
-- Library bulk import: paste a big word list into a folder and have it split
-- into units automatically. One call, all or nothing.
--
-- p_words: [{word, translation, definition?, part_of_speech?, pronunciation?,
--            definition_uz?, examples?}]
-- Runs as the caller (security invoker), so the existing teacher_units /
-- teacher_unit_words RLS still applies; the folder owner check is explicit
-- because those policies only look at teacher_id, not at the folder.
--
-- * Words already in this folder, and repeats inside the paste, are skipped.
-- * If the folder's last unit is an automatic "Unit N" that isn't full, it is
--   filled first, so importing in several rounds doesn't leave short units.
-- * A folder can hold 1000 units: list screens read at most 1000 rows.
-- ─────────────────────────────────────────────────────────────────────────────

-- These tables never had indexes on the columns every screen filters by; a
-- folder of 10,000 words makes each unit-list word count a full table scan.
create index if not exists teacher_unit_words_unit_id_idx on public.teacher_unit_words (unit_id);
create index if not exists teacher_units_folder_id_idx on public.teacher_units (folder_id);
create index if not exists class_homework_class_id_idx on public.class_homework (class_id);

create or replace function public.bulk_import_unit_words(
  p_folder_id uuid,
  p_words jsonb,
  p_unit_size int default 15
) returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_uid            uuid := auth.uid();
  v_existing_units int;
  v_last_id        uuid;
  v_last_name      text;
  v_fill           int := 0;
  v_added          int;
  v_new_units      int;
begin
  if v_uid is null or not exists (
    select 1 from teacher_folders where id = p_folder_id and teacher_id = v_uid
  ) then
    raise exception 'Not your folder' using errcode = '42501';
  end if;
  if p_unit_size is null or p_unit_size not between 5 and 100 then
    raise exception 'Unit size must be 5-100' using errcode = '22023';
  end if;
  if jsonb_typeof(p_words) is distinct from 'array' or jsonb_array_length(p_words) > 20000 then
    raise exception 'At most 20000 words per import' using errcode = '22023';
  end if;

  select count(*) into v_existing_units from teacher_units where folder_id = p_folder_id;

  select id, name into v_last_id, v_last_name
    from teacher_units where folder_id = p_folder_id
   order by position desc, created_at desc limit 1;

  if v_last_id is not null and v_last_name ~ '^Unit [0-9]+$' then
    select count(*) into v_fill from teacher_unit_words where unit_id = v_last_id;
    if v_fill >= p_unit_size then v_fill := 0; end if;
  end if;

  with input as (
    select t.e, t.ord from jsonb_array_elements(p_words) with ordinality as t(e, ord)
  ),
  clean as (
    select btrim(i.e->>'word') as w, btrim(i.e->>'translation') as tr, i.e, i.ord
      from input i
     where jsonb_typeof(i.e) = 'object'
       and btrim(coalesce(i.e->>'word', '')) <> ''
       and btrim(coalesce(i.e->>'translation', '')) <> ''
  ),
  -- Read once up front: as a correlated lookup this re-ran the table's RLS
  -- checks for every pasted word and timed out at 10,000 words.
  existing as materialized (
    select distinct lower(btrim(x.word)) as k
      from teacher_unit_words x
      join teacher_units u on u.id = x.unit_id
     where u.folder_id = p_folder_id
  ),
  fresh as (
    select distinct on (lower(c.w)) c.*
      from clean c
     where not exists (select 1 from existing z where z.k = lower(c.w))
     order by lower(c.w), c.ord
  ),
  numbered as materialized (
    select f.*, (row_number() over (order by f.ord) - 1 + v_fill)::int as idx from fresh f
  ),
  buckets as materialized (
    select d.b, case when d.b = 0 and v_fill > 0 then v_last_id else gen_random_uuid() end as target_id
      from (select distinct idx / p_unit_size as b from numbered) d
  ),
  ins_units as (
    insert into teacher_units (id, folder_id, teacher_id, name, created_at)
    select k.target_id, p_folder_id, v_uid,
           'Unit ' || (v_existing_units + k.b + case when v_fill > 0 then 0 else 1 end),
           now() + k.b * interval '1 millisecond'   -- list order is by created_at
      from buckets k
     where not (k.b = 0 and v_fill > 0)
    returning id
  ),
  ins_words as (
    insert into teacher_unit_words (unit_id, teacher_id, word, translation, definition,
                                    part_of_speech, pronunciation, definition_uz, examples, position)
    select k.target_id, v_uid, n.w, n.tr,
           nullif(btrim(n.e->>'definition'), ''),
           nullif(btrim(n.e->>'part_of_speech'), ''),
           nullif(btrim(n.e->>'pronunciation'), ''),
           nullif(btrim(n.e->>'definition_uz'), ''),
           case when jsonb_typeof(n.e->'examples') = 'array' then n.e->'examples' else '[]'::jsonb end,
           n.idx % p_unit_size
      from numbered n
      join buckets k on k.b = n.idx / p_unit_size
    returning 1
  )
  select (select count(*) from ins_words), (select count(*) from ins_units)
    into v_added, v_new_units;

  if v_existing_units + v_new_units > 1000 then
    raise exception 'A folder can hold at most 1000 units' using errcode = '22023';
  end if;

  return jsonb_build_object(
    'added', v_added,
    'skipped', jsonb_array_length(p_words) - v_added,
    'units', v_new_units
  );
end;
$$;

revoke execute on function public.bulk_import_unit_words(uuid, jsonb, int) from public, anon;
grant execute on function public.bulk_import_unit_words(uuid, jsonb, int) to authenticated;
