-- Smart insights: English class sentences that put {count} before a plural
-- noun read "1 students need attention" when only one student matches.
-- Reworded so the number stands on its own. Uzbek ("1 nafar o'quvchi") has
-- no such problem and is unchanged.

update public.insight_templates as t set text_en = v.text_en
from (values
  ('class-summary-1',  'Students needing attention today: {count}.'),
  ('class-summary-2',  'Needing attention today: {count} of {total_students}.'),
  ('class-summary-3',  'Worth reaching out to today: {count}.'),
  ('class-summary-4',  'Falling behind or missing tasks: {count}.'),
  ('class-summary-5',  'Could use a short reminder today: {count}.'),
  ('class-summary-6',  'Today''s list — needing attention: {count}.'),
  ('class-behind-3',   'Below 40% of tasks done ({count}): {names}.'),
  ('class-behind-6',   'Could be sent a reminder ({count}): {names}.'),
  ('class-well-3',     'Above 60% ({count}): {names}.'),
  ('class-hard-4',     'Marked Hard by 3+ students ({count}): {words}.'),
  ('class-skipper-3',  'Regularly missing tasks ({count}): {names}.'),
  ('class-skipper-6',  'Worth a talk about consistency ({count}): {names}.')
) as v(code, text_en)
where t.code = v.code;
