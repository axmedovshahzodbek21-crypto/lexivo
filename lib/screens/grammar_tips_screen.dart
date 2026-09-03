import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/grammar_tips_data.dart';
import '../l10n.dart';

/// Port of lexivo-web's /grammar-tips page: a searchable, category-filtered
/// list of expandable grammar/vocabulary/writing tips. Reached from the home
/// drawer.
class GrammarTipsScreen extends StatefulWidget {
  const GrammarTipsScreen({super.key});

  @override
  State<GrammarTipsScreen> createState() => _GrammarTipsScreenState();
}

class _GrammarTipsScreenState extends State<GrammarTipsScreen> {
  static const _all = 'All';
  String _category = _all;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _open = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GrammarTip> get _visible {
    final q = _search.trim().toLowerCase();
    return grammarTips.where((t) {
      final matchCat = _category == _all || t.category == _category;
      final matchSearch = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.explanation.toLowerCase().contains(q) ||
          t.remember.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = [_all, ...grammarTipCategories];
    final visible = _visible;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '📚 ${tr('grammar_tips')}',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${grammarTips.length} tips · ${grammarTipCategories.length} categories',
                  style: TextStyle(fontSize: 12, color: context.textMuted),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search tips...',
                    hintStyle: TextStyle(color: context.textMuted),
                    prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: context.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: context.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                  ),
                  style: TextStyle(color: context.appText, fontSize: 14),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final active = cat == _category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? context.primary : context.surface2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : context.textMuted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 12),
                        Text('No tips match your search.',
                            style: TextStyle(color: context.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(context, visible[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, GrammarTip tip) {
    final open = _open.contains(tip.id);
    final color = tip.categoryColor;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(
                () => open ? _open.remove(tip.id) : _open.add(tip.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tip.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(tip.category,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(tip.title,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.appText)),
                            ),
                          ],
                        ),
                        if (!open) ...[
                          const SizedBox(height: 4),
                          Text(
                            tip.explanation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: context.textMuted, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(open ? '▲' : '▼',
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: context.border, height: 1),
                  const SizedBox(height: 12),
                  Text(tip.explanation,
                      style: TextStyle(
                          fontSize: 13, color: context.appText, height: 1.5)),
                  const SizedBox(height: 12),
                  for (final ex in tip.examples) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.en,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: context.appText)),
                          if (ex.note != null && ex.note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('— ${ex.note}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: context.textMuted)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: color, width: 3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tip.remember,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.appText,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
