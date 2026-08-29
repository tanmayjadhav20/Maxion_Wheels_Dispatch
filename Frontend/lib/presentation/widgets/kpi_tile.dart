import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import '../../core/theme/app_theme.dart';

/// A compact metric tile.
///
/// Height is fixed rather than derived from an aspect ratio: a ratio-sized tile
/// grows with the column width, so on a wide screen four numbers end up filling
/// half the page with whitespace. [height] is the whole tile, and the type
/// scale is tuned so a value, its label and one line of context sit in it
/// comfortably at any width.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.accent,
    this.onTap,
  });

  /// Short uppercase caption, e.g. "Plan Achievement".
  final String label;

  /// The number itself. Kept short — "13 / 23", not a sentence.
  final String value;

  final IconData icon;

  /// One line of supporting context under the value.
  final String? detail;

  /// Status colour for the icon chip and detail line. Defaults to brand pink.
  final Color? accent;

  final VoidCallback? onTap;

  /// Fixed tile height. Two lines of value plus a detail line fit at this size.
  static const double height = 96;

  /// Target tile width used to choose the column count. Tiles flex from here,
  /// so the grid reflows smoothly instead of jumping at hard breakpoints.
  static const double targetWidth = 250;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    final color = accent ?? p.brandInk;

    final tile = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppTokens.r),
        border: Border.all(color: p.line),
        boxShadow: p.isDark
            ? null
            : [BoxShadow(color: p.shadowColor, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: p.isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.txt3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                // Long values shrink to fit rather than wrapping the tile taller.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTheme.display(p.txt, size: 21, height: 1.1),
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    // InkWell keeps the tile keyboard-reachable; GestureDetector would make it
    // mouse-only.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r),
      focusColor: AppColors.pink.withValues(alpha: 0.12),
      child: tile,
    );
  }
}

/// Lays [tiles] out at a consistent compact size, choosing the column count
/// from the available width instead of fixed breakpoints.
class KpiTileGrid extends StatelessWidget {
  const KpiTileGrid({super.key, required this.tiles, this.spacing = 12});

  final List<Widget> tiles;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            (width / (KpiTile.targetWidth + spacing)).floor().clamp(1, tiles.length);
        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}
