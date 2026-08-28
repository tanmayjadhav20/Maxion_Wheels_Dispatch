import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showGlow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.showGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardBody = Container(
      padding: padding ?? AppTokens.cardPadding(context),
      child: child,
    );

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: isDark ? null : theme.cardColor,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xB316142A), Color(0xB3110F1E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        borderRadius: BorderRadius.circular(AppTokens.r),
        border: Border.all(
          color: showGlow
              ? AppColors.pink.withValues(alpha: 0.6)
              : (isDark ? AppColors.line : const Color(0xFFCBD5E1)),
        ),
        boxShadow: [
          if (showGlow)
            const BoxShadow(
              color: Color(0x33C018C0),
              blurRadius: 16,
              offset: Offset(0, 6),
            )
          else if (!isDark)
            const BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: cardBody,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r),
        child: cardContent,
      );
    }
    return cardContent;
  }
}
