import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum PillVariant { ok, warn, danger, info, purple, neutral }

class StatusPill extends StatelessWidget {
  final String label;
  final PillVariant variant;

  const StatusPill({
    super.key,
    required this.label,
    this.variant = PillVariant.info,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case PillVariant.ok:
        bg = AppColors.okTint;
        fg = AppColors.ok;
        break;
      case PillVariant.warn:
        bg = AppColors.warnTint;
        fg = AppColors.warn;
        break;
      case PillVariant.danger:
        bg = AppColors.dangerTint;
        fg = AppColors.danger;
        break;
      case PillVariant.info:
        bg = AppColors.infoTint;
        fg = AppColors.info;
        break;
      case PillVariant.purple:
        bg = AppColors.purpleTint;
        fg = AppColors.ribbonPurple;
        break;
      case PillVariant.neutral:
        bg = Colors.white10;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
