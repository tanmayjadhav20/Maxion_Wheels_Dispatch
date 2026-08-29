import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';
import 'vistar_logo.dart';

/// The `.card` recipe: hairline border, token radius, and the signature soft
/// vertical fill — a translucent surface gradient in dark, near-flat paper with
/// a whisper of shadow in light.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.showGlow = false,
    this.onTap,
    this.cornerMark = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Pins the card to the emphasised pink-bordered state.
  final bool showGlow;

  final VoidCallback? onTap;

  /// Draws the faint S accent bleeding off the bottom-right corner.
  final bool cornerMark;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    final interactive = widget.onTap != null;
    final lifted = widget.showGlow || (interactive && _hovered);

    Widget content = Container(
      padding: widget.padding ?? AppTokens.cardPadding(context),
      child: widget.child,
    );

    if (widget.cornerMark) {
      content = Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -30,
            child: IgnorePointer(
              child: VistarSMark(size: 120, opacity: p.isDark ? 0.05 : 0.04),
            ),
          ),
          content,
        ],
      );
    }

    final card = AnimatedContainer(
      duration: AppTokens.animFast,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, lifted && interactive ? -2 : 0, 0),
      decoration: BoxDecoration(
        gradient: p.cardGradient,
        borderRadius: BorderRadius.circular(AppTokens.r),
        border: Border.all(
          color: widget.showGlow
              ? AppColors.pink.withValues(alpha: 0.6)
              : (_hovered && interactive ? p.line2 : p.line),
        ),
        boxShadow: [
          if (lifted)
            BoxShadow(
              // --glow: 0 18px 50px -22px rgba(192,24,192,.4)
              color: AppColors.magenta.withValues(alpha: p.isDark ? 0.4 : 0.22),
              blurRadius: 28,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            )
          else if (!p.isDark)
            BoxShadow(
              color: p.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (!interactive) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}
