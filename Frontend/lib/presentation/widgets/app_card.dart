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
    this.cornerMark = true,
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

    // The corner S is a dark-mode treatment, matching what f90a2f5 shipped: on
    // paper a 4%-opacity rainbow smudge just reads as a printing defect.
    if (widget.cornerMark && p.isDark) {
      content = Stack(
        children: [
          const Positioned(
            right: -26,
            bottom: -30,
            child: IgnorePointer(
              child: VistarSMark(size: 120, opacity: 0.05),
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
          // The magenta bloom is a dark-mode effect; over paper it just muddies
          // the surface, so light mode keeps the neutral shadow below.
          if (lifted && p.isDark)
            BoxShadow(
              // --glow: 0 18px 50px -22px rgba(192,24,192,.4)
              color: AppColors.magenta.withValues(alpha: 0.4),
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

    // InkWell rather than GestureDetector: it puts the card in the focus
    // traversal chain and maps Enter/Space to onTap, which a bare
    // GestureDetector does not. onHover drives the same hover state a
    // MouseRegion would, so the styling is unchanged.
    return InkWell(
      onTap: widget.onTap,
      onHover: (h) => setState(() => _hovered = h),
      borderRadius: BorderRadius.circular(AppTokens.r),
      focusColor: AppColors.pink.withValues(alpha: 0.12),
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: card,
    );
  }
}
