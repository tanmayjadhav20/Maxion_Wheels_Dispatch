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
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border(
                      top: BorderSide(color: AppColors.pink.withValues(alpha: 0.7), width: 2),
                      right: BorderSide(color: AppColors.orange.withValues(alpha: 0.5), width: 2),
                      bottom: const BorderSide(color: Colors.transparent, width: 2),
                      left: const BorderSide(color: Colors.transparent, width: 2),
                    ),
                  ),
                ),
              ),
              // Inner Reverse Spin Ring (r2)
              Transform.rotate(
                angle: -_spinController.value * 2 * math.pi,
                child: Container(
                  width: widget.size * 0.78,
                  height: widget.size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border(
                      bottom: BorderSide(color: AppColors.violet.withValues(alpha: 0.7), width: 2),
                      left: BorderSide(color: AppColors.amber.withValues(alpha: 0.5), width: 2),
                      top: const BorderSide(color: Colors.transparent, width: 2),
                      right: const BorderSide(color: Colors.transparent, width: 2),
                    ),
                  ),
                ),
              ),
              // Breathing S Mark Center
              Transform.scale(
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
            ],
          ),
        );
      },
    );
  }
}
