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
      color: isDark ? AppColors.bg : bgColor,
      child: Stack(
        children: [
          if (isDark) ...[
            // Glow 1: Top-Left Purple
            Positioned(
              left: -120,
              top: -120,
              width: 700,
              height: 600,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x387A1FB0), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Glow 2: Top-Right Pink
            Positioned(
              right: -100,
              top: 40,
              width: 600,
              height: 500,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x29E0218A), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Glow 3: Bottom-Right Orange
            Positioned(
              right: 40,
              bottom: -120,
              width: 700,
              height: 600,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x1FF06000), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Ambient Rotated Faint S Watermark
            Positioned(
              right: -80,
              top: 100,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: 0.07,
                  child: Opacity(
                    opacity: 0.04,
                    child: Image.asset(
                      'assets/logo.png',
                      width: 580,
                      height: 580,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
          child,
        ],
      ),
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
