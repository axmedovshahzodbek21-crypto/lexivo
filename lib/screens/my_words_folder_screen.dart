import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import 'import_screen.dart';
import 'import_collection_detail_screen.dart';

class _HeartbeatCard extends StatefulWidget {
  final Widget child;
  const _HeartbeatCard({required this.child});
  @override
  State<_HeartbeatCard> createState() => _HeartbeatCardState();
}

class _HeartbeatCardState extends State<_HeartbeatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.015)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

class MyWordsFolderScreen extends StatefulWidget {
  final String folderName;
  const MyWordsFolderScreen({super.key, required this.folderName});

  @override
  State<MyWordsFolderScreen> createState() => _MyWordsFolderScreenState();
}

class _MyWordsFolderScreenState extends State<MyWordsFolderScreen> {
  static final Map<String, List<ImportedCollection>> _cache = {};

  List<ImportedCollection> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.folderName];
    if (cached != null) {
      _collections = cached;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final cols = await StorageService.getCollectionsByFolder(widget.folderName);
    if (mounted) {
      setState(() {
        _collections = cols;
        _cache[widget.folderName] = cols;
        _loading = false;
      });
    }
  }

  Future<void> _openImport() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ImportScreen(prefilledFolder: widget.folderName),
    ));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.folderName,
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis),
            if (!_loading)
              Text('${_collections.length} ${_collections.length == 1 ? 'unit' : 'units'}',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _openImport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No units yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text('Import words from AI to add a unit to this folder.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Import Words', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    const cardColors = [
      Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
      Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
      Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _collections.length + 1,
      itemBuilder: (context, i) {
        if (i == _collections.length) {
          return _AddTile(label: 'New Unit', onTap: _openImport);
        }
        final col = _collections[i];
        final color = cardColors[i % cardColors.length];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => ImportCollectionDetailScreen(
                collectionName: col.name,
                folderName: widget.folderName,
              ),
            ));
            _load();
          },
          child: _HeartbeatCard(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), offset: const Offset(0, 10), blurRadius: 24),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📖', style: TextStyle(fontSize: 26)),
                  const Spacer(),
                  Text(col.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${col.count} ${col.count == 1 ? 'item' : 'items'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// A dashed-look "+ New X" tile appended to a folder/unit grid so adding one
// is as visible as the existing items, not just a small AppBar icon.
class _AddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.primary.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: context.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
