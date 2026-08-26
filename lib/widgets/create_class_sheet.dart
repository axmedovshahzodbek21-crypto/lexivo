import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../l10n.dart';

/// Shared "Create class" bottom sheet, used by both the teacher's
/// created-classes screen and the top-level classes screen. Both used to
/// keep their own copy of this identical sheet — [onCreate] is called with
/// the entered name when the user confirms (via the button or submitting
/// the field), same as each screen's own `_createClass`.
void showCreateClassSheet(BuildContext context, void Function(String name) onCreate) {
  final ctrl = TextEditingController();
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(tr('create_class'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl, autofocus: true,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              hintText: 'e.g. English B1 — Group A',
              hintStyle: TextStyle(color: context.textMuted),
              filled: true, fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onSubmitted: (v) { Navigator.pop(ctx); onCreate(v); },
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: context.textMuted, side: BorderSide(color: context.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(tr('cancel')),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () { final v = ctrl.text; Navigator.pop(ctx); onCreate(v); },
              style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(tr('create_class'), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ]),
        ]),
      ),
    ),
  ).whenComplete(ctrl.dispose);
}
