import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../date_utils.dart';
import '../l10n.dart' as l10n;
import 'class_curriculum_tab.dart';
import 'class_models.dart';
import 'missed_homework.dart';
import 'student_summary.dart';

const _strings = <String, Map<String, String>>{
  'open_homework': {'en': 'Open homework →', 'uz': 'Vazifani ochish →', 'ru': 'Открыть задание →'},
  'due': {'en': 'Due', 'uz': 'Muddat', 'ru': 'Срок'},
  'done': {'en': 'Done', 'uz': 'Bajarildi', 'ru': 'Выполнено'},
  'not_done': {'en': 'Not done yet', 'uz': 'Hali bajarilmagan', 'ru': 'Ещё не выполнено'},
  'in_progress': {'en': 'In progress', 'uz': 'Jarayonda', 'ru': 'В процессе'},
  'early': {'en': '{n} days early', 'uz': '{n} kun oldin', 'ru': 'на {n} дн. раньше'},
  'early1': {'en': '1 day early', 'uz': '1 kun oldin', 'ru': 'на 1 дн. раньше'},
  'on_last_day': {'en': 'on the last day', 'uz': 'oxirgi kuni', 'ru': 'в последний день'},
  'late_by': {'en': '{n} days late', 'uz': '{n} kun kech', 'ru': 'опоздание {n} дн.'},
  'late_by1': {'en': '1 day late', 'uz': '1 kun kech', 'ru': 'опоздание 1 дн.'},
  'left': {'en': '{m} left', 'uz': '{m} qolgan', 'ru': 'осталось: {m}'},
  'sent': {'en': 'Sent', 'uz': 'Yuborildi', 'ru': 'Отправлено'},
  'read': {'en': 'Read', 'uz': "O'qildi", 'ru': 'Прочитано'},
  'unread': {'en': 'Not opened', 'uz': 'Ochilmagan', 'ru': 'Не открыто'},
  'practised': {'en': 'Practised {h} h later', 'uz': '{h} soatdan keyin mashq qildi', 'ru': 'Занимался через {h} ч'},
  'not_practised': {'en': 'No practice after it', 'uz': 'Keyin mashq qilmagan', 'ru': 'После этого не занимался'},
};

String _s(String key) => _strings[key]?[l10n.appLangNotifier.value] ?? _strings[key]!['en']!;
String _fmtYmd(String ymd) => ymd.split('-').reversed.join('.');
String _fmtTime(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
String _fmtDateTime(DateTime t) => '${_fmtYmd(formatStreakDate(t.toLocal()))} ${_fmtTime(t)}';

/// The teacher's per-student summary (student_summary.dart). Phrases that
/// make a claim are tappable; tapping one shows the facts behind it under
/// that sentence. Mirrors lexivo-web components/StudentSummary.tsx.
class StudentSummaryView extends StatefulWidget {
  final List<List<Segment>> sentences;
  final String classId, className;
  final String Function(String reason) reasonLabel;
  const StudentSummaryView({super.key, required this.sentences, required this.classId, required this.className, required this.reasonLabel});

  @override
  State<StudentSummaryView> createState() => _StudentSummaryViewState();
}

class _StudentSummaryViewState extends State<StudentSummaryView> {
  ({int s, int g})? _open;

  @override
  Widget build(BuildContext context) {
    final accent = context.primary;
    final base = TextStyle(fontSize: 13, height: 1.45, color: context.appText);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var s = 0; s < widget.sentences.length; s++) ...[
        Text.rich(TextSpan(style: base, children: [
          for (var g = 0; g < widget.sentences[s].length; g++)
            if (widget.sentences[s][g].evidence == null)
              TextSpan(text: widget.sentences[s][g].text)
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => setState(() => _open = _open?.s == s && _open?.g == g ? null : (s: s, g: g)),
                  child: Text(widget.sentences[s][g].text, style: base.copyWith(
                    color: accent, fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted, decorationColor: accent,
                  )),
                ),
              ),
        ])),
        if (_open?.s == s && widget.sentences[s][_open!.g].evidence != null)
          _evidenceCard(context, widget.sentences[s][_open!.g].evidence!),
        const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _row(List<Widget> children) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _evidenceCard(BuildContext context, Evidence ev) {
    final muted = TextStyle(fontSize: 12, color: context.textMuted);
    final strong = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.appText);
    final plain = TextStyle(fontSize: 12, color: context.appText);
    final rows = <Widget>[];
    switch (ev.kind) {
      case 'homework':
        for (final h in ev.items.cast<HwEvidence>()) {
          rows.add(_row([
            Text('📘 ${h.title}', style: strong),
            Text(h.modes.map(homeworkModeLabel).join(' · '), style: muted),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                backgroundColor: context.bg,
                appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
                    title: Text(widget.className, style: TextStyle(color: context.appText, fontWeight: FontWeight.bold))),
                body: ClassCurriculumTab(classId: widget.classId, className: widget.className, openHomeworkId: h.homeworkId),
              ))),
              child: Text(_s('open_homework'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.primary)),
            ),
          ]));
        }
      case 'timing':
        for (final h in ev.items.cast<HwEvidence>()) {
          final status = h.status == 'E' ? (h.days == 1 ? _s('early1') : _s('early').replaceFirst('{n}', '${h.days}'))
              : h.status == 'L' ? _s('on_last_day')
              : h.status == 'K' ? (h.days == 1 ? _s('late_by1') : _s('late_by').replaceFirst('{n}', '${h.days}')) : null;
          rows.add(_row([
            Text(h.title, style: strong),
            Text('${_s('due')}: ${_fmtYmd(h.dueDate)}', style: muted),
            if (h.finishedDate != null)
              Text('${_s('done')}: ${_fmtYmd(h.finishedDate!)}${status != null ? ' · $status' : ''}',
                  style: plain.copyWith(color: h.status == 'K' ? const Color(0xFFD97706) : null))
            else
              Text('${h.status == 'N' ? _s('not_done') : _s('in_progress')} · ${_s('left').replaceFirst('{m}', h.missingModes.map(homeworkModeLabel).join(', '))}',
                  style: plain.copyWith(color: h.status == 'N' ? context.dangerColor : context.textMuted)),
          ]));
        }
      case 'reminders':
        for (final n in ev.items.cast<NoteEvidence>()) {
          rows.add(_row([
            Text('✉️ ${_s('sent')}: ${_fmtDateTime(n.sentAt)}', style: plain),
            Text(n.readAt != null ? '${_s('read')}: ${_fmtDateTime(n.readAt!)}' : _s('unread'), style: muted),
            Text(n.practisedAt != null
                ? _s('practised').replaceFirst('{h}', '${(n.practisedAt!.difference(n.sentAt).inMinutes / 60).ceil().clamp(1, 1 << 30)}')
                : _s('not_practised'), style: n.practisedAt != null ? plain : muted),
          ]));
        }
      case 'days':
        for (final d in ev.items.cast<DayEvidence>()) {
          rows.add(_row([
            Text('${_fmtYmd(d.date)} · +${xpDisplay(d.xp)} XP', style: strong),
            Text(d.reasons.map(widget.reasonLabel).join(' · '), style: muted),
          ]));
        }
      case 'review':
        for (final r in ev.items.cast<ReviewEvidence>()) {
          final from = _fmtTime(r.from), to = _fmtTime(r.to);
          rows.add(_row([
            Text('🔄 ${_fmtYmd(r.date)} · ${l10n.tr('words_count').replaceFirst('{n}', '${r.words}')} · ${from == to ? from : '$from – $to'}', style: plain),
          ]));
        }
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primary.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, color: context.border),
          rows[i],
        ],
      ]),
    );
  }
}
