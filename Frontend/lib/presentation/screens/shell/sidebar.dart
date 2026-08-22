import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/nav_items.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/vistar_logo.dart';

class Sidebar extends ConsumerWidget {
  final String currentPath;

  const Sidebar({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navActiveBg = isDark ? AppColors.surface2 : const Color(0xFFE2E8F0);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? (isDark ? AppColors.txt : const Color(0xFF0F172A));
    final textSecondary = isDark ? AppColors.txt2 : const Color(0xFF475569);
    final dividerColor = isDark ? AppColors.line : theme.dividerColor;

    // Filter accessible items
    final accessibleItems = navItems.where((item) {
      if (user == null) return true;
      return item.canAccess(user);
    }).toList();

    // Group items by category
    final Map<String, List<NavItem>> groupedItems = {};
    for (var item in accessibleItems) {
      groupedItems.putIfAbsent(item.group, () => []).add(item);
    }

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg : theme.cardColor,
        border: Border(right: BorderSide(color: dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Row with Tiny Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VistarLogo(size: 44),
                const SizedBox(height: 4),
                Text(
                  'DISPATCH OPERATIONS DIGITALIZATION',
                  style: TextStyle(
                    color: AppColors.txt3,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 8),
          // Grouped Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: groupedItems.entries.map((entry) {
                final groupTitle = entry.key;
                final items = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                      child: Text(
                        groupTitle,
                        style: const TextStyle(
                          color: AppColors.txt3,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    ...items.map((item) {
                      final isActive = currentPath == item.path;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: InkWell(
                          onTap: () => context.go(item.path),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? navActiveBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isActive
                                  ? const Border(
                                      left: BorderSide(color: AppColors.pink, width: 3),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 17,
                                  color: isActive ? AppColors.pink : textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: isActive ? textPrimary : textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (item.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.pink.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: const TextStyle(
                                        color: AppColors.pink,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // User Block Footer
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
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
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
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.role.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.txt3,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.txt3, size: 18),
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
