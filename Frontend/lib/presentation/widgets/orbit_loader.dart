import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'vistar_logo.dart';

class OrbitLoader extends StatefulWidget {
  final double size;

  const OrbitLoader({super.key, this.size = 180});

  @override
  State<OrbitLoader> createState() => _OrbitLoaderState();
}

class _OrbitLoaderState extends State<OrbitLoader> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.92, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinController, _breatheController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Counter-Spin Ring (r1)
              Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _OrbitArcPainter(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.8),
                      AppColors.orange.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    strokeWidth: 2.0,
                  ),
                ),
              ),
              // Inner Reverse Spin Ring (r2)
              Transform.rotate(
                angle: -_spinController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.78, widget.size * 0.78),
                  painter: _OrbitArcPainter(
                    colors: [
                      AppColors.violet.withValues(alpha: 0.8),
                      AppColors.amber.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    strokeWidth: 2.0,
                    startAngleOffset: math.pi,
                  ),
                ),
              ),
              // Breathing S Mark Center
              RepaintBoundary(
                child: Transform.scale(
                  scale: _breatheAnimation.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66E0218A),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: VistarLogo(size: widget.size * 0.42, showWordmark: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrbitArcPainter extends CustomPainter {
  final List<Color> colors;
  final double strokeWidth;
  final double startAngleOffset;

  _OrbitArcPainter({
    required this.colors,
    required this.strokeWidth,
    this.startAngleOffset = 0.0,
  });

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
    final arcRect = Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth);
    canvas.drawArc(arcRect, startAngleOffset, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _OrbitArcPainter oldDelegate) => true;
}
