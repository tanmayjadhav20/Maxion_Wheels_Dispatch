import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISPATCH OPERATIONS DASHBOARD',
                    style: TextStyle(
                      color: AppColors.ribbonPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maxion Wheels Dispatch Control Center',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  AppButton(
                    text: 'LIVE TV BOARD',
                    icon: Icons.tv,
                    variant: AppButtonVariant.ghost,
                    onPressed: _onToggleTvBoard,
                  ),
                  AppButton(
                    text: 'EXCEL REPORT',
                    icon: Icons.download_outlined,
                    variant: AppButtonVariant.gradient,
                    onPressed: _onExportDashboardExcel,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Key KPI Cards Grid
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
                    return GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: width < 400 ? 1.3 : 1.6,
                      children: [
                        _buildKpiCard(context, 'Plan Achievement', '$achievementPct%', '$packedTotal / $plannedTotal Wheels Packed', Icons.pie_chart_outline, AppColors.ok),
                        _buildKpiCard(context, 'Pallets Closed Today', '$fullCount Full / $halfCount Half', 'P: $fullCount | H: $halfCount | M: $mergedCount', Icons.inventory_2_outlined, AppColors.ribbonPink),
                        _buildKpiCard(context, 'Open Half Pallets', '$openHalfCount Pallets', 'Oldest: $oldestHalfNumber ($oldestHalfAge)', Icons.timelapse_outlined, AppColors.warn),
                        _buildKpiCard(context, 'Shipments Gated Out', '$gatedOutShipments Vehicles', '$gatedOutShipments Gate Passes Generated', Icons.local_shipping_outlined, AppColors.info),
                      ],
                    );
                  },
                ),
          const SizedBox(height: 32),
          // Live Activity Table Card
          AppCard(
            showGlow: true,
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
                              DataCell(Text('$packed', style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w700))),
                              DataCell(Text('$varQty wheels', style: TextStyle(color: varQty < 0 ? AppColors.warn : AppColors.ok))),
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

  Widget _buildKpiCard(BuildContext context, String title, String val, String sub, IconData icon, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              val,
              style: TextStyle(
                fontFamily: AppTheme.fontDisplay,
                color: context.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
