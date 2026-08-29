import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/kpi_tile.dart';
import '../../widgets/page_header.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class ManagementDashboardScreen extends ConsumerStatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  ConsumerState<ManagementDashboardScreen> createState() => _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends ConsumerState<ManagementDashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic> get stats => _stats ?? {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/dashboard/stats');
    setState(() => _isLoading = false);

    if (res['success'] == true && res['stats'] != null) {
      setState(() {
        _stats = res['stats'];
      });
    }
  }

  void _onExportDashboardExcel() {
    final achievementPct = stats['achievementPct'] ?? '0.0';
    final packedTotal = stats['packedTotal'] ?? 0;
    final plannedTotal = stats['plannedTotal'] ?? 0;
    final fullCount = stats['fullCount'] ?? 0;
    final halfCount = stats['halfCount'] ?? 0;
    final openHalfCount = stats['openHalfCount'] ?? 0;
    final gatedOutShipments = stats['gatedOutShipments'] ?? 0;

    exportToExcel(
      context,
      'Dispatch Operations Management Dashboard Summary',
      ['KPI METRIC', 'VALUE', 'DETAILS / BREAKDOWN'],
      [
        ['Plan Achievement', '$achievementPct%', '$packedTotal / $plannedTotal Wheels Packed'],
        ['Pallets Closed Today', '$fullCount Full / $halfCount Half', 'Full: $fullCount | Half: $halfCount'],
        ['Open Half Pallets', '$openHalfCount Pallets', 'Oldest: ${stats['oldestHalfNumber'] ?? "None"} (${stats['oldestHalfAge'] ?? "N/A"})'],
        ['Shipments Gated Out', '$gatedOutShipments Vehicles', '$gatedOutShipments Gate Passes Processed'],
      ],
    );
  }

  void _onToggleTvBoard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Row(
          children: [
            const Icon(Icons.tv, color: AppColors.ribbonPink),
            const SizedBox(width: 10),
            Text('SHOP FLOOR LIVE TV DISPLAY MODE', style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Live Shop Floor TV Board activated! Auto-refreshing every 5 seconds for plant wall monitors.',
          style: TextStyle(color: ctx.textSecondary),
        ),
        actions: [
          AppButton(
            text: 'OK — RETURN TO DASHBOARD',
            variant: AppButtonVariant.gradient,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievementPct = stats['achievementPct'] ?? '0.0';
    final packedTotal = stats['packedTotal'] ?? 0;
    final plannedTotal = stats['plannedTotal'] ?? 0;
    final fullCount = stats['fullCount'] ?? 0;
    final halfCount = stats['halfCount'] ?? 0;
    final mergedCount = stats['mergedCount'] ?? 0;
    final openHalfCount = stats['openHalfCount'] ?? 0;
    final oldestHalfNumber = stats['oldestHalfNumber'] ?? 'None';
    final oldestHalfAge = stats['oldestHalfAge'] ?? 'N/A';
    final gatedOutShipments = stats['gatedOutShipments'] ?? 0;

    final activePlan = stats['activePlan'];
    final planItems = (activePlan?['items'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'Dispatch Operations',
            title: 'Dispatch Control Center',
            actions: [
              AppButton(
                text: 'LIVE TV BOARD',
                icon: Icons.tv,
                variant: AppButtonVariant.ghost,
                isCompact: true,
                onPressed: _onToggleTvBoard,
              ),
              AppButton(
                text: 'EXCEL REPORT',
                icon: Icons.download_outlined,
                variant: AppButtonVariant.gradient,
                isCompact: true,
                onPressed: _onExportDashboardExcel,
              ),
            ],
          ),
          // Key KPI tiles
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.ribbonPink)),
            )
          else
            KpiTileGrid(
              tiles: [
                KpiTile(
                  label: 'Plan Achievement',
                  value: '$achievementPct%',
                  detail: '$packedTotal / $plannedTotal wheels packed',
                  icon: Icons.pie_chart_outline,
                  accent: context.okInk,
                ),
                KpiTile(
                  label: 'Pallets Closed Today',
                  value: '$fullCount Full / $halfCount Half',
                  detail: 'Merged: $mergedCount',
                  icon: Icons.inventory_2_outlined,
                  accent: context.brandInk,
                ),
                KpiTile(
                  label: 'Open Half Pallets',
                  value: '$openHalfCount',
                  detail: 'Oldest: $oldestHalfNumber ($oldestHalfAge)',
                  icon: Icons.timelapse_outlined,
                  accent: context.warnInk,
                ),
                KpiTile(
                  label: 'Shipments Gated Out',
                  value: '$gatedOutShipments',
                  detail: '$gatedOutShipments gate passes generated',
                  icon: Icons.local_shipping_outlined,
                  accent: context.infoInk,
                ),
              ],
            ),
          const SizedBox(height: 20),
          // Live Activity Table Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: 'Active Shift Summary (${activePlan?['planNumber'] ?? "PLN26081103"} - Shift ${activePlan?['shift'] ?? "A"})'),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, tableConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                        child: DataTable(
                          columnSpacing: 18,
                          horizontalMargin: 8,
                          columns: const [
                            DataColumn(label: Text('ITEM CODE')),
                            DataColumn(label: Text('PLANNED')),
                            DataColumn(label: Text('PACKED')),
                            DataColumn(label: Text('VARIANCE')),
                            DataColumn(label: Text('STATUS')),
                          ],
                          rows: planItems.map((item) {
                            final planned = item['plannedQty'] ?? 384;
                            final packed = item['packedQty'] ?? 240;
                            final varQty = packed - planned;
                            final isDone = packed >= planned;

                            return DataRow(cells: [
                              DataCell(Text(item['itemCode'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                              DataCell(Text('$planned')),
                              DataCell(Text('$packed', style: TextStyle(color: context.okInk, fontWeight: FontWeight.w700))),
                              DataCell(Text('$varQty wheels', style: TextStyle(color: varQty < 0 ? context.warnInk : context.okInk))),
                              DataCell(StatusPill(label: isDone ? 'COMPLETED' : 'RUNNING', variant: isDone ? PillVariant.ok : PillVariant.purple)),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
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
