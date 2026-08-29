import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Text painted with the ribbon gradient — the Flutter equivalent of the design
/// system's `background-clip:text` treatment for KPI numbers and the one
/// highlighted word in a headline.
///
/// Reserved for short, large text. The ribbon runs light-to-dark across its
/// sweep, so small or long runs lose legibility; use [AppColors.pink] as a flat
/// accent there instead.
class RibbonText extends StatelessWidget {
  const RibbonText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.gradient,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? context.vistar.ribbonTextGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => g.createShader(Offset.zero & bounds.size),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        // The mask supplies the colour; this only needs to be fully opaque.
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

/// A 5x16 rounded ribbon bar — the `.sect-ttl .acc` accent, and the active-nav
/// left marker when rotated to the nav item's height.
class RibbonAccent extends StatelessWidget {
  const RibbonAccent({super.key, this.width = 5, this.height = 16});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.ribbonVertical,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
