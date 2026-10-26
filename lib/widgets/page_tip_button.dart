import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/page_tips.dart';
import '../l10n.dart';

// "?" button for a screen's header. Also opens the screen's tip by itself the
// first time this account lands on the screen (see lib/data/page_tips.dart).
class PageTipButton extends StatefulWidget {
  final String tipId;
  final Color? color;
  const PageTipButton(this.tipId, {super.key, this.color});

  @override
  State<PageTipButton> createState() => _PageTipButtonState();
}

class _PageTipButtonState extends State<PageTipButton> {
  @override
  void initState() {
    super.initState();
    PageTips.shouldShow(widget.tipId).then((show) {
      if (show && mounted) _open();
    });
  }

  Map<String, String> get _ui => pageTipsUi[appLangNotifier.value] ?? pageTipsUi['en']!;

  Future<void> _open() async {
    final tip = pageTips[widget.tipId]?[appLangNotifier.value] ?? pageTips[widget.tipId]?['en'];
    if (tip == null) return;
    final ui = _ui;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 ${tip.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ctx.appText)),
            const SizedBox(height: 20),
            for (final (icon, title, desc) in tip.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 40, height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: ctx.primaryBg, borderRadius: BorderRadius.circular(14)),
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ctx.appText)),
                      const SizedBox(height: 2),
                      Text(desc, style: TextStyle(fontSize: 12, height: 1.4, color: ctx.textMuted)),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(ui['gotIt']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  PageTips.setEnabled(false);
                  Navigator.pop(ctx);
                },
                child: Text(ui['turnOff']!, style: TextStyle(fontSize: 12, color: ctx.textMuted)),
              ),
            ),
          ]),
        ),
      ),
    );
    PageTips.markSeen(widget.tipId);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline_rounded, color: widget.color ?? context.primary),
      tooltip: _ui['showTip'],
      onPressed: _open,
    );
  }
}
