import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../presentation/widgets/vistar_logo.dart';
import 'vistar_palette.dart';

/// The signature Vistar page ground: three aurora radial glows, a faint S
/// watermark bled off the right edge, and a fine grain overlay.
///
/// In dark mode this is the near-black canvas the ribbon pops against. In light
/// mode the same three glows are dialled right down over paper, so the page
/// keeps the brand's warmth without turning into a pastel wash.
class VistarBackdrop extends StatelessWidget {
  const VistarBackdrop({
    super.key,
    required this.child,
    this.showWatermark = true,
    this.showGrain = true,
  });

  final Widget child;
  final bool showWatermark;
  final bool showGrain;

  @override
  Widget build(BuildContext context) {
    final p = VistarPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: p.bg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // radial-gradient(800px 600px at 12% -8%, purple)
          _Glow(color: p.glowPurple, alignment: const Alignment(-0.76, -1.16), radius: 0.95),
          // radial-gradient(700px 600px at 105% 8%, pink)
          _Glow(color: p.glowPink, alignment: const Alignment(1.1, -0.84), radius: 0.85),
          // radial-gradient(900px 700px at 80% 110%, orange)
          _Glow(color: p.glowOrange, alignment: const Alignment(0.6, 1.2), radius: 1.05),

          if (showWatermark)
            Positioned.fill(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerRight,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: FractionallySizedBox(
                    widthFactor: 0.62,
                    alignment: Alignment.centerRight,
                    child: Transform.translate(
                      offset: const Offset(80, 0),
                      child: Transform.rotate(
                        angle: 4 * math.pi / 180,
                        child: Opacity(
                          opacity: p.watermarkOpacity,
                          child: Image.asset(
                            VistarAssets.sMark,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (showGrain) const Positioned.fill(child: _Grain()),

          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.alignment, required this.radius});

  final Color color;
  final Alignment alignment;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: alignment,
              radius: radius,
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0.0, 0.6],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fine fractal-noise overlay, matching the `.grain` layer in the design system.
///
/// The 96x96 tile is generated once and cached for the process; painting it
/// tiled costs one shader draw per frame rather than any per-pixel work.
class _Grain extends StatefulWidget {
  const _Grain();

  @override
  State<_Grain> createState() => _GrainState();
}

class _GrainState extends State<_Grain> {
  static ui.Image? _tile;
  static Future<ui.Image>? _pending;

  @override
  void initState() {
    super.initState();
    if (_tile == null) {
      (_pending ??= _buildTile()).then((img) {
        if (!mounted) return;
        setState(() => _tile = img);
      });
    }
  }

  static Future<ui.Image> _buildTile() {
    const size = 96;
    final rnd = math.Random(0x5EED);
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      final v = rnd.nextInt(256);
      pixels[i * 4] = v;
      pixels[i * 4 + 1] = v;
      pixels[i * 4 + 2] = v;
      pixels[i * 4 + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, size, size, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile;
    if (tile == null) return const SizedBox.shrink();
    final p = VistarPalette.of(context);
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(
          tile: tile,
          opacity: p.isDark ? 0.045 : 0.025,
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.tile, required this.opacity});

  final ui.Image tile;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.overlay
      ..colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: opacity),
        BlendMode.modulate,
      )
      ..shader = ImageShader(
        tile,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      old.tile != tile || old.opacity != opacity;
}
