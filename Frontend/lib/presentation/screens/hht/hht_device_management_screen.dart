import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class HhtDeviceManagementScreen extends ConsumerStatefulWidget {
  const HhtDeviceManagementScreen({super.key});

  @override
  ConsumerState<HhtDeviceManagementScreen> createState() => _HhtDeviceManagementScreenState();
}

class _HhtDeviceManagementScreenState extends ConsumerState<HhtDeviceManagementScreen> {
  List<dynamic>? _devices = [];
  List<dynamic> get devices => _devices ?? [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHhtDevices();
  }

  Future<void> _fetchHhtDevices() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/hht/devices');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _devices = (res['devices'] as List<dynamic>?) ?? [];
      });
    }
  }

  void _onExportHhtRegister() {
    exportToExcel(
      context,
      'HHT Scanner Guns Register & Battery Status',
      ['DEVICE ID', 'DEVICE NAME', 'ROLE ALLOCATION', 'ASSIGNED OPERATOR', 'LOCATION', 'BATTERY %', 'STATUS'],
      devices.map<List<String>>((d) => [
        '${d['deviceId']}',
        '${d['name']}',
        '${d['roleCategory']}',
        '${d['assignedUser']}',
        '${d['location']}',
        '${d['batteryLevel']}%',
        '${d['status']}',
      ]).toList(),
    );
  }

  void _onReassignGun(dynamic device) {
    final nameController = TextEditingController(text: device['assignedUser']);
    String selectedRole = device['roleCategory'] ?? 'UNLOADING';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Configure ${device['name']}', style: TextStyle(color: ctx.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: ctx.textPrimary),
              decoration: InputDecoration(
                labelText: 'Assigned Operator Name',
                labelStyle: TextStyle(color: ctx.textMuted),
                filled: true,
                fillColor: ctx.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              isExpanded: true,
              dropdownColor: ctx.bgSurfaceElevated,
              style: TextStyle(color: ctx.textPrimary),
              decoration: InputDecoration(
                labelText: 'HHT Gun Role Allocation',
                labelStyle: TextStyle(color: ctx.textMuted),
                filled: true,
                fillColor: ctx.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'UNLOADING', child: Text('Unloading Gun (2 Required)')),
                DropdownMenuItem(value: 'LOADING', child: Text('Loading Gun (1 Required)')),
                DropdownMenuItem(value: 'MERGING_BINNING', child: Text('Merging / Binning Gun (1 Required)')),
              ],
              onChanged: (val) => selectedRole = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          AppButton(
            text: 'SAVE GUN ALLOCATION',
            variant: AppButtonVariant.gradient,
            onPressed: () async {
              Navigator.pop(ctx);
              final remoteApi = ref.read(remoteApiProvider);
              await remoteApi.post('/hht/assign-role', {
                'deviceId': device['deviceId'],
                'assignedUser': nameController.text.trim(),
                'roleCategory': selectedRole,
              });
              _fetchHhtDevices();
            },
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'UNLOADING':
        return AppColors.ok;
      case 'LOADING':
        return AppColors.ribbonPink;
      case 'MERGING_BINNING':
        return AppColors.warn;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktopHeader = constraints.maxWidth > 750;

              if (isDesktopHeader) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: 'Handheld Devices (HHT) Gun Allocation & Management'),
                          const SizedBox(height: 8),
                          Text(
                            'Live monitoring & role allocation for the 4 required HHT scanner guns (Unloading: 2, Loading: 1, Merging/Binning: 1).',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'EXPORT HHT REGISTER EXCEL',
                      icon: Icons.table_chart_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: _onExportHhtRegister,
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Handheld Devices (HHT) Gun Allocation & Management'),
                  const SizedBox(height: 8),
                  Text(
                    'Live monitoring & role allocation for the 4 required HHT scanner guns (Unloading: 2, Loading: 1, Merging/Binning: 1).',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'EXPORT HHT REGISTER EXCEL',
                    icon: Icons.table_chart_outlined,
                    variant: AppButtonVariant.ghost,
                    onPressed: _onExportHhtRegister,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Top Summary Badges for the 4 Guns
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final isNarrow = cardConstraints.maxWidth < 600;

              final card1 = AppCard(
                child: Column(
                  children: [
                    Text('UNLOADING GUNS', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('2 / 2 ACTIVE', style: TextStyle(color: AppColors.ok, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              );

              final card2 = AppCard(
                child: Column(
                  children: [
                    Text('LOADING GUN', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('1 / 1 ACTIVE', style: TextStyle(color: AppColors.ribbonPink, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              );

              final card3 = AppCard(
                child: Column(
                  children: [
                    Text('MERGING / BINNING GUN', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('1 / 1 ACTIVE', style: TextStyle(color: AppColors.warn, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    card1,
                    const SizedBox(height: 12),
                    card2,
                    const SizedBox(height: 12),
                    card3,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 16),
                  Expanded(child: card2),
                  const SizedBox(width: 16),
                  Expanded(child: card3),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
          else
            Column(
              children: devices.map((device) {
                final role = device['roleCategory'] ?? 'UNLOADING';
                final battery = device['batteryLevel'] ?? 100;
                final roleColor = _getRoleColor(role);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    child: LayoutBuilder(
                      builder: (context, cardConstraints) {
                        final isMobile = cardConstraints.maxWidth < 620;

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.qr_code_scanner_outlined, color: roleColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      device['name'] ?? '',
                                      style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        battery > 50 ? Icons.battery_full : Icons.battery_alert,
                                        color: battery > 20 ? AppColors.ok : AppColors.danger,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('$battery%', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  StatusPill(
                                    label: role.replaceAll('_', ' '),
                                    variant: role == 'UNLOADING'
                                        ? PillVariant.ok
                                        : role == 'LOADING'
                                            ? PillVariant.purple
                                            : PillVariant.warn,
                                  ),
                                  Text(
                                    '${device['assignedUser']} • ${device['location']}',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              AppButton(
                                text: 'CONFIGURE ROLE',
                                isFullWidth: true,
                                variant: AppButtonVariant.gradient,
                                onPressed: () => _onReassignGun(device),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.qr_code_scanner_outlined, color: roleColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        device['name'] ?? '',
                                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                      StatusPill(
                                        label: role.replaceAll('_', ' '),
                                        variant: role == 'UNLOADING'
                                            ? PillVariant.ok
                                            : role == 'LOADING'
                                                ? PillVariant.purple
                                                : PillVariant.warn,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Assigned Operator: ${device['assignedUser']} • Location: ${device['location']}',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      battery > 50 ? Icons.battery_full : Icons.battery_alert,
                                      color: battery > 20 ? AppColors.ok : AppColors.danger,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('$battery%', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AppButton(
                                  text: 'CONFIGURE ROLE',
                                  variant: AppButtonVariant.gradient,
                                  onPressed: () => _onReassignGun(device),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
