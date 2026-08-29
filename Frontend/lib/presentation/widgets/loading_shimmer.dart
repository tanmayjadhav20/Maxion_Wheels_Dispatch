import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';

/// The `.skel` recipe: a flat surface block with a rainbow sweep travelling
/// left to right, matching the design system's `shimmer` keyframe rather than
/// rotating the gradient in place.
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppTokens.rSm,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    // The sweep needs more presence on paper than it does on near-black.
    final boost = p.isDark ? 1.0 : 1.6;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Travel the sweep from fully off the left to fully off the right.
            final t = _controller.value * 2 - 1;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: p.skeletonBase,
                gradient: LinearGradient(
                  begin: Alignment(t - 1, 0),
                  end: Alignment(t + 1, 0),
                  colors: [
                    Colors.transparent,
                    AppColors.pink.withValues(alpha: 0.16 * boost),
                    AppColors.orange.withValues(alpha: 0.12 * boost),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 0.58, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
