import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  Color get bg       => isDark ? const Color(0xFF0F0E1A) : const Color(0xFFF8F7FF);
  Color get surface  => isDark ? const Color(0xFF1A1928) : Colors.white;
  Color get surface2 => isDark ? const Color(0xFF252438) : const Color(0xFFF3F4F6);

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get appText   => isDark ? const Color(0xFFEEEEFF) : const Color(0xFF1A1A2E);
  Color get textMuted => isDark ? const Color(0xFF9999BB) : const Color(0xFF6B7280);

  // ── Borders ───────────────────────────────────────────────────────────────
  Color get border => isDark ? const Color(0xFF2E2D45) : const Color(0xFFE5E7EB);

  // ── Primary ───────────────────────────────────────────────────────────────
  Color get primary   => isDark ? const Color(0xFF8B85FF) : const Color(0xFF6C63FF);
  Color get primaryBg => isDark ? const Color(0xFF1E1D3A) : const Color(0xFFEEF2FF);

  // ── Status ────────────────────────────────────────────────────────────────
  Color get successColor => isDark ? const Color(0xFF34D399) : const Color(0xFF2ECC71);
  Color get successBg    => isDark ? const Color(0xFF0D2E20) : const Color(0xFFE8F8F0);
  Color get dangerColor  => isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
  Color get dangerBg     => isDark ? const Color(0xFF2D1010) : const Color(0xFFFFEEEE);

  // ── Shadows ───────────────────────────────────────────────────────────────
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}
