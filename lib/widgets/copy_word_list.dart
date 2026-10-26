import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n.dart';
import '../app_theme.dart';

// "Copy word list" — just the headwords, numbered, no translations. Shared
// by every unit and folder screen (pre-built collections, My Words, Library).

String formatWordList(List<String> words) =>
    [for (var i = 0; i < words.length; i++) '${i + 1}. ${words[i]}'].join('\n');

// Folder copy: each unit under its own name, numbering restarting per unit.
String formatFolderWordList(List<(String, List<String>)> units) => units
    .where((u) => u.$2.isNotEmpty)
    .map((u) => '${u.$1}\n${formatWordList(u.$2)}')
    .join('\n\n');

void copyWordListText(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('copied')), duration: const Duration(seconds: 1)));
}

// AppBar icon for a single unit screen.
class CopyWordListButton extends StatelessWidget {
  final List<String> words;
  const CopyWordListButton({super.key, required this.words});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tr('copy_word_list'),
        icon: Icon(Icons.copy_rounded, color: context.textMuted, size: 21),
        onPressed: words.isEmpty ? null : () => copyWordListText(context, formatWordList(words)),
      );
}

// AppBar icon for a folder screen: opens a sheet to copy every unit at once
// (grouped by unit) or any single unit. [loadWords] returns each unit's
// words in the same order as [units]; it's only called on a tap, so folders
// whose words aren't already in memory (Library) fetch them lazily.
class CopyFolderWordListButton extends StatelessWidget {
  final List<({String name, int count})> units;
  final Future<List<List<String>>> Function() loadWords;
  const CopyFolderWordListButton({super.key, required this.units, required this.loadWords});

  Future<void> _copy(BuildContext context, int? unitIndex) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      final words = await loadWords();
      final text = unitIndex == null
          ? formatFolderWordList([for (var i = 0; i < units.length; i++) (units[i].name, words[i])])
          : formatWordList(words[unitIndex]);
      if (text.isEmpty) return;
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(SnackBar(content: Text(tr('copied')), duration: const Duration(seconds: 1)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(tr('check_connection'))));
    }
  }

  void _openSheet(BuildContext context) {
    final total = units.fold<int>(0, (s, u) => s + u.count);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: sheetCtx.surface2, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(tr('copy_word_list'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sheetCtx.appText)),
            ),
            ListTile(
              leading: Icon(Icons.copy_all_rounded, color: sheetCtx.primary),
              title: Text(tr('copy_all_units'),
                  style: TextStyle(color: sheetCtx.appText, fontWeight: FontWeight.bold)),
              trailing: Text(tr('n_words_plain').replaceFirst('{n}', '$total'),
                  style: TextStyle(color: sheetCtx.textMuted, fontSize: 12)),
              onTap: () => _copy(sheetCtx, null),
            ),
            Divider(height: 1, color: sheetCtx.border),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: units.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  leading: Icon(Icons.copy_rounded, color: sheetCtx.textMuted, size: 18),
                  title: Text(units[i].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sheetCtx.appText)),
                  trailing: Text(tr('n_words_plain').replaceFirst('{n}', '${units[i].count}'),
                      style: TextStyle(color: sheetCtx.textMuted, fontSize: 12)),
                  onTap: units[i].count == 0 ? null : () => _copy(sheetCtx, i),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tr('copy_word_list'),
        icon: Icon(Icons.copy_rounded, color: context.textMuted, size: 21),
        onPressed: units.every((u) => u.count == 0) ? null : () => _openSheet(context),
      );
}
