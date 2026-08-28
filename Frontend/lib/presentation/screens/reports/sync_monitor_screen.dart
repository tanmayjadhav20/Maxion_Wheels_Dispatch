import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/network/sync_engine.dart';
import '../../../core/utils/export_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class SyncMonitorScreen extends ConsumerWidget {
  const SyncMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Section 7 — IT Background Sync Monitor & Device Health'),
          const SizedBox(height: 8),
          Text(
            'Monitor floor handheld scanning guns, pending sync queue count, and server sync heartbeat.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Control & Simulation Card
          AppCard(
            showGlow: true,
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                final isNarrow = cardConstraints.maxWidth < 700;

                final infoCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEVICE LOCAL SYNC STATUS',
                      style: TextStyle(color: AppColors.ribbonPink, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      syncState.isOnline ? 'Online (Connected to Plant Server)' : 'Offline (Local SQLite Cache Active)',
                      style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                );

                final btn1 = AppButton(
                  text: syncState.isOnline ? 'SIMULATE NETWORK DROP (OFFLINE)' : 'SIMULATE RESTORE',
                  icon: syncState.isOnline ? Icons.wifi_off : Icons.wifi,
                  variant: syncState.isOnline ? AppButtonVariant.danger : AppButtonVariant.gradient,
                  onPressed: () {
                    ref.read(syncProvider.notifier).toggleOnlineStatus(!syncState.isOnline);
                  },
                );

                final btn2 = AppButton(
                  text: 'FORCE SYNC NOW',
                  icon: Icons.sync,
                  variant: AppButtonVariant.ghost,
                  onPressed: () {
                    ref.read(syncProvider.notifier).triggerSync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.ok,
                        content: Text('Two-way sync completed successfully!'),
                      ),
                    );
                  },
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoCol,
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [btn1, btn2],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoCol,
                    Row(
                      children: [
                        btn1,
                        const SizedBox(width: 12),
                        btn2,
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Handheld Devices Table
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'HANDHELD GUN DEVICES ON SHOP FLOOR',
                      style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    AppButton(
                      text: 'EXPORT SYNC LOG EXCEL',
                      icon: Icons.table_chart_outlined,
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        exportToExcel(
                          context,
                          'HHT Devices Background Sync Log',
                          ['DEVICE ID', 'WORK POINT', 'OPERATOR', 'PENDING QUEUE', 'LAST SYNC TIME', 'HEALTH'],
                          [
                            ['HH-GUN-01', 'Pack Point #1', 'Ramesh', '${syncState.pendingCount} scans', '10 seconds ago', 'HEALTHY'],
                            ['HH-GUN-02', 'Putaway Forklift', 'Suresh', '0 transactions', '2 mins ago', 'HEALTHY'],
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('DEVICE ID')),
                      DataColumn(label: Text('WORK POINT')),
                      DataColumn(label: Text('OPERATOR')),
                      DataColumn(label: Text('PENDING QUEUE')),
                      DataColumn(label: Text('LAST SYNC TIME')),
                      DataColumn(label: Text('HEALTH')),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text('HH-GUN-01', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                        const DataCell(Text('Pack Point #1')),
                        const DataCell(Text('Ramesh')),
                        DataCell(Text('${syncState.pendingCount} scans')),
                        const DataCell(Text('10 seconds ago')),
                        const DataCell(StatusPill(label: 'HEALTHY', variant: PillVariant.ok)),
                      ]),
                      DataRow(cells: [
                        DataCell(Text('HH-GUN-02', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                        const DataCell(Text('Putaway Forklift')),
                        const DataCell(Text('Suresh')),
                        const DataCell(Text('0 transactions')),
                        const DataCell(Text('2 mins ago')),
                        const DataCell(StatusPill(label: 'HEALTHY', variant: PillVariant.ok)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
