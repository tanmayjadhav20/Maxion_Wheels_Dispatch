import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/vistar_palette.dart';

enum PillVariant { ok, warn, danger, info, purple, neutral }

/// The `.pill` recipe: translucent status tint, a coloured dot, and the label in
/// the matching ink. Both grounds and inks come from the palette, so contrast
/// holds in either mode.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.variant = PillVariant.info,
    this.icon,
  });

  final String label;
  final PillVariant variant;
  final IconData? icon;

  VistarStatus get _status {
    switch (variant) {
      case PillVariant.ok:
        return VistarStatus.ok;
      case PillVariant.warn:
        return VistarStatus.warn;
      case PillVariant.danger:
        return VistarStatus.bad;
      case PillVariant.info:
        return VistarStatus.info;
      case PillVariant.purple:
        return VistarStatus.brand;
      case PillVariant.neutral:
        return VistarStatus.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    final pair = p.statusPair(_status);
    final fg = pair[0];
    final bg = pair[1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: p.isDark ? 0.3 : 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(icon, size: 12, color: fg),
            )
          else
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: fg,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
