import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'sidebar.dart';
import 'topbar.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    Widget ambientCanvas = Container(
      decoration: isDark
          ? const BoxDecoration(
              color: AppColors.bg,
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.85),
                radius: 1.1,
                colors: [
                  Color(0x2E7A1FB0), // rgba(122,31,176,.18)
                  Colors.transparent,
                ],
                stops: [0.0, 0.65],
              ),
            )
          : BoxDecoration(color: bgColor),
      child: child,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Row(
              children: [
                Sidebar(currentPath: currentPath),
                Expanded(
                  child: Column(
                    children: [
                      const Topbar(),
                      Expanded(
                        child: ambientCanvas,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout with Drawer
        return Scaffold(
          backgroundColor: bgColor,
          appBar: const Topbar(),
          drawer: Drawer(
            child: Sidebar(currentPath: currentPath),
          ),
          body: ambientCanvas,
        );
      },
    );
  }
}
