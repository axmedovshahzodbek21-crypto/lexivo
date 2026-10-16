-- Smart insights: wording fixes found while previewing the templates.
-- 20261017000002 already carries the new wording for fresh databases; this
-- updates the rows already inserted on production.
--
-- - L5-steady-3 / L4-steady-5 promised "one or two tasks" to the next level,
--   which is wrong whenever more than 10 tasks were due.
-- - skipper-2 put {date} in brackets, so "(Kecha)" ended up nested.

update public.insight_templates set
  text_uz = '{name}: {score}% vazifa o''z vaqtida. Eng yuqori darajaga oz qoldi.',
  text_en = '{name}: {score}% of tasks on time. Not far from the top level.'
where code = 'L5-steady-3';

update public.insight_templates set
  text_uz = '{name} bu hafta {total} tadan {done} ta vazifani o''z vaqtida topshirdi. Yana bir nechta vazifa bajarilsa, natija yaxshi darajaga chiqadi.',
  text_en = '{name} handed in {done} of {total} tasks on time this week. A few more would bring them to a good level.'
where code = 'L4-steady-5';

update public.insight_templates set
  text_uz = '{name} bu hafta {days_skipped} kun vazifa yoki takrorlashni bajarmadi, oxirgi marta {date}. Kundalik qisqa odat taklif qilish mumkin.',
  text_en = '{name} skipped tasks or reviews on {days_skipped} days this week, most recently {date}. Suggesting a short daily habit may help.'
where code = 'skipper-2';
