import 'package:flutter/material.dart';

/// BillParty's identity: strictly monochrome — black, white, and greys. The
/// only color is the logo mark (an image asset).
class Brand {
  Brand._();

  /// Neutral seed → a near-monochrome Material tonal palette.
  static const neutralSeed = Color(0xFF6B6B6B);

  // Light
  static const lightBg = Color(0xFFF4F4F5);
  static const ink = Color(0xFF18181B);
  static const muted = Color(0xFF71717A);

  // Dark
  static const darkBg = Color(0xFF0E0E10);
  static const darkSurface = Color(0xFF1C1C1F);
  static const darkInk = Color(0xFFFAFAFA);
  static const darkMuted = Color(0xFFA1A1AA);

  // Avatars stay monochrome: dark greys (light text) in light mode, light greys
  // (dark text) in dark mode — always readable, always on-brand.
  static const _avatarsLight = <Color>[
    Color(0xFF27272A),
    Color(0xFF3F3F46),
    Color(0xFF52525B),
    Color(0xFF18181B),
    Color(0xFF5B5B63),
    Color(0xFF35353B),
  ];
  static const _avatarsDark = <Color>[
    Color(0xFFD4D4D8),
    Color(0xFFA1A1AA),
    Color(0xFFB8B8BF),
    Color(0xFFE4E4E7),
    Color(0xFF9A9AA3),
    Color(0xFFC4C4CB),
  ];

  static Color avatarColor(String seed, {required bool dark}) {
    final palette = dark ? _avatarsDark : _avatarsLight;
    var sum = 0;
    for (final unit in seed.codeUnits) {
      sum += unit;
    }
    return palette[sum % palette.length];
  }

  // Semantic colors — the only color besides the logo, used just for balances:
  // green = is owed, red = owes. Tuned for light and dark.
  static const _owedLight = Color(0xFF2E9E6B);
  static const _owedDark = Color(0xFF5FCB92);
  static const _owesLight = Color(0xFFCC4B4F);
  static const _owesDark = Color(0xFFEB7E83);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color owed(BuildContext context) =>
      isDark(context) ? _owedDark : _owedLight;

  static Color owes(BuildContext context) =>
      isDark(context) ? _owesDark : _owesLight;
}
