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
    Decoration decoration;
    Color textColor = Colors.white;

    switch (variant) {
      case AppButtonVariant.gradient:
        decoration = BoxDecoration(
          gradient: AppColors.ribbonGradient,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66E0218A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        );
        break;
      case AppButtonVariant.ghost:
      case AppButtonVariant.secondary:
        decoration = BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(color: AppColors.line),
        );
        textColor = AppColors.textPrimary;
        break;
      case AppButtonVariant.danger:
        decoration = BoxDecoration(
          color: AppColors.dangerTint,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        );
        textColor = AppColors.danger;
        break;
    }

    final bool loading = isLoading;
    final bool fullWidth = isFullWidth;

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
