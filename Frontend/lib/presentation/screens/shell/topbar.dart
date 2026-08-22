import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/network/sync_engine.dart';
import '../../../domain/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/pills.dart';

class Topbar extends ConsumerWidget implements PreferredSizeWidget {
  const Topbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = authState.user;

    final roles = [
      {'code': 'superAdmin', 'label': 'Admin', 'emp': 'EMP001', 'pin': '1234'},
      {'code': 'packOperator', 'label': 'Pack Op', 'emp': 'EMP002', 'pin': '1111'},
      {'code': 'warehouseManager', 'label': 'WH Manager', 'emp': 'EMP003', 'pin': '2222'},
      {'code': 'picker', 'label': 'HHT Operator', 'emp': 'EMP005', 'pin': '4444'},
      {'code': 'security', 'label': 'Security', 'emp': 'EMP004', 'pin': '3333'},
    ];

    String currentRoleCode = 'superAdmin';
    if (user != null) {
      if (user.role == UserRole.picker) {
        currentRoleCode = 'picker';
      } else if (user.role == UserRole.packOperator) {
        currentRoleCode = 'packOperator';
      } else if (user.role == UserRole.warehouseManager) {
        currentRoleCode = 'warehouseManager';
      } else if (user.role == UserRole.security) {
        currentRoleCode = 'security';
      } else {
        currentRoleCode = 'superAdmin';
      }
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg : Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.line : Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
          // Document ID pill
          const StatusPill(
            label: AppTokens.documentId,
            variant: PillVariant.purple,
          ),
          const SizedBox(width: 16),
          // Search box
          Expanded(
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Scan or search Wheel QR / Pallet QR / Location...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  fillColor: isDark ? AppColors.surface2 : const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: isDark ? AppColors.line : Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Sync indicator
          StatusPill(
            label: syncState.isOnline
                ? (syncState.pendingCount == 0 ? 'ONLINE · SYNCED' : 'ONLINE · PENDING ${syncState.pendingCount}')
                : 'OFFLINE MODE',
            variant: syncState.isOnline
                ? (syncState.pendingCount == 0 ? PillVariant.ok : PillVariant.warn)
                : PillVariant.danger,
          ),
          const SizedBox(width: 12),
          // View As Role Switcher (Vistar Design Spec)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.line : Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.supervisor_account, size: 16, color: AppColors.pink),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentRoleCode,
                    isDense: true,
                    dropdownColor: isDark ? AppColors.surface2 : Colors.white,
                    style: TextStyle(
                      color: isDark ? AppColors.txt : const Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: roles.map((r) {
                      return DropdownMenuItem<String>(
                        value: r['code'],
                        child: Text('View as: ${r['label']}'),
                      );
                    }).toList(),
                    onChanged: (newCode) async {
                      if (newCode != null) {
                        final r = roles.firstWhere((element) => element['code'] == newCode);
                        final ok = await ref.read(authProvider.notifier).login(
                          employeeCode: r['emp']!,
                          pin: r['pin']!,
                        );
                        if (ok && context.mounted) {
                          if (newCode == 'picker') {
                            context.go('/hht-picking');
                          } else if (newCode == 'packOperator') {
                            context.go('/pack-point');
                          } else if (newCode == 'warehouseManager') {
                            context.go('/warehouse');
                          } else if (newCode == 'security') {
                            context.go('/dispatch');
                          } else {
                            context.go('/dashboard');
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Light / Dark Theme Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
              color: isDark ? AppColors.amber : AppColors.pink,
              size: 20,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SizedBox(width: 8),
          // User Badge Avatar
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface2 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.line : Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppColors.ribbonGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    );
  }
}
