import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VistarLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const VistarLogo({
    super.key,
    this.size = 48,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final targetCacheHeight = (size * 2).clamp(48, 256).toInt();

    if (showWordmark) {
      return Image.asset(
        'assets/logo_name.png',
        height: size * 1.35,
        cacheHeight: targetCacheHeight,
        filterQuality: FilterQuality.medium,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                height: size,
                cacheHeight: targetCacheHeight,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.ribbonGradient,
                    ),
                    child: const Center(
                      child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VISTAR',
                    style: TextStyle(
                      color: AppColors.txt,
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    'LOGITEK',
                    style: TextStyle(
                      color: AppColors.pink,
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    return Image.asset(
      'assets/logo.png',
      height: size,
      cacheHeight: targetCacheHeight,
      filterQuality: FilterQuality.medium,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.ribbonGradient,
          ),
          child: const Center(
            child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        );
      },
    );
  }
}
