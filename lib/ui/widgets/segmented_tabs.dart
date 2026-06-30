import 'package:flutter/material.dart';

import '../brand.dart';

/// A pill segmented control wired to the surrounding [DefaultTabController].
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;

  const SegmentedTabs({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final isDark = Brand.isDark(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.index == i
                            ? (isDark ? Brand.darkSurface : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: controller.index == i
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.30 : 0.07,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: controller.index == i
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
