import 'dart:ui';

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

/// The 64px blurred topbar: search, sync state, role switcher, theme control,
/// and the user chip.
class Topbar extends ConsumerWidget implements PreferredSizeWidget {
  const Topbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  static const List<Map<String, String>> _roles = [
    {'code': 'superAdmin', 'label': 'Super Admin', 'emp': 'EMP001', 'pin': '1234'},
    {'code': 'packOperator', 'label': 'Pack Operator', 'emp': 'EMP002', 'pin': '1111'},
    {'code': 'warehouseManager', 'label': 'Warehouse Manager', 'emp': 'EMP003', 'pin': '2222'},
    {'code': 'picker', 'label': 'HHT Operator', 'emp': 'EMP005', 'pin': '4444'},
    {'code': 'security', 'label': 'Security', 'emp': 'EMP004', 'pin': '3333'},
  ];

  static const Map<String, String> _landingByRole = {
    'picker': '/hht-picking',
    'packOperator': '/pack-point',
    'warehouseManager': '/warehouse',
    'security': '/dispatch',
    'superAdmin': '/dashboard',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.vistar;
    final syncState = ref.watch(syncProvider);
    final user = ref.watch(authProvider).user;

    String currentRoleCode = 'superAdmin';
    if (user != null) {
      currentRoleCode = switch (user.role) {
        UserRole.picker => 'picker',
        UserRole.packOperator => 'packOperator',
        UserRole.warehouseManager => 'warehouseManager',
        UserRole.security => 'security',
        _ => 'superAdmin',
      };
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.bg.withValues(alpha: 0.72),
            border: Border(bottom: BorderSide(color: p.line)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final showAvatar = width >= 850;
              final showSyncPill = width >= 1050;
              final showSearch = width >= 900;
              final showDocPill = width >= 650;

              return Row(
                children: [
                  if (Scaffold.maybeOf(context)?.hasDrawer ?? false) ...[
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Icon(Icons.menu, color: p.brandInk),
                        tooltip: 'Open navigation menu',
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (showDocPill) ...[
                    const StatusPill(
                      label: AppTokens.documentId,
                      variant: PillVariant.purple,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (showSearch) ...[
                    Expanded(
                      child: Container(
                        height: 38,
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: TextField(
                          style: TextStyle(color: p.txt, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Scan or search Wheel QR / Pallet QR...',
                            hintStyle: TextStyle(color: p.txt3, fontSize: 12.5),
                            prefixIcon: Icon(Icons.search, size: 18, color: p.txt3),
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: p.surface2,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: p.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const Spacer(),
                  if (showSyncPill) ...[
                    StatusPill(
                      label: syncState.isOnline
                          ? (syncState.pendingCount == 0
                              ? 'ONLINE · SYNCED'
                              : 'ONLINE · PENDING ${syncState.pendingCount}')
                          : 'OFFLINE MODE',
                      variant: syncState.isOnline
                          ? (syncState.pendingCount == 0 ? PillVariant.ok : PillVariant.warn)
                          : PillVariant.danger,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 145),
                      child: _RoleSwitcher(currentRoleCode: currentRoleCode),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const ThemeModeButton(),
                  if (user != null && showAvatar) ...[
                    const SizedBox(width: 4),
                    _UserChip(name: user.name),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleSwitcher extends ConsumerWidget {
  const _RoleSwitcher({required this.currentRoleCode});

  final String currentRoleCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.vistar;

    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.supervisor_account, size: 15, color: p.brandInk),
          const SizedBox(width: 4),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentRoleCode,
                isDense: true,
                isExpanded: true,
                dropdownColor: p.surface2,
                borderRadius: BorderRadius.circular(10),
                iconEnabledColor: p.txt3,
                style: TextStyle(
                  color: p.txt,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final r in Topbar._roles)
                    DropdownMenuItem<String>(
                      value: r['code'],
                      child: Text(r['label']!, overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                ],
                onChanged: (newCode) async {
                  if (newCode == null) return;
                  final r = Topbar._roles.firstWhere((e) => e['code'] == newCode);
                  final ok = await ref.read(authProvider.notifier).login(
                        employeeCode: r['emp']!,
                        pin: r['pin']!,
                      );
                  if (ok && context.mounted) {
                    context.go(Topbar._landingByRole[newCode] ?? '/dashboard');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Light / dark / system control.
///
/// A tap toggles between light and dark; the menu exposes "Follow system" so a
/// shop-floor HHT can track the device's own day/night setting.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.vistar;
    final mode = ref.watch(themeModeProvider);
    final isDark = p.isDark;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Appearance',
      position: PopupMenuPosition.under,
      onSelected: (m) => ref.read(themeModeProvider.notifier).setTheme(m),
      itemBuilder: (context) => [
        for (final entry in const {
          ThemeMode.light: ('Light', Icons.wb_sunny_outlined),
          ThemeMode.dark: ('Dark', Icons.nightlight_round_outlined),
          ThemeMode.system: ('Follow system', Icons.brightness_auto_outlined),
        }.entries)
          PopupMenuItem<ThemeMode>(
            value: entry.key,
            height: 40,
            child: Row(
              children: [
                Icon(
                  entry.value.$2,
                  size: 17,
                  color: mode == entry.key ? p.brandInk : p.txt2,
                ),
                const SizedBox(width: 10),
                Text(
                  entry.value.$1,
                  style: TextStyle(
                    color: mode == entry.key ? p.txt : p.txt2,
                    fontSize: 12.5,
                    fontWeight: mode == entry.key ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (mode == entry.key) ...[
                  const Spacer(),
                  Icon(Icons.check, size: 15, color: p.brandInk),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.line),
        ),
        alignment: Alignment.center,
        child: Icon(
          switch (mode) {
            ThemeMode.system => Icons.brightness_auto_outlined,
            ThemeMode.light => Icons.wb_sunny_outlined,
            ThemeMode.dark => Icons.nightlight_round_outlined,
          },
          size: 17,
          color: isDark ? AppColors.amber : p.brandInk,
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: AppColors.ribbonGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: p.txt,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
