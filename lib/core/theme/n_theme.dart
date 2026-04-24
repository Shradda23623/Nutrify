import 'package:flutter/material.dart';

/// Semantic color tokens that adapt to light/dark mode.
/// Usage:  context.surface   context.textPrimary   etc.
extension NTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Backgrounds ────────────────────────────────────────────────────────
  /// Page / scaffold background
  Color get pageBg =>
      isDark ? const Color(0xFF0D0D13) : const Color(0xFFF7F8FA);

  /// Standard card / container surface
  Color get surface =>
      isDark ? const Color(0xFF17171F) : Colors.white;

  /// Slightly elevated surface (modals, bottom sheets, popovers)
  Color get surfaceElevated =>
      isDark ? const Color(0xFF1E1E28) : Colors.white;

  /// Subtle fill for input fields and unselected chips
  Color get inputFill =>
      isDark ? const Color(0xFF242433) : const Color(0xFFF0F1F3);

  /// Even more subtle background (unselected toggle options, etc.)
  Color get subtleFill =>
      isDark ? const Color(0xFF1B1B25) : const Color(0xFFF7F8FA);

  // ── Borders & dividers ─────────────────────────────────────────────────
  /// Card border (very subtle — replaces shadows in dark mode)
  Color get cardBorder =>
      isDark ? const Color(0xFF2A2A38) : Colors.transparent;

  /// Divider line
  Color get divider =>
      isDark ? const Color(0xFF252530) : const Color(0xFFEEEEF2);

  /// Muted border for inputs, chips
  Color get mutedBorder =>
      isDark ? const Color(0xFF2E2E3E) : Colors.black.withOpacity(0.08);

  // ── Text ──────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? const Color(0xFFEEEEF4) : Colors.black87;

  Color get textSecondary =>
      isDark ? const Color(0xFFAAAAAC) : Colors.black54;

  Color get textMuted =>
      isDark ? const Color(0xFF777788) : Colors.black45;

  Color get textHint =>
      isDark ? const Color(0xFF666677) : Colors.black38;

  // ── Shadows ───────────────────────────────────────────────────────────
  /// Use for BoxShadow color — transparent in dark (borders do the job)
  Color get shadowColor =>
      isDark ? Colors.transparent : Colors.black.withOpacity(0.05);

  Color get shadowColorMd =>
      isDark ? Colors.transparent : Colors.black.withOpacity(0.08);

  // ── Helpers ───────────────────────────────────────────────────────────
  /// Standard elevated card decoration
  BoxDecoration cardDecoration({
    BorderRadius? radius,
    Color? color,
    List<BoxShadow>? extraShadow,
  }) {
    final br = radius ?? BorderRadius.circular(18);
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: br,
      border: isDark
          ? Border.all(color: cardBorder, width: 1)
          : null,
      boxShadow: isDark
          ? null
          : (extraShadow ??
              [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]),
    );
  }

  /// Section label style
  TextStyle get sectionLabelStyle => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: textHint,
        letterSpacing: 1.1,
      );
}
