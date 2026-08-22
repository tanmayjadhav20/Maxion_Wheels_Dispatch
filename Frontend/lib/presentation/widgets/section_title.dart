import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return Row(
      children: [
        Container(
          width: 5,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.ribbonGradient,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
