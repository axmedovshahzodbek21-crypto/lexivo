import 'package:flutter/material.dart';
import '../app_theme.dart';

// Gentle pulse used to draw attention to a card without being distracting —
// shared by imported_words_screen.dart's folder grid and
// my_words_folder_screen.dart's collection grid, which previously each had
// their own verbatim copy.
class HeartbeatCard extends StatefulWidget {
  final Widget child;
  const HeartbeatCard({super.key, required this.child});
  @override
  State<HeartbeatCard> createState() => _HeartbeatCardState();
}

class _HeartbeatCardState extends State<HeartbeatCard> with SingleTickerProviderStateMixin {
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

// A dashed-look "+ New X" tile appended to a folder/unit grid so adding one
// is as visible as the existing items, not just a small AppBar icon.
class AddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AddTile({super.key, required this.label, required this.onTap});

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

// 12-entry palette cycled through for folder/collection cards — shared by
// the same two screens as HeartbeatCard/AddTile above.
const myWordsCardColors = [
  Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
  Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
  Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
];
