import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';

enum AppButtonVariant { gradient, ghost, danger, secondary }

/// The `.btn` family.
///
/// [AppButtonVariant.gradient] is the ribbon primary — used sparingly, one per
/// view, per the design system's restraint rule. Ghost and danger read off the
/// active palette so they invert correctly in light mode.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.gradient,
    bool? isLoading,
    bool? isFullWidth,
    this.isCompact = false,
  })  : isLoading = isLoading ?? false,
        isFullWidth = isFullWidth ?? false;

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  /// The `.btn-sm` step.
  final bool isCompact;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final isRibbon = widget.variant == AppButtonVariant.gradient;

    late final Decoration decoration;
    late final Color textColor;

    switch (widget.variant) {
      case AppButtonVariant.gradient:
        decoration = BoxDecoration(
          gradient: AppColors.ribbonGradient,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          boxShadow: [
            BoxShadow(
              // 0 14px 34px -14px rgba(224,33,138,.7)
              color: AppColors.pink.withValues(alpha: _hovered ? 0.7 : 0.5),
              blurRadius: _hovered ? 22 : 16,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        );
        textColor = Colors.white;

      case AppButtonVariant.ghost:
      case AppButtonVariant.secondary:
        decoration = BoxDecoration(
          color: _hovered ? p.surface3 : p.surface2,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(color: _hovered ? p.line2 : p.line),
        );
        textColor = p.txt;

      case AppButtonVariant.danger:
        decoration = BoxDecoration(
          color: p.badTint,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(color: p.bad.withValues(alpha: _hovered ? 0.65 : 0.4)),
        );
        textColor = p.bad;
    }

    final content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
          ),
          const SizedBox(width: 9),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: widget.isCompact ? 16 : 18, color: textColor),
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Text(
            widget.text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: textColor,
              fontSize: widget.isCompact ? 13 : 13.5,
              fontWeight: FontWeight.w700,
              // The ribbon finishes in amber/cream, where white label text
              // loses contrast. A tight dark shadow holds the glyph edges
              // without reading as a drop shadow.
              shadows: isRibbon
                  ? const [Shadow(color: Color(0x59000000), blurRadius: 3, offset: Offset(0, 1))]
                  : null,
            ),
          ),
        ),
      ],
    );

    // InkWell rather than GestureDetector: it keeps the button in the focus
    // traversal chain and maps Enter/Space to the action. A bare
    // GestureDetector gives mouse-tap only, which strands keyboard users in
    // the desktop dispatch office.
    return InkWell(
      onTap: enabled ? widget.onPressed : null,
      onHover: (h) => setState(() => _hovered = h),
      borderRadius: BorderRadius.circular(AppTokens.rSm),
      focusColor: Colors.white.withValues(alpha: 0.14),
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedOpacity(
          duration: AppTokens.animFast,
          opacity: enabled ? 1.0 : 0.5,
          child: AnimatedContainer(
            duration: AppTokens.animFast,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _hovered && enabled ? -1 : 0, 0),
            padding: widget.isCompact
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
                : AppTokens.pButton,
            decoration: decoration,
            child: content,
          ),
        ),
    );
  }
}
