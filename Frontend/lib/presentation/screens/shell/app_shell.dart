import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/theme/vistar_backdrop.dart';
import 'sidebar.dart';
import 'topbar.dart';

/// The app shell: 248px sidebar, 64px blurred topbar, and a scrollable canvas
/// sitting on the Vistar ambient ground.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final p = context.vistar;

    // Each screen mounts with the design system's `fade` entry — 10px rise into
    // place — keyed on the route so it replays on every navigation.
    final canvas = VistarBackdrop(
      child: AnimatedSwitcher(
        duration: AppTokens.animNormal,
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.022),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          alignment: Alignment.topLeft,
          children: [...previousChildren, if (currentChild != null) currentChild],
        ),
        child: KeyedSubtree(key: ValueKey(currentPath), child: child),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: p.bg,
            body: Row(
              children: [
                Sidebar(currentPath: currentPath),
                Expanded(
                  child: Column(
                    children: [
                      const Topbar(),
                      Expanded(child: canvas),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: p.bg,
          appBar: const Topbar(),
          drawer: Drawer(
            backgroundColor: p.bg,
            width: 264,
            shape: const RoundedRectangleBorder(),
            child: Sidebar(currentPath: currentPath),
          ),
          body: canvas,
        );
      },
    );
  }
}
