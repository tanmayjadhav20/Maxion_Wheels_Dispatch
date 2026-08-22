import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

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
                        child: Container(
                          color: bgColor,
                          child: child,
                        ),
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
          body: child,
        );
      },
    );
  }
}
