import 'package:flutter/material.dart';

import '../brand.dart';

enum PillVariant { primary, secondary, ghost }

enum PillSize { md, sm }

/// The single button used across the whole app. Variants keep every screen
/// consistent: [primary] (high-contrast pill), [secondary] (subtle grey),
/// [ghost] (text only).
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final PillVariant variant;
  final PillSize size;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = false,
    this.variant = PillVariant.primary,
    this.size = PillSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Brand.isDark(context);
    final disabled = onPressed == null;

    Color bg;
    Color fg;
    List<BoxShadow>? shadow;

    switch (variant) {
      case PillVariant.primary:
        bg = isDark ? const Color(0xFFEDE7DB) : Brand.ink;
        fg = isDark ? Brand.ink : Colors.white;
        shadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ];
      case PillVariant.secondary:
        bg = scheme.onSurface.withValues(alpha: 0.08);
        fg = scheme.onSurface;
        shadow = null;
      case PillVariant.ghost:
        bg = Colors.transparent;
        fg = scheme.onSurface;
        shadow = null;
    }

    if (disabled) {
      bg = variant == PillVariant.ghost
          ? Colors.transparent
          : scheme.onSurface.withValues(alpha: 0.10);
      fg = scheme.onSurface.withValues(alpha: 0.38);
      shadow = null;
    }

    final small = size == PillSize.sm;
    final radius = BorderRadius.circular(30);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 16 : 24,
              vertical: small ? 9 : 16,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: fg, size: small ? 16 : 20),
                  SizedBox(width: small ? 6 : 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: small ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
