import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Standard screen header: a small brand eyebrow, the page title, an optional
/// one-line description, and right-aligned actions.
///
/// Every screen rolled its own header at a different size, which is a large
/// part of why the app reads as busy. This keeps one compact, predictable
/// block so the eye lands in the same place on every screen.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.actions = const [],
  });

  final String title;

  /// Short uppercase kicker above the title.
  final String? eyebrow;

  /// One line of context. Keep it to a sentence — anything longer belongs in
  /// the screen body, not the header.
  final String? description;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: p.brandInk,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.display(p.txt, size: 19, height: 1.15),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.txt2, fontSize: 12, height: 1.4),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Below this the title and a row of buttons cannot share a line
          // without the title truncating to nothing.
          final stacked = constraints.maxWidth < 620;

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: text),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 16),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          );
        },
      ),
    );
  }
}
