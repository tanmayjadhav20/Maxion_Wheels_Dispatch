import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_tokens.dart';

enum AppButtonVariant { gradient, ghost, danger, secondary }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.gradient,
    bool? isLoading,
    bool? isFullWidth,
  })  : isLoading = isLoading ?? false,
        isFullWidth = isFullWidth ?? false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Decoration decoration;
    Color textColor = isDark ? AppColors.txt : const Color(0xFF0F172A);

    switch (variant) {
      case AppButtonVariant.gradient:
        decoration = BoxDecoration(
          gradient: AppColors.ribbonGradient,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55E0218A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
        textColor = Colors.white;
        break;

      case AppButtonVariant.ghost:
      case AppButtonVariant.secondary:
        decoration = BoxDecoration(
          color: isDark ? AppColors.surface2 : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(color: isDark ? AppColors.line : const Color(0xFFCBD5E1)),
        );
        textColor = isDark ? AppColors.txt : const Color(0xFF0F172A);
        break;

      case AppButtonVariant.danger:
        decoration = BoxDecoration(
          color: isDark ? AppColors.dangerTint : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(
            color: isDark ? AppColors.danger.withValues(alpha: 0.4) : const Color(0xFFFCA5A5),
          ),
        );
        textColor = isDark ? AppColors.danger : const Color(0xFFDC2626);
        break;
    }

    final bool loading = isLoading;
    final bool fullWidth = isFullWidth;

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.gradient ? Colors.white : textColor,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: textColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(AppTokens.rSm),
      child: Container(
        padding: AppTokens.pButton,
        decoration: decoration,
        child: content,
      ),
    );
  }
}
