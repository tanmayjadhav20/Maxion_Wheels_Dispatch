import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';

class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppTokens.rSm,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                AppColors.bgSurfaceElevated,
                AppColors.ribbonPink.withOpacity(0.16),
                AppColors.ribbonOrange.withOpacity(0.12),
                AppColors.bgSurfaceElevated,
              ],
              stops: const [0.0, 0.4, 0.6, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
        );
      },
    );
  }
}
