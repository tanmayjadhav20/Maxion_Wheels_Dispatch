import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Canonical paths for the Vistar brand marks.
///
/// The files under `assets/brand/` are autocropped, transparent-background
/// derivatives generated from the source art at `assets/logo.png` (the S
/// swoosh) and `assets/logo_name.png` (the wordmark) by
/// `tool/build_brand_assets.js`.
///
/// The sources are 1536x1024 with the mark occupying under half the frame, so
/// cropping is what makes a mark actually fill the box it is given — and it
/// takes the three shipped files from 4.3 MB down to 928 KB. Only the
/// derivatives are bundled; the sources stay in the repo as art, not payload.
class VistarAssets {
  VistarAssets._();

  /// S mark at 720px — loaders, page watermark, card corner accents.
  static const String sMark = 'assets/brand/s_mark.png';

  /// S mark at 280px — small inline UI spots.
  static const String sMarkSmall = 'assets/brand/s_mark_sm.png';

  /// Wordmark at 972px wide — splash and login only.
  static const String wordmark = 'assets/brand/wordmark.png';
}

/// The Vistar "S" swoosh.
///
/// [glow] adds the pink drop-shadow the design system puts behind the mark in
/// loaders; it is softened in light mode where a bloom would muddy the paper.
class VistarSMark extends StatelessWidget {
  const VistarSMark({
    super.key,
    this.size = 48,
    this.glow = false,
    this.opacity = 1.0,
  });

  final double size;
  final bool glow;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    // Pick the small derivative when it can still cover the physical pixels.
    final usesSmall = size * dpr <= 280;

    Widget mark = Image.asset(
      usesSmall ? VistarAssets.sMarkSmall : VistarAssets.sMark,
      height: size,
      width: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _RibbonFallback(size: size, label: 'S'),
    );

    if (opacity < 1.0) {
      mark = Opacity(opacity: opacity, child: mark);
    }

    if (!glow) return mark;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: context.isDark ? 0.55 : 0.28),
            blurRadius: size * 0.3,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: mark,
    );
  }
}

/// The Vistar wordmark, with a graceful degrade to the S mark plus set type if
/// the image cannot be loaded.
class VistarWordmark extends StatelessWidget {
  const VistarWordmark({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      VistarAssets.wordmark,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _WordmarkFallback(height: height),
    );
  }
}

/// Brand lockup used across the shell.
///
/// [showWordmark] selects the wordmark; otherwise just the S mark. The API is
/// kept from the original widget so existing call sites are unchanged.
class VistarLogo extends StatelessWidget {
  const VistarLogo({
    super.key,
    this.size = 48,
    this.showWordmark = true,
  });

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    if (showWordmark) {
      return VistarWordmark(height: size);
    }
    return VistarSMark(size: size);
  }
}

class _WordmarkFallback extends StatelessWidget {
  const _WordmarkFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RibbonFallback(size: height, label: 'S'),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VISTAR',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: height * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                height: 1.1,
              ),
            ),
            Text(
              'LOGITEK',
              style: TextStyle(
                color: context.brandInk,
                fontSize: height * 0.22,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.0,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RibbonFallback extends StatelessWidget {
  const _RibbonFallback({required this.size, required this.label});

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.ribbonGradient,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.55,
        ),
      ),
    );
  }
}
