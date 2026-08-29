import 'package:flutter/material.dart';

/// The full Vistar Premium surface / line / text / status scale for one
/// brightness, carried on [ThemeData.extensions] so every widget resolves its
/// colours from the active theme instead of hard-coding a dark value.
///
/// The brand ribbon is deliberately not part of this class: the rainbow is the
/// one constant across both modes, and it stays a thin accent in each.
@immutable
class VistarPalette extends ThemeExtension<VistarPalette> {
  const VistarPalette({
    required this.brightness,
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.line2,
    required this.txt,
    required this.txt2,
    required this.txt3,
    required this.ok,
    required this.warn,
    required this.bad,
    required this.info,
    required this.okTint,
    required this.warnTint,
    required this.badTint,
    required this.infoTint,
    required this.brandTint,
    required this.neutralTint,
    required this.brandInk,
    required this.glowPurple,
    required this.glowPink,
    required this.glowOrange,
    required this.shadowColor,
    required this.skeletonBase,
    required this.watermarkOpacity,
    required this.cardTop,
    required this.cardBottom,
    required this.scrollThumb,
  });

  final Brightness brightness;

  /// Page grounds. [bg] is the app canvas, [bg2] the secondary panel ground.
  final Color bg;
  final Color bg2;

  /// Raised surfaces, lightest last.
  final Color surface;
  final Color surface2;
  final Color surface3;

  /// Hairline borders. [line2] is the hover / emphasis step.
  final Color line;
  final Color line2;

  /// Text ramp, strongest first.
  final Color txt;
  final Color txt2;
  final Color txt3;

  /// Status foregrounds, contrast-checked against [surface] in this brightness.
  final Color ok;
  final Color warn;
  final Color bad;
  final Color info;

  /// Translucent status grounds for pills and tinted rows.
  final Color okTint;
  final Color warnTint;
  final Color badTint;
  final Color infoTint;
  final Color brandTint;
  final Color neutralTint;

  /// Brand pink adjusted to stay legible as text on this brightness.
  final Color brandInk;

  /// Ambient aurora stops behind the app shell.
  final Color glowPurple;
  final Color glowPink;
  final Color glowOrange;

  final Color shadowColor;
  final Color skeletonBase;

  /// Opacity for the background S watermark in this brightness.
  final double watermarkOpacity;

  /// The two stops of the signature card fill.
  final Color cardTop;
  final Color cardBottom;

  final Color scrollThumb;

  bool get isDark => brightness == Brightness.dark;

  /// The near-black premium scale, verbatim from the Vistar design tokens.
  static const VistarPalette dark = VistarPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF070611),
    bg2: Color(0xFF0B0A18),
    surface: Color(0xFF110F1E),
    surface2: Color(0xFF16142A),
    surface3: Color(0xFF1D1A33),
    line: Color(0x14FFFFFF),
    line2: Color(0x21FFFFFF),
    txt: Color(0xFFF2EEFB),
    txt2: Color(0xFFB9B2D6),
    txt3: Color(0xFF7E769B),
    ok: Color(0xFF34D399),
    warn: Color(0xFFFBBF24),
    bad: Color(0xFFFB6F84),
    info: Color(0xFF5BA8FF),
    okTint: Color(0x2434D399),
    warnTint: Color(0x24FBBF24),
    badTint: Color(0x24FB6F84),
    infoTint: Color(0x245BA8FF),
    brandTint: Color(0x2EC018C0),
    neutralTint: Color(0x12FFFFFF),
    brandInk: Color(0xFFE0218A),
    glowPurple: Color(0x387A1FB0),
    glowPink: Color(0x29E0218A),
    glowOrange: Color(0x1FF06000),
    shadowColor: Color(0xD9000000),
    skeletonBase: Color(0xFF16142A),
    watermarkOpacity: 0.05,
    cardTop: Color(0xB316142A),
    cardBottom: Color(0xB3110F1E),
    scrollThumb: Color(0x669B30C9),
  );

  /// The light mirror. Grounds are a violet-tinted paper rather than a neutral
  /// grey, so the ribbon still reads as an accent of the same family, and the
  /// text and status ramps are darkened to clear WCAG AA against those grounds.
  static const VistarPalette light = VistarPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF6F4FB),
    bg2: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2EFFA),
    surface3: Color(0xFFE7E2F4),
    line: Color(0x1A17123A),
    line2: Color(0x3317123A),
    txt: Color(0xFF171233),
    txt2: Color(0xFF4A4270),
    txt3: Color(0xFF6E6690),
    ok: Color(0xFF047857),
    warn: Color(0xFF92400E),
    bad: Color(0xFFB91C1C),
    info: Color(0xFF1D4ED8),
    okTint: Color(0xFFD5F5E6),
    warnTint: Color(0xFFFCEFCD),
    badTint: Color(0xFFFBE0E0),
    infoTint: Color(0xFFDDE8FE),
    brandTint: Color(0xFFF9E4F5),
    neutralTint: Color(0xFFE9E5F3),
    brandInk: Color(0xFF9D1B7B),
    glowPurple: Color(0x1F7A1FB0),
    glowPink: Color(0x17E0218A),
    glowOrange: Color(0x14F0C000),
    shadowColor: Color(0x1A17123A),
    skeletonBase: Color(0xFFEDE9F7),
    watermarkOpacity: 0.045,
    cardTop: Color(0xFFFFFFFF),
    cardBottom: Color(0xFFFCFBFE),
    scrollThumb: Color(0x669B30C9),
  );

  static VistarPalette of(BuildContext context) =>
      Theme.of(context).extension<VistarPalette>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// The signature card fill: a soft vertical gradient in dark, near-flat paper
  /// in light.
  LinearGradient get cardGradient => LinearGradient(
        colors: [cardTop, cardBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  /// The ribbon as used for gradient-clipped *text*.
  ///
  /// The stock ribbon ends in cream (#F7EE9A), which is the right finish on
  /// near-black but leaves the last glyphs of a headline or KPI unreadable on
  /// paper. Light mode therefore runs a luminance-capped ribbon: same hue
  /// sweep, every stop dark enough to hold contrast against [surface].
  LinearGradient get ribbonTextGradient => isDark
      ? const LinearGradient(
          colors: [
            Color(0xFF7A1FB0),
            Color(0xFFB81FB8),
            Color(0xFFE0218A),
            Color(0xFFD11630),
            Color(0xFFF0480C),
            Color(0xFFF06000),
            Color(0xFFF0C000),
            Color(0xFFF7EE9A),
          ],
          stops: [0.0, 0.22, 0.40, 0.56, 0.70, 0.80, 0.92, 1.0],
          begin: Alignment(-1.0, -0.42),
          end: Alignment(1.0, 0.42),
        )
      : const LinearGradient(
          colors: [
            Color(0xFF6A1A9A),
            Color(0xFF9E189E),
            Color(0xFFC01B76),
            Color(0xFFB01228),
            Color(0xFFC93C0A),
            Color(0xFFB34F00),
            Color(0xFF8F6A00),
          ],
          stops: [0.0, 0.22, 0.42, 0.58, 0.74, 0.88, 1.0],
          begin: Alignment(-1.0, -0.42),
          end: Alignment(1.0, 0.42),
        );

  /// Foreground / ground pair for a status, keyed the same way in both modes.
  List<Color> statusPair(VistarStatus status) {
    switch (status) {
      case VistarStatus.ok:
        return [ok, okTint];
      case VistarStatus.warn:
        return [warn, warnTint];
      case VistarStatus.bad:
        return [bad, badTint];
      case VistarStatus.info:
        return [info, infoTint];
      case VistarStatus.brand:
        return [brandInk, brandTint];
      case VistarStatus.neutral:
        return [txt2, neutralTint];
    }
  }

  @override
  VistarPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? line2,
    Color? txt,
    Color? txt2,
    Color? txt3,
    Color? ok,
    Color? warn,
    Color? bad,
    Color? info,
    Color? okTint,
    Color? warnTint,
    Color? badTint,
    Color? infoTint,
    Color? brandTint,
    Color? neutralTint,
    Color? brandInk,
    Color? glowPurple,
    Color? glowPink,
    Color? glowOrange,
    Color? shadowColor,
    Color? skeletonBase,
    double? watermarkOpacity,
    Color? cardTop,
    Color? cardBottom,
    Color? scrollThumb,
  }) {
    return VistarPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      txt: txt ?? this.txt,
      txt2: txt2 ?? this.txt2,
      txt3: txt3 ?? this.txt3,
      ok: ok ?? this.ok,
      warn: warn ?? this.warn,
      bad: bad ?? this.bad,
      info: info ?? this.info,
      okTint: okTint ?? this.okTint,
      warnTint: warnTint ?? this.warnTint,
      badTint: badTint ?? this.badTint,
      infoTint: infoTint ?? this.infoTint,
      brandTint: brandTint ?? this.brandTint,
      neutralTint: neutralTint ?? this.neutralTint,
      brandInk: brandInk ?? this.brandInk,
      glowPurple: glowPurple ?? this.glowPurple,
      glowPink: glowPink ?? this.glowPink,
      glowOrange: glowOrange ?? this.glowOrange,
      shadowColor: shadowColor ?? this.shadowColor,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      cardTop: cardTop ?? this.cardTop,
      cardBottom: cardBottom ?? this.cardBottom,
      scrollThumb: scrollThumb ?? this.scrollThumb,
    );
  }

  @override
  VistarPalette lerp(ThemeExtension<VistarPalette>? other, double t) {
    if (other is! VistarPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return VistarPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: c(bg, other.bg),
      bg2: c(bg2, other.bg2),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      surface3: c(surface3, other.surface3),
      line: c(line, other.line),
      line2: c(line2, other.line2),
      txt: c(txt, other.txt),
      txt2: c(txt2, other.txt2),
      txt3: c(txt3, other.txt3),
      ok: c(ok, other.ok),
      warn: c(warn, other.warn),
      bad: c(bad, other.bad),
      info: c(info, other.info),
      okTint: c(okTint, other.okTint),
      warnTint: c(warnTint, other.warnTint),
      badTint: c(badTint, other.badTint),
      infoTint: c(infoTint, other.infoTint),
      brandTint: c(brandTint, other.brandTint),
      neutralTint: c(neutralTint, other.neutralTint),
      brandInk: c(brandInk, other.brandInk),
      glowPurple: c(glowPurple, other.glowPurple),
      glowPink: c(glowPink, other.glowPink),
      glowOrange: c(glowOrange, other.glowOrange),
      shadowColor: c(shadowColor, other.shadowColor),
      skeletonBase: c(skeletonBase, other.skeletonBase),
      watermarkOpacity:
          watermarkOpacity + (other.watermarkOpacity - watermarkOpacity) * t,
      cardTop: c(cardTop, other.cardTop),
      cardBottom: c(cardBottom, other.cardBottom),
      scrollThumb: c(scrollThumb, other.scrollThumb),
    );
  }
}

enum VistarStatus { ok, warn, bad, info, brand, neutral }
