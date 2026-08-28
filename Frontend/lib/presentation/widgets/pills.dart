import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;

    if (isDark) {
      switch (variant) {
        case PillVariant.ok:
          bg = const Color(0x3334D399);
          fg = const Color(0xFF34D399);
          break;
        case PillVariant.warn:
          bg = const Color(0x33FBBF24);
          fg = const Color(0xFFFBBF24);
          break;
        case PillVariant.danger:
          bg = const Color(0x33FB6F84);
          fg = const Color(0xFFFB6F84);
          break;
        case PillVariant.info:
          bg = const Color(0x335BA8FF);
          fg = const Color(0xFF5BA8FF);
          break;
        case PillVariant.purple:
          bg = const Color(0x33C018C0);
          fg = const Color(0xFFE0218A);
          break;
        case PillVariant.neutral:
          bg = const Color(0x14FFFFFF);
          fg = const Color(0xFFB9B2D6);
          break;
      }
    } else {
      switch (variant) {
        case PillVariant.ok:
          bg = const Color(0xFFD1FAE5);
          fg = const Color(0xFF047857);
          break;
        case PillVariant.warn:
          bg = const Color(0xFFFEF3C7);
          fg = const Color(0xFFB45309);
          break;
        case PillVariant.danger:
          bg = const Color(0xFFFEE2E2);
          fg = const Color(0xFFB91C1C);
          break;
        case PillVariant.info:
          bg = const Color(0xFFDBEAFE);
          fg = const Color(0xFF1D4ED8);
          break;
        case PillVariant.purple:
          bg = const Color(0xFFF3E8FF);
          fg = const Color(0xFF6B21A8);
          break;
        case PillVariant.neutral:
          bg = const Color(0xFFE2E8F0);
          fg = const Color(0xFF334155);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: isDark ? 0.3 : 0.2)),
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
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
