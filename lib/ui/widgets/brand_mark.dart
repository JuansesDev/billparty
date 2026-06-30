import 'package:flutter/material.dart';

/// The BillParty logo mark — the app icon, used in the header.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    // The rasterized PNG can carry a faint anti-aliased halo at its edge, which
    // shows as a white outline in dark mode. Zoom in slightly and clip the
    // rounded silhouette so that halo is pushed outside the clip.
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: SizedBox(
        width: size,
        height: size,
        child: Transform.scale(
          scale: 1.06,
          child: Image.asset(
            'assets/icon/billparty-icon.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
