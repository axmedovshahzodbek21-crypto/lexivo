import '../data/student_summary_sentences.dart';
import '../date_utils.dart';
import 'missed_homework.dart';

// Picks the cases that fit one student and turns them into sentences from
// data/student_summary_sentences.dart (generated from the web's
// lib/student-summary-sentences.ts). Each sentence is a list of segments; a
// segment with evidence is a tappable phrase that shows the facts behind it.
// Pure — callers load the data. Keep in sync with
// lexivo-web/lib/student-summary.ts.

class SentNote {
  final DateTime createdAt;
  final DateTime? readAt;
  const SentNote(this.createdAt, this.readAt);
}

class HistoryEntry {
  final String reason;
  final int amount;
  final DateTime createdAt;
  const HistoryEntry(this.reason, this.amount, this.createdAt);
}

// E early, L on the last day, K late but done, N past due and not done,
// null = not due yet and not done (not judged).
class HwEvidence {
  final String homeworkId, title, dueDate;
  final List<String> modes, missingModes;
  final String? finishedDate, status;
  final int days; // E: days early, K: days late
  const HwEvidence({required this.homeworkId, required this.title, required this.modes, required this.dueDate,
    required this.finishedDate, required this.missingModes, required this.status, required this.days});
}

class NoteEvidence {
  final DateTime sentAt;
  final DateTime? readAt, practisedAt;
  const NoteEvidence(this.sentAt, this.readAt, this.practisedAt);
}

class DayEvidence {
  final String date;
  final int xp;
  final List<String> reasons;
  const DayEvidence(this.date, this.xp, this.reasons);
}

class ReviewEvidence {
  final String date;
  int words;
  DateTime from;
  final DateTime to;
  ReviewEvidence(this.date, this.words, this.from, this.to);
}

class WeekEvidence {
  final String from, to; // yyyy-mm-dd; [0] = this week
  final int xp, activeDays;
  const WeekEvidence(this.from, this.to, this.xp, this.activeDays);
}

class SessionEvidence {
  final String date;
  DateTime from;
  final DateTime to;
  SessionEvidence(this.date, this.from, this.to);
}

/// One class_review_events row.
class ReviewAnswer {
  final String word;
  final bool knew;
  final DateTime createdAt;
  const ReviewAnswer(this.word, this.knew, this.createdAt);
}

class AccuracyEvidence {
  final String from, to;
  final int right, total;
  const AccuracyEvidence(this.from, this.to, this.right, this.total);
}

class WordEvidence {
  final String word;
  final int right, wrong;
  const WordEvidence(this.word, this.right, this.wrong);
}

/// kind: homework | timing | reminders | days | review | weeks | sessions |
/// accuracy | words; items are the matching *Evidence objects.
class Evidence {
  final String kind;
  final List<Object> items;
  const Evidence(this.kind, this.items);
}

class Segment {
  final String text;
  final Evidence? evidence;
  const Segment(this.text, [this.evidence]);
}

class _Pick {
  final String code;
  final Map<String, Object> vars;
  final Map<String, List<Object>> ev;
  const _Pick(this.code, [this.vars = const {}, this.ev = const {}]);
}

String _localDate(DateTime d) => formatStreakDate(d.toLocal());
int _dayDiff(String from, String to) => (DateTime.parse(to).difference(DateTime.parse(from)).inHours / 24).round();
String _addDays(String ymd, int n) => formatStreakDate(DateTime.parse(ymd).add(Duration(days: n)));
String _fmtShort(String ymd) => '${ymd.substring(8, 10)}.${ymd.substring(5, 7)}';
String _fmtLong(String ymd) => ymd.split('-').reversed.join('.');

String _fill(String s, Map<String, Object> vars) =>
    s.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => vars[m[1]]?.toString() ?? m[0]!);

String _names(List<HwEvidence> items, Map<String, String> w) => _joinList(items.map((i) => i.title).toList(), w);

String _joinList(List<String> list, Map<String, String> w) {
  final t = <String>[];
  for (final i in list) {
    if (!t.contains(i)) t.add(i);
  }
  if (t.length == 1) return t[0];
  if (t.length == 2) return '${t[0]} ${w['and']} ${t[1]}';
  return _fill(w['andMore']!, {'a': t[0], 'b': t[1], 'n': t.length - 2});
}

String _modeList(List<String> modes, Map<String, String> w) => modes.map((m) => w[m] ?? m).join(', ');

List<String> _activeDates(List<HistoryEntry> history) {
  final d = history.map((e) => _localDate(e.createdAt)).toSet().toList()..sort();
  return d.reversed.toList(); // newest first
}

// ── Homework ─────────────────────────────────────────────────────────────────

HwEvidence _hwEvidence(HomeworkRecord r, String today) {
  final f = r.finishedDate;
  final String? status = f != null
      ? (f.compareTo(r.dueDate) < 0 ? 'E' : f == r.dueDate ? 'L' : 'K')
      : (r.dueDate.compareTo(today) < 0 ? 'N' : null);
  final days = status == 'E' ? _dayDiff(f!, r.dueDate) : status == 'K' ? _dayDiff(r.dueDate, f!) : 0;
  return HwEvidence(homeworkId: r.homeworkId, title: r.title, modes: r.modes, dueDate: r.dueDate,
      finishedDate: f, missingModes: r.missingModes, status: status, days: days);
}

// Returns the picks plus the ids they named, so "what they did" doesn't repeat them.
({List<_Pick> picks, Set<String> named}) _homeworkPicks(List<HomeworkRecord> records, String today, Map<String, String> w) {
  final judged = records.map((r) => (r: r, e: _hwEvidence(r, today))).where((x) => x.e.status != null).toList()
    ..sort((a, b) => b.e.dueDate.compareTo(a.e.dueDate));
  final top = judged.take(10).toList();
  final all = top.map((x) => x.e).toList();
  final total = all.length;
  if (total == 0) return (picks: <_Pick>[], named: <String>{});
  List<HwEvidence> by(String s) => all.where((e) => e.status == s).toList();
  final e = by('E'), l = by('L'), k = by('K'), n = by('N');
  final done = total - n.length;

  if (total < 3) {
    _Pick p;
    if (n.isNotEmpty && n.length < total) {
      p = _Pick('hw_few_mixed', {'hw': _names(all, w)}, {'homework': all, 'timing': n});
    } else if (n.isNotEmpty) {
      p = total == 1
          ? _Pick('hw_few_open', {'hw': n[0].title, 'left': _modeList(n[0].missingModes, w)}, {'homework': n, 'timing': n})
          : _Pick('hw_few_open_many', {'hw': _names(n, w)}, {'homework': n, 'timing': n});
    } else if (k.isNotEmpty) {
      final late = k.length != 1 ? w['aLittleLate']! : k[0].days == 1 ? w['daysLate1']! : _fill(w['daysLate']!, {'n': k[0].days});
      p = _Pick('hw_few_late', {'hw': _names(k, w), 'late': late}, {'homework': k, 'timing': k});
    } else if (total == 1 && e.length == 1) {
      p = _Pick('hw_few_early', {'hw': e[0].title, 'early': e[0].days == 1 ? w['daysEarly1']! : _fill(w['daysEarly']!, {'n': e[0].days})}, {'homework': e, 'timing': e});
    } else {
      p = _Pick('hw_few_on_time', {'hw': _names(all, w)}, {'homework': all, 'timing': all});
    }
    return (picks: [p], named: all.map((x) => x.homeworkId).toSet());
  }

  Map<String, List<Object>> ev(List<HwEvidence> timing) => {'homework': all, 'timing': timing};
  _Pick main;
  if (n.length == total) {
    main = _Pick('hw_none_done', {'total': total}, ev(n));
  } else if (n.length / total >= 0.4) {
    main = _Pick('hw_many_missing', {'total': total, 'done': done, 'missed': n.length}, ev(n));
  } else if (n.isNotEmpty) {
    main = _Pick('hw_some_missing', {'total': total, 'done': done, 'missed': n.length}, ev(n));
  } else if (k.isNotEmpty) {
    final share = k.length / total;
    main = _Pick('hw_late_finishes', {'freq': w[share < 0.25 ? 'rarely' : share < 0.6 ? 'sometimes' : 'often']!}, ev(k));
  } else if (top.where((x) => x.r.finishedDate == x.r.assignedDate).length / total >= 0.5) {
    main = _Pick('hw_same_day', const {}, ev(all));
  } else if (e.length / total >= 0.6) {
    main = _Pick('hw_early', const {}, ev(all));
  } else if (l.length / total >= 0.6) {
    main = _Pick('hw_last_day', const {}, ev(all));
  } else {
    main = _Pick('hw_on_time', {'total': total}, ev(all));
  }

  // Trend: last 3 vs the 3 before, scored E3 L2 K1 N0.
  final picks = [main];
  if (total >= 6 && main.code != 'hw_none_done') {
    const points = {'E': 3, 'L': 2, 'K': 1, 'N': 0};
    double score(Iterable<HwEvidence> es) => es.fold<int>(0, (t, x) => t + points[x.status]!) / es.length;
    final diff = score(all.take(3)) - score(all.skip(3).take(3));
    final recent = all.take(6).toList();
    if (diff >= 1) {
      picks.add(_Pick('hw_improving', const {}, {'timing': recent}));
    } else if (diff <= -1) {
      picks.add(_Pick('hw_slipping', const {}, {'timing': recent}));
    }
  }
  return (picks: picks, named: <String>{});
}

// ── Activity: days, review sessions ─────────────────────────────────────────

List<DayEvidence> _dayItems(List<HistoryEntry> history, List<String> dates) => dates.map((date) {
  final es = history.where((e) => _localDate(e.createdAt) == date).toList();
  final reasons = <String>[];
  for (final e in es) {
    if (!reasons.contains(e.reason)) reasons.add(e.reason);
  }
  return DayEvidence(date, es.fold(0, (s, e) => s + e.amount), reasons);
}).toList();

// Review rows less than 30 min apart are one session. Newest first.
List<ReviewEvidence> _reviewSessions(List<HistoryEntry> history) {
  final rows = history.where((e) => e.reason == 'SRS Review').toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final out = <ReviewEvidence>[];
  for (final e in rows) {
    final s = out.isEmpty ? null : out.last;
    if (s != null && s.from.difference(e.createdAt).inMinutes < 30) {
      s.words++;
      s.from = e.createdAt;
    } else {
      out.add(ReviewEvidence(_localDate(e.createdAt), 1, e.createdAt, e.createdAt));
    }
  }
  return out;
}

_Pick? _contextPick(List<HistoryEntry> history, String today, String? joinDate, Map<String, String> w) {
  final active = _activeDates(history);
  if (joinDate != null) {
    final inClass = _dayDiff(joinDate, today);
    if (inClass <= 0) {
      return active.contains(today)
          ? _Pick('ctx_joined_today_active', const {}, {'days': _dayItems(history, [today])})
          : const _Pick('ctx_joined_today');
    }
    if (inClass < 7) {
      final span = inClass + 1;
      final since = active.where((d) => d.compareTo(joinDate) >= 0).toList();
      final vars = <String, Object>{'since': inClass == 1 ? w['sinceYesterday']! : _fill(w['sinceDays']!, {'n': inClass})};
      final ev = <String, List<Object>>{'days': _dayItems(history, since)};
      if (since.isEmpty) return _Pick('ctx_new_inactive', vars);
      if (since.length >= span) return _Pick('ctx_new_all_active', vars, ev);
      return _Pick('ctx_new_some_active', {...vars, 'active': since.length, 'days': span}, ev);
    }
  }
  if (active.isEmpty) return const _Pick('ctx_never');
  final week = active.where((d) => d.compareTo(_addDays(today, -7)) > 0).toList();
  final ev = <String, List<Object>>{'days': _dayItems(history, week)};
  if (week.length >= 6) return _Pick('ctx_week_high', {'active': week.length}, ev);
  if (week.length >= 3) return _Pick('ctx_week_mid', {'active': week.length}, ev);
  if (week.isNotEmpty) return _Pick('ctx_week_low', {'active': week.length, 'dayWord': week.length == 1 ? w['day1']! : w['dayN']!}, ev);
  return _Pick('ctx_week_none', {'last': _fmtLong(active.first)}, {'days': _dayItems(history, [active.first])});
}

// What they did on their latest active day (within the last 7 days).
({List<_Pick> picks, bool cleared}) _activityPicks(List<HistoryEntry> history, List<HomeworkRecord> records, Set<String> named,
    String today, int dueCount, Map<String, String> w) {
  final days = _activeDates(history);
  if (days.isEmpty || days.first.compareTo(_addDays(today, -7)) <= 0) return (picks: <_Pick>[], cleared: false);
  final last = days.first;
  final when = last == today ? w['today']! : last == _addDays(today, -1) ? w['yesterday']! : _fill(w['onDate']!, {'d': _fmtShort(last)});
  final sessions = _reviewSessions(history).where((s) => s.date == last).toList();
  final words = sessions.fold<int>(0, (s, x) => s + x.words);
  final finished = records.where((r) => r.finishedDate == last && !named.contains(r.homeworkId)).map((r) => _hwEvidence(r, today)).toList();
  final partial = records.where((r) => r.finishedDate == null && !named.contains(r.homeworkId) && r.doneModes.values.contains(last))
      .map((r) => _hwEvidence(r, today)).toList();
  final cleared = last == today && words > 0 && dueCount == 0;

  final picks = <_Pick>[];
  if (cleared) {
    picks.add(_Pick('act_review_cleared', {'when': when, 'n': words}, {'review': sessions}));
    if (finished.isNotEmpty) picks.add(_Pick('act_hw', {'when': when, 'hw': _names(finished, w)}, {'homework': finished}));
  } else if (words > 0 && finished.isNotEmpty) {
    picks.add(_Pick('act_review_hw', {'when': when, 'n': words, 'hw': _names(finished, w)}, {'review': sessions, 'homework': finished}));
  } else if (words > 0) {
    picks.add(_Pick('act_review', {'when': when, 'n': words}, {'review': sessions}));
  } else if (finished.isNotEmpty) {
    picks.add(_Pick('act_hw', {'when': when, 'hw': _names(finished, w)}, {'homework': finished}));
  } else if (partial.isNotEmpty) {
    final p = partial.first;
    picks.add(_Pick('act_hw_partial', {'when': when, 'hw': p.title, 'left': _modeList(p.missingModes, w)}, {'homework': [p], 'timing': [p]}));
  } else {
    picks.add(_Pick('act_other', {'when': when}, {'days': _dayItems(history, [last])}));
  }
  return (picks: picks, cleared: cleared);
}

_Pick? _reviewPick(List<HistoryEntry> history, String today, int dueCount, int overdueCount) {
  if (dueCount == 0) return null;
  final sessions = _reviewSessions(history);
  if (sessions.isEmpty) return _Pick('rev_never', {'n': dueCount});
  final since = _dayDiff(sessions.first.date, today);
  if (since >= 3) return _Pick('rev_stopped', {'days': since, 'n': dueCount}, {'review': sessions.take(5).toList()});
  if (overdueCount > 0) return _Pick('rev_overdue', {'n': dueCount, 'm': overdueCount});
  return _Pick('rev_waiting', {'n': dueCount});
}

// ── This week vs their own usual ────────────────────────────────────────────
// Weeks are rolling 7-day windows ending today; "usual" = average XP of the
// 3 weeks before this one. Only weeks that start on/after the join day (or
// the first activity) count, so a new student isn't compared with empty weeks.
List<WeekEvidence> _weekItems(List<HistoryEntry> history, String today, String? joinDate) {
  final dates = history.map((e) => _localDate(e.createdAt)).toList()..sort();
  final earliest = joinDate ?? (dates.isEmpty ? null : dates.first);
  if (earliest == null) return [];
  final out = <WeekEvidence>[];
  for (var k = 0; k < 26; k++) {
    final from = _addDays(today, -6 - 7 * k), to = _addDays(today, -7 * k);
    if (k > 0 && from.compareTo(earliest) < 0) break;
    final es = history.where((e) {
      final d = _localDate(e.createdAt);
      return d.compareTo(from) >= 0 && d.compareTo(to) <= 0;
    }).toList();
    out.add(WeekEvidence(from, to, es.fold(0, (s, e) => s + e.amount), es.map((e) => _localDate(e.createdAt)).toSet().length));
  }
  return out;
}

_Pick? _trendPick(List<HistoryEntry> history, String today, String? joinDate) {
  final weeks = _weekItems(history, today, joinDate);
  if (weeks.length < 3 || weeks.first.xp == 0) return null;
  final cur = weeks.first, prev = weeks.sublist(1);
  final ev = <String, List<Object>>{'weeks': weeks.take(4).toList()};
  if (prev.first.xp == 0 && prev.skip(1).any((w) => w.xp > 0)) return _Pick('trd_back', const {}, ev);
  final base = prev.take(3).toList();
  final usual = base.fold<int>(0, (s, w) => s + w.xp) / base.length;
  if (usual == 0) return null;
  final ratio = cur.xp / usual;
  if (prev.length >= 3 && ratio >= 1.3 && prev.every((w) => cur.xp > w.xp)) return _Pick('trd_record', const {}, ev);
  if (ratio >= 2) return _Pick('trd_up_strong', {'pct': ((ratio - 1) * 100).round()}, ev);
  if (ratio >= 1.3) return _Pick('trd_up', {'pct': ((ratio - 1) * 100).round()}, ev);
  if (ratio > 0.7) return _Pick('trd_steady', const {}, ev);
  if (ratio > 0.3) return _Pick('trd_down', {'pct': ((1 - ratio) * 100).round()}, ev);
  return _Pick('trd_down_strong', {'pct': ((1 - ratio) * 100).round()}, ev);
}

// ── Streaks ──────────────────────────────────────────────────────────────────
// Skipped in the first week — "every day since joining" already says it.
_Pick? _streakPick(List<HistoryEntry> history, String today, String? joinDate) {
  if (joinDate != null && _dayDiff(joinDate, today) < 7) return null;
  final set = history.map((e) => _localDate(e.createdAt)).toSet();
  final dates = set.toList()..sort();
  if (dates.isEmpty) return null;
  // Longest run (oldest → newest).
  var longest = <String>[], run = <String>[];
  for (final d in dates) {
    run = run.isNotEmpty && _addDays(run.last, 1) == d ? [...run, d] : [d];
    if (run.length > longest.length) longest = run;
  }
  // Current run ends today or yesterday.
  final current = <String>[];
  for (var d = set.contains(today) ? today : _addDays(today, -1); set.contains(d); d = _addDays(d, -1)) {
    current.add(d);
  }
  final n = current.length;
  if (n >= 5 && n == longest.length && dates.length > n) return _Pick('str_record', {'streak': n}, {'days': _dayItems(history, current)});
  if (n >= 7) return _Pick('str_long', {'streak': n}, {'days': _dayItems(history, current)});
  if (n >= 3) return _Pick('str_mid', {'streak': n}, {'days': _dayItems(history, current)});
  if (n == 0 && longest.length >= 5) {
    final since = _dayDiff(dates.last, today);
    if (since >= 2 && since <= 7) {
      return _Pick('str_broken', {'longest': longest.length, 'days': since}, {'days': _dayItems(history, longest.reversed.toList())});
    }
  }
  return null;
}

// ── Study habits (last 30 days) ─────────────────────────────────────────────
// Any class activity rows less than 30 min apart are one session. Newest first.
List<SessionEvidence> _sessionItems(List<HistoryEntry> history) {
  final rows = [...history]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final out = <SessionEvidence>[];
  for (final e in rows) {
    final s = out.isEmpty ? null : out.last;
    if (s != null && s.from.difference(e.createdAt).inMinutes < 30) {
      s.from = e.createdAt;
    } else {
      out.add(SessionEvidence(_localDate(e.createdAt), e.createdAt, e.createdAt));
    }
  }
  return out;
}

String _period(int h) => h >= 5 && h < 12 ? 'morning' : h >= 12 && h < 17 ? 'afternoon' : h >= 17 && h < 22 ? 'evening' : 'night';

// One habit sentence at most: a fixed hour, else a time of day, else
// weekends, else several sessions a day, else "varied".
_Pick? _habitPick(List<HistoryEntry> history, String today) {
  final sessions = _sessionItems(history).where((s) => s.date.compareTo(_addDays(today, -30)) > 0).toList();
  if (sessions.length < 8) return null;
  int hourOf(SessionEvidence s) => s.from.toLocal().hour;
  final hours = sessions.map(hourOf).toList();
  // Busiest ±1h window; ties go to the hour that itself has the most starts.
  var bestH = 0, best = 0, bestExact = 0;
  for (var h = 0; h < 24; h++) {
    final c = hours.where((x) => x == h || x == (h + 1) % 24 || x == (h + 23) % 24).length;
    final exact = hours.where((x) => x == h).length;
    if (c > best || (c == best && exact > bestExact)) {
      best = c;
      bestH = h;
      bestExact = exact;
    }
  }
  Map<String, List<Object>> ev(bool Function(SessionEvidence) keep) => {'sessions': sessions.where(keep).take(10).toList()};
  if (best / sessions.length >= 0.6) {
    bool near(SessionEvidence s) {
      final d = (hourOf(s) - bestH).abs();
      return (d < 24 - d ? d : 24 - d) <= 1;
    }
    return _Pick('tim_same_hour', {'hour': '${bestH.toString().padLeft(2, '0')}:00'}, ev(near));
  }
  for (final p in const ['morning', 'afternoon', 'evening', 'night']) {
    if (hours.where((h) => _period(h) == p).length / sessions.length >= 0.6) {
      return _Pick('tim_$p', const {}, ev((s) => _period(hourOf(s)) == p));
    }
  }
  final days = <String>[];
  for (final s in sessions) {
    if (!days.contains(s.date)) days.add(s.date);
  }
  final weekend = days.where((d) => DateTime.parse(d).weekday >= 6).toList();
  if (days.length >= 6 && weekend.length / days.length >= 0.6) return _Pick('wk_weekend', const {}, {'days': _dayItems(history, weekend)});
  final perDay = sessions.length / days.length;
  if (days.length >= 5 && perDay >= 2) return _Pick('ses_multi', {'x': perDay.round()}, ev((_) => true));
  return _Pick('tim_varied', const {}, ev((_) => true));
}

// ── Review quality ───────────────────────────────────────────────────────────
// From class_review_events (one row per graded card). Accuracy needs 20+
// answers in the last 30 days; a trend needs 15+ in each of the last two
// fortnights and a 10-point move. Then the words: still hard (2+ misses in
// 30 days and the latest answer wrong or more misses than hits), else
// recovered (2+ misses in 60 days, last two answers right).
AccuracyEvidence _accuracyItem(List<ReviewAnswer> answers, String from, String to) {
  final a = answers.where((x) {
    final d = _localDate(x.createdAt);
    return d.compareTo(from) >= 0 && d.compareTo(to) <= 0;
  }).toList();
  return AccuracyEvidence(from, to, a.where((x) => x.knew).length, a.length);
}

int _pctOf(AccuracyEvidence a) => (a.right / a.total * 100).round();

List<_Pick> _reviewQualityPicks(List<ReviewAnswer> answers, String today, Map<String, String> w) {
  final picks = <_Pick>[];
  final acc30 = _accuracyItem(answers, _addDays(today, -29), today);
  if (acc30.total >= 20) {
    final recent = _accuracyItem(answers, _addDays(today, -13), today);
    final prior = _accuracyItem(answers, _addDays(today, -27), _addDays(today, -14));
    final diff = recent.total >= 15 && prior.total >= 15 ? _pctOf(recent) - _pctOf(prior) : 0;
    if (diff >= 10) {
      picks.add(_Pick('rq_improving', {'from': _pctOf(prior), 'to': _pctOf(recent)}, {'accuracy': [prior, recent]}));
    } else if (diff <= -10) {
      picks.add(_Pick('rq_dropping', {'from': _pctOf(prior), 'to': _pctOf(recent)}, {'accuracy': [prior, recent]}));
    } else {
      final pct = _pctOf(acc30);
      final code = pct >= 90 ? 'rq_strong' : pct >= 75 ? 'rq_good' : pct >= 55 ? 'rq_mixed' : 'rq_hard';
      picks.add(_Pick(code, {'pct': pct, 'total': acc30.total}, {'accuracy': [acc30]}));
    }
  }
  final byWord = <String, List<ReviewAnswer>>{}; // oldest first, last 60 days
  final sorted = [...answers]..sort((x, y) => x.createdAt.compareTo(y.createdAt));
  for (final a in sorted) {
    if (_localDate(a.createdAt).compareTo(_addDays(today, -60)) <= 0) continue;
    (byWord[a.word] ??= []).add(a);
  }
  WordEvidence stat(String word, Iterable<ReviewAnswer> list) =>
      WordEvidence(word, list.where((a) => a.knew).length, list.where((a) => !a.knew).length);
  final from30 = _addDays(today, -29);
  final hard = <WordEvidence>[], recovered = <WordEvidence>[];
  byWord.forEach((word, list) {
    final r = stat(word, list.where((a) => _localDate(a.createdAt).compareTo(from30) >= 0));
    if (r.wrong >= 2 && (!list.last.knew || r.wrong > r.right)) {
      hard.add(r);
    } else if (stat(word, list).wrong >= 2 && list.length >= 2 && list.sublist(list.length - 2).every((a) => a.knew)) {
      recovered.add(stat(word, list));
    }
  });
  hard.sort((a, b) => b.wrong.compareTo(a.wrong));
  recovered.sort((a, b) => b.wrong.compareTo(a.wrong));
  if (hard.isNotEmpty) {
    picks.add(_Pick('rq_hard_words', {'words': _joinList(hard.take(3).map((x) => x.word).toList(), w)}, {'words': hard.take(5).toList()}));
  } else if (recovered.isNotEmpty) {
    picks.add(_Pick('rq_recovered', {'words': _joinList(recovered.take(3).map((x) => x.word).toList(), w)}, {'words': recovered.take(5).toList()}));
  }
  return picks;
}

// ── Milestones: one sentence at most ────────────────────────────────────────
// A run of on-time homework (only when the homework sentence isn't already
// an "always on time" one), else mastered words (SRS stage 5 — every
// interval done), else total review answers.
const _onTimeCodes = ['hw_on_time', 'hw_early', 'hw_last_day', 'hw_same_day', 'hw_few_on_time', 'hw_few_early'];

_Pick? _milestonePick(List<HomeworkRecord> records, List<String> hwCodes, String today, int mastered, int learned, int reviews) {
  final judged = records.map((r) => _hwEvidence(r, today)).where((e) => e.status != null).toList()
    ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  final run = <HwEvidence>[];
  for (final e in judged) {
    if (e.status != 'E' && e.status != 'L') break;
    run.add(e);
  }
  if (run.length >= 5 && !hwCodes.any(_onTimeCodes.contains)) return _Pick('mst_hw_streak', {'n': run.length}, {'timing': run});
  if (mastered > 100) return _Pick('mst_mastered_big', {'n': mastered, 'learned': learned});
  if (mastered >= 25) return _Pick('mst_mastered_mid', {'n': mastered, 'learned': learned});
  if (mastered >= 5) return _Pick('mst_mastered_small', {'n': mastered, 'learned': learned});
  if (mastered >= 1) return _Pick('mst_mastered_first', {'n': mastered});
  for (final m in const [2000, 1000, 500, 250, 100]) {
    if (reviews > m) return _Pick('mst_reviews_total', {'n': m});
  }
  return null;
}

// ── Reminders ────────────────────────────────────────────────────────────────
// A teacher message counts only if the student hadn't studied in the 24h
// before it (otherwise they'd have practised anyway). R studied within 24h,
// S within 72h, O read but no practice, U not opened. Under 72h with no
// practice yet = not judged.
_Pick? _reminderPick(List<SentNote> notes, List<HistoryEntry> history, DateTime now, String today, String? joinDate) {
  final activity = history.map((e) => e.createdAt).toList();
  final judged = <String>[];
  final items = <NoteEvidence>[];
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
      items.add(NoteEvidence(sent, note.readAt, after));
    } else if (now.difference(sent).inHours < 72) {
      continue;
    } else {
      judged.add(note.readAt != null ? 'O' : 'U');
      items.add(NoteEvidence(sent, note.readAt, null));
    }
  }
  final ev = <String, List<Object>>{'reminders': items};

  if (judged.isEmpty) {
    final week = _activeDates(history).where((d) => d.compareTo(_addDays(today, -7)) > 0).toList();
    final inClass = joinDate != null ? _dayDiff(joinDate, today) : 0;
    return week.length >= 5 && inClass >= 7 ? _Pick('rem_not_needed', const {}, {'days': _dayItems(history, week)}) : null;
  }
  if (judged.length == 1) {
    final s = judged.first;
    if (s == 'R' || s == 'S') return _Pick('rem_single_responded', {'hours': lastHours}, ev);
    return _Pick(s == 'O' ? 'rem_single_read' : 'rem_single_unread', const {}, ev);
  }
  double share(List<String> ss) => judged.where(ss.contains).length / judged.length;
  if (share(['R']) >= 0.6) return _Pick('rem_quick', const {}, ev);
  if (share(['R', 'S']) >= 0.6) return _Pick('rem_slow', const {}, ev);
  if (share(['O']) >= 0.5) return _Pick('rem_read_no_action', const {}, ev);
  if (share(['U']) >= 0.5) return _Pick('rem_unread', const {}, ev);
  if (share(['R', 'S']) >= 0.3) return _Pick('rem_mixed', const {}, ev);
  return _Pick(share(['O']) >= share(['U']) ? 'rem_read_no_action' : 'rem_unread', const {}, ev);
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

// Splits [[label|key]] markup before filling placeholders, so a homework
// title containing "|" or "]]" can't break the parse.
// English verb endings after {name}: singular for "Student 1", plural for "they".
const _agreeOne = {'s': 's', 'es': 'es', 'has': 'has', 'hasnt': "hasn't", 'is': 'is', 'was': 'was', 'doesnt': "doesn't"};
const _agreeThey = {'s': '', 'es': '', 'has': 'have', 'hasnt': "haven't", 'is': 'are', 'was': 'were', 'doesnt': "don't"};

({List<Segment> sentence, bool usesName}) _render(_Pick p, String lang, String name, String seed, bool pronoun) {
  final versions = summarySentences[p.code]![lang]!;
  final text = versions[_variantIndex('$seed:${p.code}', versions.length)];
  final w = summaryWords[lang]!;
  final who = pronoun
      ? <String, Object>{'name': w['pronoun']!, 'nameObj': w['pronounObj']!, ..._agreeThey}
      : <String, Object>{'name': name, 'nameObj': name, ..._agreeOne};
  return (sentence: _renderText(text, p, who), usesName: RegExp(r'\{name(Obj)?\}').hasMatch(text));
}

List<Segment> _renderText(String text, _Pick p, Map<String, Object> who) {
  final vars = <String, Object>{...who, ...p.vars};
  final out = <Segment>[];
  var at = 0;
  for (final m in RegExp(r'\[\[(.+?)\|(\w+)\]\]').allMatches(text)) {
    if (m.start > at) out.add(Segment(_fill(text.substring(at, m.start), vars)));
    final items = p.ev[m[2]];
    out.add(items != null && items.isNotEmpty ? Segment(_fill(m[1]!, vars), Evidence(m[2]!, items)) : Segment(_fill(m[1]!, vars)));
    at = m.end;
  }
  if (at < text.length) out.add(Segment(_fill(text.substring(at), vars)));
  // Templates may open with a placeholder ("{since} qo'shilganidan beri…").
  if (out.isNotEmpty && out.first.text.isNotEmpty) {
    final f = out.first;
    out[0] = Segment(f.text[0].toUpperCase() + f.text.substring(1), f.evidence);
  }
  return out;
}

List<List<Segment>> buildStudentSummary({
  required String studentId,
  required String name,
  required String lang, // 'uz' or 'en'
  required String today,
  required DateTime now,
  required String? joinDate, // yyyy-mm-dd
  required List<HomeworkRecord> homework,
  required List<SentNote> notes,
  required List<HistoryEntry> history, // class XP history (any order)
  required int dueCount,               // words waiting for review now
  required int overdueCount,
  required List<ReviewAnswer> answers, // class_review_events
  required int mastered,               // class_srs_states at stage 5
  required int learned,                // class_srs_states rows
}) {
  final w = summaryWords[lang]!;
  final hw = _homeworkPicks(homework, today, w);
  final act = _activityPicks(history, homework, hw.named, today, dueCount, w);
  final streak = _streakPick(history, today, joinDate);
  final trend = _trendPick(history, today, joinDate);
  final picks = [
    _contextPick(history, today, joinDate, w),
    // "Steady" only adds something when no streak sentence is there.
    trend?.code == 'trd_steady' && streak != null ? null : trend,
    streak,
    ...act.picks,
    act.cleared ? null : _reviewPick(history, today, dueCount, overdueCount),
    ..._reviewQualityPicks(answers, today, w),
    ...hw.picks,
    _milestonePick(homework, hw.picks.map((p) => p.code).toList(), today, mastered, learned, answers.length),
    _habitPick(history, today),
    _reminderPick(notes, history, now, today, joinDate),
  ].whereType<_Pick>().toList();
  if (picks.isEmpty) picks.add(const _Pick('not_enough_data'));
  final seed = '$studentId:$today';
  // The paragraph names the student once; later sentences say "u" (Uzbek
  // has no gendered pronoun) or "they" / "them".
  var named = false;
  return picks.map((p) {
    final r = _render(p, lang, name, seed, named);
    named = named || r.usesName;
    return r.sentence;
  }).toList();
}
