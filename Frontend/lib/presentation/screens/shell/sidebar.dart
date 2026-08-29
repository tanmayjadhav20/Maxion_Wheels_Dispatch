import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/router/nav_items.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/vistar_logo.dart';

/// The 248px sidebar: brand row, grouped nav with uppercase group labels, and
/// the user block footer.
///
/// The active item takes a soft ribbon tint plus a 3px ribbon left bar — the
/// design system's `.nav.on` treatment.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.vistar;
    final user = ref.watch(authProvider).user;

    final accessibleItems =
        navItems.where((item) => user == null || item.canAccess(user)).toList();

    final groupedItems = <String, List<NavItem>>{};
    for (final item in accessibleItems) {
      groupedItems.putIfAbsent(item.group, () => []).add(item);
    }

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(right: BorderSide(color: p.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row: S glyph + wordmark + tiny caption
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VistarWordmark(height: 30),
                const SizedBox(height: 8),
                Text(
                  'DISPATCH OPERATIONS DIGITALIZATION',
                  style: TextStyle(
                    color: p.txt3,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.line),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final entry in groupedItems.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: TextStyle(
                        color: p.txt3,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  for (final item in entry.value)
                    _NavRow(
                      item: item,
                      isActive: currentPath == item.path,
                      onTap: () {
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.of(context).pop();
                        }
                        context.go(item.path);
                      },
                    ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          Divider(height: 1, color: p.line),
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.ribbonGradient,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.txt,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.role.name.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.txt3,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: p.txt3, size: 18),
                    tooltip: 'Sign out',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavRow extends StatefulWidget {
  const _NavRow({required this.item, required this.isActive, required this.onTap});

  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;
    final active = widget.isActive;

    final Color fg = active ? p.txt : (_hovered ? p.txt : p.txt2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppTokens.animFast,
            decoration: BoxDecoration(
              // Soft ribbon tint on the active row, a plain surface lift on hover.
              color: active
                  ? p.brandTint
                  : (_hovered ? p.surface2 : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (active)
                  Positioned(
                    left: 0,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: AppColors.ribbonVertical,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        widget.item.icon,
                        size: 17,
                        color: active ? p.brandInk : fg,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.item.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 12.5,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.item.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.brandTint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: p.brandInk.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            widget.item.badge!,
                            style: TextStyle(
                              color: p.brandInk,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
