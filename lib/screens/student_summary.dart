import '../data/student_summary_sentences.dart';
import 'missed_homework.dart';

// Picks the cases that fit one student and turns them into sentences from
// data/student_summary_sentences.dart (generated from the web's
// lib/student-summary-sentences.ts). Pure — callers load the data. Keep in
// sync with lexivo-web/lib/student-summary.ts.

class SentNote {
  final DateTime createdAt;
  final DateTime? readAt;
  const SentNote(this.createdAt, this.readAt);
}

class _Pick {
  final String code;
  final Map<String, Object> vars;
  const _Pick(this.code, [this.vars = const {}]);
}

// ── Homework timing ──────────────────────────────────────────────────────────
// Each assignment: E early, L last day, K late but done, N not done (past
// due). Not due yet and not done = not judged. Last 10 judged, newest first.
List<_Pick> _homeworkPicks(List<HomeworkRecord> records, String today) {
  final judged = <(HomeworkRecord, String)>[];
  for (final r in records) {
    final f = r.finishedDate;
    final s = f != null
        ? (f.compareTo(r.dueDate) < 0 ? 'E' : f == r.dueDate ? 'L' : 'K')
        : (r.dueDate.compareTo(today) < 0 ? 'N' : null);
    if (s != null) judged.add((r, s));
  }
  judged.sort((a, b) => b.$1.dueDate.compareTo(a.$1.dueDate));
  final recent = judged.take(10).toList();
  final total = recent.length;
  if (total == 0) return [];
  int count(String s) => recent.where((j) => j.$2 == s).length;
  final e = count('E'), l = count('L'), k = count('K'), n = count('N');
  final done = total - n;

  if (total < 3) {
    if (n > 0) return [_Pick('hw_few_open', {'missed': n})];
    return [_Pick(k > 0 ? 'hw_few_late' : 'hw_few_on_time')];
  }

  _Pick main;
  if (n == total) {
    main = _Pick('hw_none_done', {'total': total});
  } else if (n / total >= 0.4) {
    main = _Pick('hw_many_missing', {'total': total, 'done': done, 'missed': n});
  } else if (n > 0) {
    main = _Pick('hw_some_missing', {'total': total, 'done': done, 'missed': n});
  } else if (k > 0) {
    final share = k / total;
    main = _Pick('hw_late_finishes', {'freq': share < 0.25 ? 'rarely' : share < 0.6 ? 'sometimes' : 'often'});
  } else if (recent.where((j) => j.$1.finishedDate == j.$1.assignedDate).length / total >= 0.5) {
    main = const _Pick('hw_same_day');
  } else if (e / total >= 0.6) {
    main = const _Pick('hw_early');
  } else if (l / total >= 0.6) {
    main = const _Pick('hw_last_day');
  } else {
    main = _Pick('hw_on_time', {'total': total});
  }

  // Trend: last 3 vs the 3 before, scored E3 L2 K1 N0.
  final picks = [main];
  if (total >= 6 && main.code != 'hw_none_done') {
    const points = {'E': 3, 'L': 2, 'K': 1, 'N': 0};
    double score(Iterable<(HomeworkRecord, String)> rs) => rs.fold<int>(0, (t, j) => t + points[j.$2]!) / rs.length;
    final diff = score(recent.take(3)) - score(recent.skip(3).take(3));
    if (diff >= 1) {
      picks.add(const _Pick('hw_improving'));
    } else if (diff <= -1) {
      picks.add(const _Pick('hw_slipping'));
    }
  }
  return picks;
}

// ── Reaction to reminders ────────────────────────────────────────────────────
// A teacher message counts only if the student hadn't studied in the 24h
// before it (otherwise they'd have practised anyway). R studied within 24h,
// S within 72h, O read but no practice, U not opened. Under 72h with no
// practice yet = not judged.
_Pick? _reminderPick(List<SentNote> notes, List<DateTime> activity, DateTime now, int activeDays7, int? daysInClass) {
  final judged = <String>[];
  var lastHours = 0;
  final sorted = [...notes]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final note in sorted.take(10)) {
    final sent = note.createdAt;
    if (activity.any((t) => !t.isBefore(sent.subtract(const Duration(hours: 24))) && t.isBefore(sent))) continue;
    DateTime? after;
    for (final t in activity) {
      if (t.isAfter(sent) && (after == null || t.isBefore(after))) after = t;
    }
    final hours = after == null ? double.infinity : after.difference(sent).inMinutes / 60;
    if (hours <= 72) {
      judged.add(hours <= 24 ? 'R' : 'S');
      if (judged.length == 1) lastHours = hours.ceil() < 1 ? 1 : hours.ceil();
    } else if (now.difference(sent).inHours < 72) {
      continue;
    } else {
      judged.add(note.readAt != null ? 'O' : 'U');
    }
  }

  if (judged.isEmpty) {
    return activeDays7 >= 5 && (daysInClass ?? 0) >= 7 ? const _Pick('rem_not_needed') : null;
  }
  if (judged.length == 1) {
    final s = judged.first;
    if (s == 'R' || s == 'S') return _Pick('rem_single_responded', {'hours': lastHours});
    return _Pick(s == 'O' ? 'rem_single_read' : 'rem_single_unread');
  }
  double share(List<String> ss) => judged.where(ss.contains).length / judged.length;
  if (share(['R']) >= 0.6) return const _Pick('rem_quick');
  if (share(['R', 'S']) >= 0.6) return const _Pick('rem_slow');
  if (share(['O']) >= 0.5) return const _Pick('rem_read_no_action');
  if (share(['U']) >= 0.5) return const _Pick('rem_unread');
  if (share(['R', 'S']) >= 0.3) return const _Pick('rem_mixed');
  return _Pick(share(['O']) >= share(['U']) ? 'rem_read_no_action' : 'rem_unread');
}

// ── Rendering ────────────────────────────────────────────────────────────────

// Stable per student per day, different across days and cases. Same hash as
// the web, so both pick the same version.
int _variantIndex(String seed, int n) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c).toSigned(32);
  }
  return h.abs() % n;
}

String _render(_Pick p, String lang, String name, String seed) {
  final versions = summarySentences[p.code]![lang]!;
  final text = versions[_variantIndex('$seed:${p.code}', versions.length)];
  final vars = <String, Object>{'name': name, ...p.vars};
  final freq = vars['freq'];
  if (freq is String) vars['freq'] = summaryFreq[lang]![freq]!;
  return text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => vars[m[1]]?.toString() ?? m[0]!);
}

List<String> buildStudentSummary({
  required String studentId,
  required String name,
  required String lang, // 'uz' or 'en'
  required String today,
  required DateTime now,
  required List<HomeworkRecord> homework,
  required List<SentNote> notes,
  required List<DateTime> activity, // class activity timestamps
  required int activeDays7,         // days with class activity in the last 7
  required int? daysInClass,
}) {
  final picks = [
    ..._homeworkPicks(homework, today),
    _reminderPick(notes, activity, now, activeDays7, daysInClass),
  ].whereType<_Pick>().toList();
  if (picks.isEmpty) picks.add(const _Pick('not_enough_data'));
  final seed = '$studentId:$today';
  return picks.map((p) => _render(p, lang, name, seed)).toList();
}
