import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

// Auto homework (teacher): "X units a day" for one collection or library
// folder. The nightly job (lexivo-web migration 20261108000001) does the
// assigning; this file only edits the class_auto_homework row.

const _s = <String, Map<String, String>>{
  'title':        {'en': 'Auto homework', 'uz': 'Avtomatik uy vazifasi', 'ru': 'Автодомашка'},
  'sub':          {'en': 'Units are assigned to the whole class every chosen day.', 'uz': 'Tanlangan kunlarda butun sinfga unitlar avtomatik beriladi.', 'ru': 'Юниты назначаются всему классу в выбранные дни.'},
  'per_day':      {'en': 'UNITS PER DAY', 'uz': 'KUNIGA NECHTA UNIT', 'ru': 'ЮНИТОВ В ДЕНЬ'},
  'days':         {'en': 'DAYS', 'uz': 'KUNLAR', 'ru': 'ДНИ'},
  'deadline':     {'en': 'DEADLINE', 'uz': 'MUDDAT', 'ru': 'СРОК'},
  'no_deadline':  {'en': 'None', 'uz': 'Yo\'q', 'ru': 'Нет'},
  'n_days':       {'en': '{n} d', 'uz': '{n} kun', 'ru': '{n} дн'},
  'order':        {'en': 'ORDER', 'uz': 'TARTIB', 'ru': 'ПОРЯДОК'},
  'in_order':     {'en': 'In order', 'uz': 'Ketma-ket', 'ru': 'По порядку'},
  'random':       {'en': 'Random', 'uz': 'Tasodifiy', 'ru': 'Случайно'},
  'random_n':     {'en': '{n} random unit(s)', 'uz': '{n} ta tasodifiy unit', 'ru': 'Случайных юнитов: {n}'},
  'start':        {'en': 'START', 'uz': 'BOSHLASH', 'ru': 'НАЧАЛО'},
  'today':        {'en': 'Today', 'uz': 'Bugundan', 'ru': 'Сегодня'},
  'tomorrow':     {'en': 'Tomorrow', 'uz': 'Ertadan', 'ru': 'Завтра'},
  'plan':         {'en': 'PLAN', 'uz': 'REJA', 'ru': 'ПЛАН'},
  'last_unit':    {'en': 'Last unit: {d}', 'uz': 'Oxirgi unit: {d}', 'ru': 'Последний юнит: {d}'},
  'nothing_left': {'en': 'Every unit is already assigned.', 'uz': 'Hamma unitlar allaqachon berilgan.', 'ru': 'Все юниты уже назначены.'},
  'hold_note':    {'en': 'In classes of more than 5 students, if fewer than half finished the previous units, that day is skipped.', 'uz': '5 tadan ko\'p o\'quvchili sinflarda, agar yarmidan kami oldingi unitlarni tugatgan bo\'lsa, o\'sha kun yangi unit berilmaydi.', 'ru': 'В классах больше 5 учеников: если меньше половины закончили прошлые юниты, день пропускается.'},
  'save':         {'en': 'Save', 'uz': 'Saqlash', 'ru': 'Сохранить'},
  'pause':        {'en': 'Pause', 'uz': 'Pauza', 'ru': 'Пауза'},
  'resume':       {'en': 'Resume', 'uz': 'Davom ettirish', 'ru': 'Продолжить'},
  'turn_off':     {'en': 'Turn off', 'uz': 'O\'chirish', 'ru': 'Выключить'},
  'turn_off_q':   {'en': 'Turn off auto homework? Already assigned units stay.', 'uz': 'Avtomatik uy vazifasi o\'chirilsinmi? Berilgan unitlar qoladi.', 'ru': 'Выключить? Назначенные юниты останутся.'},
  'failed':       {'en': 'Could not save', 'uz': 'Saqlab bo\'lmadi', 'ru': 'Не удалось сохранить'},
  'st_paused':    {'en': 'Paused', 'uz': 'Pauzada', 'ru': 'На паузе'},
  'st_starts':    {'en': 'Starts {d}', 'uz': '{d} dan boshlanadi', 'ru': 'Начнётся {d}'},
  'st_released':  {'en': '{n} unit(s) assigned', 'uz': '{n} ta unit berildi', 'ru': 'Назначено юнитов: {n}'},
  'st_held':      {'en': 'held — under half the class finished', 'uz': 'to\'xtatildi — sinfning yarmidan kami tugatgan', 'ru': 'пауза — закончили меньше половины'},
  'st_done':      {'en': 'All units assigned', 'uz': 'Hamma unitlar berildi', 'ru': 'Все юниты назначены'},
  'st_today':     {'en': 'Today', 'uz': 'Bugun', 'ru': 'Сегодня'},
  'per_day_short':{'en': '{n}/day', 'uz': 'kuniga {n} ta', 'ru': '{n} в день'},
};

String _t(String key) {
  final lang = appLangNotifier.value;
  return _s[key]?[lang] ?? _s[key]!['en']!;
}

const _weekdayShort = <String, List<String>>{
  'en': ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
  'uz': ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
  'ru': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
};

/// Tashkent "today" (UTC+5, no DST) — the job's day boundary.
DateTime tashkentToday() {
  final t = DateTime.now().toUtc().add(const Duration(hours: 5));
  return DateTime.utc(t.year, t.month, t.day);
}

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);
String _short(DateTime d) => '${d.day}.${d.month.toString().padLeft(2, '0')}';

class AutoSchedule {
  final String id;
  final String? collectionName, folderId;
  final int unitsPerDay;
  final List<int> weekdays;
  final List<String> modes;
  final int? dueDays;
  final bool paused, randomOrder;
  final String startDate;
  final String? lastRunOn, lastStatus;
  final int lastCount;

  AutoSchedule.fromRow(Map<String, dynamic> m)
      : id = m['id'] as String,
        collectionName = m['collection_name'] as String?,
        folderId = m['folder_id'] as String?,
        unitsPerDay = (m['units_per_day'] as num).toInt(),
        weekdays = ((m['weekdays'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
        modes = ((m['modes'] as List?) ?? const []).map((e) => e as String).toList(),
        dueDays = (m['due_days'] as num?)?.toInt(),
        paused = m['paused'] as bool? ?? false,
        randomOrder = m['random_order'] as bool? ?? false,
        startDate = m['start_date'] as String,
        lastRunOn = m['last_run_on'] as String?,
        lastStatus = m['last_status'] as String?,
        lastCount = (m['last_count'] as num?)?.toInt() ?? 0;

  static const selectCols =
      'id, collection_name, folder_id, units_per_day, weekdays, modes, due_days, random_order, paused, start_date, last_run_on, last_status, last_count';

  /// One line for the teacher's card, e.g. "⚡ kuniga 2 ta · Bugun: 2 ta unit berildi".
  String statusLine() {
    final head = '⚡ ${_t('per_day_short').replaceFirst('{n}', '$unitsPerDay')}';
    if (paused) return '$head · ${_t('st_paused')}';
    final today = _iso(tashkentToday());
    if (lastRunOn == null) {
      return startDate.compareTo(today) > 0
          ? '$head · ${_t('st_starts').replaceFirst('{d}', _short(DateTime.parse(startDate)))}'
          : head;
    }
    if (lastStatus == 'done') return '$head · ${_t('st_done')}';
    final when = lastRunOn == today ? _t('st_today') : _short(DateTime.parse(lastRunOn!));
    final what = switch (lastStatus) {
      'released' => _t('st_released').replaceFirst('{n}', '$lastCount'),
      'held' => _t('st_held'),
      _ => '',
    };
    return '$head · $when: $what';
  }
}

Future<List<AutoSchedule>> loadAutoSchedules(String classId) async {
  final rows = await supabase.from('class_auto_homework').select(AutoSchedule.selectCols).eq('class_id', classId);
  return (rows as List).map((e) => AutoSchedule.fromRow(Map<String, dynamic>.from(e as Map))).toList();
}

/// Opens the editor. Exactly one of [collectionName]+[dayNumbers] or
/// [folderId] is given. [remaining] = labels of the units not yet assigned to
/// the whole class, in release order (for the plan preview).
/// Returns true when something was saved/changed.
Future<bool> showAutoHomeworkSheet(
  BuildContext context, {
  required String classId,
  required String sourceTitle,
  String? collectionName,
  List<int>? dayNumbers,
  String? folderId,
  required List<String> remaining,
  AutoSchedule? existing,
}) async {
  final user = currentUser;
  if (user == null) return false;
  var perDay = existing?.unitsPerDay ?? 1;
  final weekdays = <int>{...(existing?.weekdays ?? const [1, 2, 3, 4, 5, 6])};
  var match = existing?.modes.contains('match') ?? false;
  int? dueDays = existing == null ? 1 : existing.dueDays;
  var randomOrder = existing?.randomOrder ?? false;
  var startToday = true;
  var busy = false;
  var changed = false;
  final lang = appLangNotifier.value;
  final wd = _weekdayShort[lang] ?? _weekdayShort['en']!;

  Widget label(BuildContext ctx, String key) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(_t(key), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted, letterSpacing: 0.8)),
      );

  Widget chip(BuildContext ctx, String text, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: on ? ctx.primary : ctx.surface2, borderRadius: BorderRadius.circular(10)),
          child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : ctx.textMuted)),
        ),
      );

  // Plan preview: walk the calendar from the first release day, ignoring
  // holds (they depend on how the class does).
  List<String> plan() {
    if (remaining.isEmpty || weekdays.isEmpty) return [];
    final lines = <String>[];
    var day = tashkentToday();
    if (existing == null && !startToday) day = day.add(const Duration(days: 1));
    if (existing != null) {
      final s = DateTime.parse(existing.startDate);
      final t = tashkentToday();
      day = s.isAfter(t) ? DateTime.utc(s.year, s.month, s.day) : t;
      if (existing.lastRunOn == _iso(t)) day = day.add(const Duration(days: 1));
    }
    var idx = 0;
    DateTime? last;
    var guard = 0;
    while (idx < remaining.length && guard++ < 2000) {
      if (weekdays.contains(day.weekday)) {
        final batch = remaining.sublist(idx, (idx + perDay).clamp(0, remaining.length));
        final what = randomOrder ? _t('random_n').replaceFirst('{n}', '${batch.length}') : batch.join(', ');
        if (lines.length < 6) lines.add('${wd[day.weekday - 1]} ${_short(day)}: $what');
        idx += batch.length;
        last = day;
      }
      day = day.add(const Duration(days: 1));
    }
    if (last != null) lines.add(_t('last_unit').replaceFirst('{d}', _short(last)));
    return lines;
  }

  Future<void> save(BuildContext ctx, StateSetter setSheet, Map<String, dynamic> patch) async {
    setSheet(() => busy = true);
    try {
      if (existing == null) {
        final row = await supabase.from('class_auto_homework').insert({
          'class_id': classId,
          'teacher_id': user.id,
          'collection_name': ?collectionName,
          'folder_id': ?folderId,
          if (!startToday) 'start_date': _iso(tashkentToday().add(const Duration(days: 1))),
          ...patch,
        }).select('id').single();
        if (startToday) await supabase.rpc('auto_homework_run_today', params: {'p_id': row['id']});
      } else {
        await supabase.from('class_auto_homework').update(patch).eq('id', existing.id);
      }
      changed = true;
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (e) {
      if (ctx.mounted) {
        setSheet(() => busy = false);
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${_t('failed')}: $e')));
      }
    }
  }

  Map<String, dynamic> settings() => {
        'units_per_day': perDay,
        'weekdays': (weekdays.toList()..sort()),
        'modes': ['learn', 'flashcard', 'quiz', if (match) 'match'],
        'due_days': dueDays,
        'random_order': randomOrder,
        if (collectionName != null) 'day_numbers': dayNumbers,
      };

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      final lines = plan();
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: ctx.surface2, borderRadius: BorderRadius.circular(2)))),
          Text('⚡ ${_t('title')}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ctx.appText)),
          const SizedBox(height: 4),
          Text(sourceTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ctx.appText)),
          const SizedBox(height: 2),
          Text(_t('sub'), style: TextStyle(fontSize: 12, color: ctx.textMuted)),
          if (existing != null) ...[
            const SizedBox(height: 8),
            Text(existing.statusLine(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.primary)),
          ],

          label(ctx, 'per_day'),
          Row(children: [
            IconButton(onPressed: perDay > 1 ? () => setSheet(() => perDay--) : null, icon: const Icon(Icons.remove_circle_outline)),
            Text('$perDay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ctx.appText)),
            IconButton(onPressed: perDay < 10 ? () => setSheet(() => perDay++) : null, icon: const Icon(Icons.add_circle_outline)),
          ]),

          label(ctx, 'order'),
          Row(children: [
            chip(ctx, _t('in_order'), !randomOrder, () => setSheet(() => randomOrder = false)),
            const SizedBox(width: 6),
            chip(ctx, '🎲 ${_t('random')}', randomOrder, () => setSheet(() => randomOrder = true)),
          ]),

          label(ctx, 'days'),
          Wrap(spacing: 6, runSpacing: 6, children: List.generate(7, (i) {
            final d = i + 1;
            return chip(ctx, wd[i], weekdays.contains(d), () => setSheet(() {
              if (weekdays.contains(d)) {
                if (weekdays.length > 1) weekdays.remove(d);
              } else {
                weekdays.add(d);
              }
            }));
          })),

          label(ctx, 'deadline'),
          Wrap(spacing: 6, runSpacing: 6, children: [null, 1, 2, 3, 7].map((n) => chip(ctx,
              n == null ? _t('no_deadline') : _t('n_days').replaceFirst('{n}', '$n'),
              dueDays == n, () => setSheet(() => dueDays = n))).toList()),

          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              chip(ctx, '📖 ${tr('mode_learn')}', true, () {}),
              chip(ctx, '🃏 ${tr('mode_flashcard')}', true, () {}),
              chip(ctx, '❓ ${tr('mode_quiz')}', true, () {}),
              chip(ctx, '🔗 ${tr('mode_match')}${tr('mode_optional_suffix')}', match, () => setSheet(() => match = !match)),
            ]),
          ),

          if (existing == null) ...[
            label(ctx, 'start'),
            Row(children: [
              chip(ctx, _t('today'), startToday, () => setSheet(() => startToday = true)),
              const SizedBox(width: 6),
              chip(ctx, _t('tomorrow'), !startToday, () => setSheet(() => startToday = false)),
            ]),
          ],

          label(ctx, 'plan'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ctx.surface2, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (lines.isEmpty)
                Text(_t('nothing_left'), style: TextStyle(fontSize: 12, color: ctx.textMuted))
              else
                ...lines.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(l, style: TextStyle(fontSize: 12, color: ctx.appText)),
                    )),
              const SizedBox(height: 6),
              Text(_t('hold_note'), style: TextStyle(fontSize: 11, color: ctx.textMuted)),
            ]),
          ),

          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: busy ? null : () => save(ctx, setSheet, settings()),
            style: ElevatedButton.styleFrom(backgroundColor: ctx.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_t('save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          )),
          if (existing != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: busy ? null : () => save(ctx, setSheet, {'paused': !existing.paused}),
                child: Text(existing.paused ? _t('resume') : _t('pause')),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: busy ? null : () async {
                  final ok = await showDialog<bool>(context: ctx, builder: (dctx) => AlertDialog(
                    content: Text(_t('turn_off_q')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(tr('cancel'))),
                      TextButton(onPressed: () => Navigator.pop(dctx, true), child: Text(_t('turn_off'))),
                    ],
                  ));
                  if (ok != true) return;
                  setSheet(() => busy = true);
                  try {
                    await supabase.from('class_auto_homework').delete().eq('id', existing.id);
                    changed = true;
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      setSheet(() => busy = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${_t('failed')}: $e')));
                    }
                  }
                },
                child: Text(_t('turn_off')),
              )),
            ]),
          ],
        ])),
      );
    }),
  );
  return changed;
}
