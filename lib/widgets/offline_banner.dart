import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../l10n.dart';

/// "1h ago"-style label from the shared time_* strings.
String timeAgoLabel(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return tr('time_just_now');
  if (diff.inMinutes < 60) return tr('time_minutes_ago').replaceFirst('{n}', '${diff.inMinutes}');
  if (diff.inHours < 24) return tr('time_hours_ago').replaceFirst('{n}', '${diff.inHours}');
  if (diff.inDays < 7) return tr('time_days_ago').replaceFirst('{n}', '${diff.inDays}');
  return tr('time_weeks_ago').replaceFirst('{n}', '${(diff.inDays / 7).floor()}');
}

/// Shown on top of a screen whose data came from the phone's saved copy
/// (OfflineReads) because there was no internet.
class OfflineBanner extends StatelessWidget {
  final DateTime savedAt;
  const OfflineBanner(this.savedAt, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
    child: Text(
      tr('offline_last_updated').replaceFirst('{t}', timeAgoLabel(savedAt)),
      style: TextStyle(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w600),
    ),
  );
}
