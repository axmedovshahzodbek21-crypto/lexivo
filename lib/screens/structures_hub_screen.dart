import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/structures_data.dart';
import '../data/structures_storage_service.dart';
import '../l10n.dart';
import 'structures_day_picker_screen.dart';
import 'structures_flashcards_screen.dart';
import 'structures_review_screen.dart';
import 'structures_detective_screen.dart';

const Map<String, String> _kUnitIcons = {
  'Speaking Part 1': '🗣️',
  'Speaking Part 2': '🎤',
  'Speaking Part 3': '💬',
  'Writing Task 2': '✍️',
};

/// Port of lexivo-web's /structures page: 4 unit tiles (Learn is scoped by
/// unit → day), plus cross-unit Flashcards/Review/Detective entry points,
/// plus a searchable reference list copied from grammar_tips_screen.dart's
/// structure (search + tag filter chips + expandable cards).
class StructuresHubScreen extends StatefulWidget {
  const StructuresHubScreen({super.key});

  @override
  State<StructuresHubScreen> createState() => _StructuresHubScreenState();
}

class _StructuresHubScreenState extends State<StructuresHubScreen> {
  static const _all = 'All';
  String _tag = _all;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _open = {};
  Set<String> _learnedIds = {};
  int _dueCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final srs = await StructuresStorageService.getStructuresSRS();
    final due = await StructuresStorageService.getDueStructures();
    if (!mounted) return;
    setState(() {
      _learnedIds = srs.map((s) => s.id).toSet();
      _dueCount = due.length;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StructureItem> get _visible {
    final q = _search.trim().toLowerCase();
    return kStructures.where((s) {
      final matchTag = _tag == _all || s.ieltsUse.contains(_tag);
      final matchSearch = q.isEmpty ||
          s.pattern.toLowerCase().contains(q) ||
          s.definition.toLowerCase().contains(q) ||
          s.uzTranslation.toLowerCase().contains(q) ||
          s.uzDefinition.toLowerCase().contains(q) ||
          s.scenario.toLowerCase().contains(q);
      return matchTag && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tags = [_all, ...{for (final s in kStructures) ...s.ieltsUse}];
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
          '🧩 ${tr('ielts_structures')}',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            '${_learnedIds.length} / ${kStructures.length} learned',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
          const SizedBox(height: 12),
          Text('Learn by unit',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: context.textMuted)),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: kStructureUnits.map((unit) {
              final inUnit = structuresInUnit(unit);
              final learned = inUnit.where((s) => _learnedIds.contains(s.id)).length;
              return _tile(
                icon: _kUnitIcons[unit] ?? '🧩',
                label: unit,
                sub: '$learned/${inUnit.length} learned',
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StructuresDayPickerScreen(unit: unit),
                  ));
                  _load();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Practice everything',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: context.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tile(
                  icon: '🃏',
                  label: tr('structures_flashcards'),
                  sub: null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const StructuresFlashcardsScreen(unit: null),
                  )).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  icon: '🕵️',
                  label: tr('structures_detective'),
                  sub: null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const StructuresDetectiveScreen(),
                  )).then((_) => _load()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  icon: '🔄',
                  label: tr('structures_review'),
                  sub: _dueCount > 0 ? '$_dueCount due' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const StructuresReviewScreen(),
                  )).then((_) => _load()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search structures…',
              hintStyle: TextStyle(color: context.textMuted),
              prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
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
              itemCount: tags.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = tags[i];
                final active = t == _tag;
                return GestureDetector(
                  onTap: () => setState(() => _tag = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? context.primary : context.surface2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : context.textMuted)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No structures match your search.',
                    style: TextStyle(color: context.textMuted)),
              ),
            )
          else
            for (final s in visible) ...[
              _structureCard(s),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _tile({required String icon, required String label, String? sub, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: context.appText)),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 10, color: context.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _structureCard(StructureItem s) {
    final open = _open.contains(s.id);
    final learned = _learnedIds.contains(s.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => open ? _open.remove(s.id) : _open.add(s.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (learned)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text('✓', style: TextStyle(color: context.successColor, fontSize: 12)),
                              ),
                            Flexible(
                              child: Text(s.pattern,
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                            ),
                          ],
                        ),
                        if (!open) ...[
                          const SizedBox(height: 4),
                          Text(s.definition,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  Text(open ? '▲' : '▼', style: TextStyle(fontSize: 12, color: context.textMuted)),
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
                  Text(s.definition, style: TextStyle(fontSize: 13, color: context.appText, height: 1.5)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💭 ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(s.scenario,
                              style: TextStyle(fontSize: 12, color: context.appText, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.uzTranslation,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
                        const SizedBox(height: 4),
                        Text(s.uzDefinition, style: TextStyle(fontSize: 12, color: context.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < s.examples.take(3).length; i++)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('"${s.examples[i]}"',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.appText)),
                          const SizedBox(height: 2),
                          Text('"${s.exampleTranslations[i]}"',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.textMuted)),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.ieltsUse
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.surface2,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t, style: TextStyle(fontSize: 10, color: context.textMuted)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
