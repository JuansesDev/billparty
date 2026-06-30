import 'package:flutter/material.dart';

import '../brand.dart';

/// A circular initials avatar, colored deterministically from the name.
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? borderColor;

  const Avatar({
    super.key,
    required this.name,
    this.size = 36,
    this.borderColor,
  });

  static String initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Brand.isDark(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Brand.avatarColor(name, dark: dark),
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2.5)
            : null,
      ),
      child: Text(
        initials(name),
        style: TextStyle(
          color: dark ? const Color(0xFF18181B) : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Overlapping stack of avatars, with a "+N" bubble when there are too many.
class AvatarCluster extends StatelessWidget {
  final List<String> names;
  final double size;
  final int max;

  const AvatarCluster({
    super.key,
    required this.names,
    this.size = 34,
    this.max = 4,
  });

  @override
  Widget build(BuildContext context) {
    final border = Brand.surface(context);
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = size * 0.64; // 36% overlap
    final slots = shown.length + (extra > 0 ? 1 : 0);
    final width = slots == 0 ? 0.0 : size + step * (slots - 1);

    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Avatar(name: shown[i], size: size, borderColor: border),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Brand.isDark(context)
                      ? const Color(0xFF3F3F46)
                      : const Color(0xFFE4E4E7),
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2.5),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
