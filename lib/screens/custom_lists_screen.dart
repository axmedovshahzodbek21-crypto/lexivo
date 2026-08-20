import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../l10n.dart';
import 'list_detail_screen.dart';

final _wordMap = buildWordMap();

class CustomListsScreen extends StatefulWidget {
  const CustomListsScreen({super.key});

  @override
  State<CustomListsScreen> createState() => _CustomListsScreenState();
}

class _CustomListsScreenState extends State<CustomListsScreen> {
  List<CustomList> _lists = [];
  bool _creating = false;
  final _nameController = TextEditingController();
  String? _deleteId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lists = await StorageService.getCustomLists();
    if (mounted) setState(() => _lists = lists);
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final id = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
        '${(DateTime.now().microsecondsSinceEpoch % 10000).toRadixString(36)}';
    final list = CustomList(
      id: id,
      name: name,
      createdAt: DateTime.now().toIso8601String(),
    );
    await StorageService.saveCustomList(list);
    if (!mounted) return;
    _nameController.clear();
    setState(() => _creating = false);
    await _load();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ListDetailScreen(listId: list.id)),
      ).then((_) => _load());
    }
  }

  Future<void> _delete(String id) async {
    await StorageService.deleteCustomList(id);
    if (!mounted) return;
    setState(() => _deleteId = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        foregroundColor: context.appText,
        elevation: 0,
        title: Text(tr('my_lists'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() { _creating = true; _nameController.clear(); }),
            icon: Icon(Icons.add, color: context.primary, size: 18),
            label: Text(tr('new_list'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _lists.isEmpty && !_creating
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_creating) _buildCreateCard(),
                ..._lists.map((list) => _deleteId == list.id
                    ? _buildDeleteConfirm(list)
                    : _buildListRow(list)),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              tr('no_lists_yet'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText),
            ),
            const SizedBox(height: 8),
            Text(
              tr('no_lists_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(() { _creating = true; _nameController.clear(); }),
              style: FilledButton.styleFrom(backgroundColor: context.primary),
              child: Text(tr('create_first_list')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.primary.withValues(alpha: 0.4)),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('new_list_name'), style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              hintText: 'e.g. IELTS Vocab, Hard Words…',
              hintStyle: TextStyle(color: context.textMuted),
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _create,
                  style: FilledButton.styleFrom(backgroundColor: context.primary),
                  child: Text(tr('create_and_open')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _creating = false),
                  style: OutlinedButton.styleFrom(foregroundColor: context.textMuted),
                  child: Text(tr('cancel')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(CustomList list) {
    final created = _formatDate(list.createdAt);
    final studyableCount = list.words.where((w) => _wordMap.containsKey(w.toLowerCase())).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
        boxShadow: context.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListDetailScreen(listId: list.id)),
        ).then((_) => _load()),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.primaryBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📋', style: TextStyle(fontSize: 22))),
        ),
        title: Text(list.name, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
        subtitle: Text(
          '$studyableCount ${studyableCount == 1 ? 'word' : 'words'} · $created',
          style: TextStyle(fontSize: 12, color: context.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.textMuted, size: 20),
              onPressed: () => setState(() => _deleteId = list.id),
            ),
            Icon(Icons.chevron_right, color: context.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirm(CustomList list) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dangerColor.withValues(alpha: 0.4)),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Delete "', style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
            TextSpan(text: list.name, style: TextStyle(color: context.dangerColor, fontWeight: FontWeight.bold)),
            TextSpan(text: '"?', style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
          ])),
          const SizedBox(height: 4),
          Text(
            'Removes the list and its ${list.words.length} word${list.words.length != 1 ? 's' : ''}. Words themselves are not affected.',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _delete(list.id),
                  style: FilledButton.styleFrom(backgroundColor: context.dangerColor),
                  child: const Text('Yes, delete'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _deleteId = null),
                  style: OutlinedButton.styleFrom(foregroundColor: context.textMuted),
                  child: Text(tr('cancel')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }
}
