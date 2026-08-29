import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'vistar_logo.dart';

/// The splash orbit loader: two counter-spinning rings around a breathing S.
///
/// Ring colours are fixed brand hues — they read on both grounds — while the
/// centre glow is dialled back in light mode by [VistarSMark].
class OrbitLoader extends StatefulWidget {
  const OrbitLoader({super.key, this.size = 180});

  final double size;

  @override
  State<OrbitLoader> createState() => _OrbitLoaderState();
}

class _OrbitLoaderState extends State<OrbitLoader> with TickerProviderStateMixin {
  // r1: 1.6s forward. r2: 2.2s reverse.
  late final AnimationController _outer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final AnimationController _inner = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final Animation<double> _breatheScale = Tween<double>(
    begin: 0.92,
    end: 1.04,
  ).animate(CurvedAnimation(parent: _breathe, curve: Curves.easeInOut));

  late final Animation<double> _breatheLift = Tween<double>(
    begin: 2.0,
    end: -2.0,
  ).animate(CurvedAnimation(parent: _breathe, curve: Curves.easeInOut));

  @override
  void dispose() {
    _outer.dispose();
    _inner.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _outer,
              builder: (context, child) => Transform.rotate(
                angle: _outer.value * 2 * math.pi,
                child: child,
              ),
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _OrbitArcPainter(
                  colors: [
                    AppColors.pink.withValues(alpha: 0.65),
                    AppColors.orange.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _inner,
              builder: (context, child) => Transform.rotate(
                angle: -_inner.value * 2 * math.pi,
                child: child,
              ),
              child: CustomPaint(
                size: Size.square(widget.size * 0.78),
                painter: _OrbitArcPainter(
                  colors: [
                    AppColors.violet.withValues(alpha: 0.65),
                    AppColors.amber.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  strokeWidth: 1.5,
                  startAngleOffset: math.pi,
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _breathe,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _breatheLift.value),
                child: Transform.scale(scale: _breatheScale.value, child: child),
              ),
              child: VistarSMark(size: widget.size * 0.48, glow: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitArcPainter extends CustomPainter {
  const _OrbitArcPainter({
    required this.colors,
    required this.strokeWidth,
    this.startAngleOffset = 0.0,
  });

  final List<Color> colors;
  final double strokeWidth;
  final double startAngleOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        stops: const [0.0, 0.65, 1.0],
        transform: GradientRotation(startAngleOffset),
      ).createShader(rect);

    final inset = strokeWidth / 2;
    final arcRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawArc(arcRect, startAngleOffset, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitArcPainter old) =>
      old.colors != colors ||
      old.strokeWidth != strokeWidth ||
      old.startAngleOffset != startAngleOffset;
}

/// The ribbon progress bar under the splash orbit — a 40%-wide ribbon slug
/// sliding across a hairline track.
class RibbonProgressBar extends StatefulWidget {
  const RibbonProgressBar({super.key, this.width = 200, this.height = 4});

  final double width;
  final double height;

  @override
  State<RibbonProgressBar> createState() => _RibbonProgressBarState();
}

class _RibbonProgressBarState extends State<RibbonProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: p.isDark ? Colors.white10 : p.surface3),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Align(
                alignment: Alignment(t * 2 * 1.35 - 1.35, 0),
                child: child,
              );
            },
            child: FractionallySizedBox(
              widthFactor: 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.ribbonGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
