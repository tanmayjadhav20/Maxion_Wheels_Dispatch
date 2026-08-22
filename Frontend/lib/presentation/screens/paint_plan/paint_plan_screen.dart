import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class PaintPlanScreen extends ConsumerStatefulWidget {
  const PaintPlanScreen({super.key});

  @override
  ConsumerState<PaintPlanScreen> createState() => _PaintPlanScreenState();
}

class _PaintPlanScreenState extends ConsumerState<PaintPlanScreen> {
  final _itemController = TextEditingController(text: 'MXW-17-BLK');
  final _qtyController = TextEditingController(text: '384');
  String _shift = 'A';
  String _line = 'PL2';

  List<dynamic>? _summaryList = [];
  List<dynamic> get summaryList => _summaryList ?? [];
  String _planNumber = 'PLN26081103';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPaintPlan();
  }

  Future<void> _fetchPaintPlan() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/paint-plan/plan-vs-actual');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _planNumber = res['planNumber'] ?? 'PLN26081103';
        _summaryList = (res['summary'] as List<dynamic>?) ?? [];
      });
    }
  }

  Future<void> _onReleasePlan() async {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 384;
    final itemCode = _itemController.text.trim();

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/paint-plan', {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'shift': _shift,
      'line': _line,
      'items': [
        {'itemCode': itemCode, 'plannedQty': qty}
      ]
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Paint plan released live to shop floor!'),
        ),
      );
      _fetchPaintPlan();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(res['message'] ?? 'Failed to release paint plan'),
        ),
      );
    }
  }

  void _onExportExcel() {
    exportToExcel(
      context,
      'Paint Plan $_planNumber',
      ['ITEM CODE', 'PLANNED QTY', 'ACTUAL PACKED', 'VARIANCE', 'COMPLETION %'],
      summaryList.map<List<String>>((s) => [
        '${s['itemCode']}',
        '${s['plannedQty']}',
        '${s['packedQty']}',
        '${s['varianceQty']}',
        '${s['completionPercentage']}%',
      ]).toList(),
    );
  }

  void _onPrintSticker() {
    final itemCode = _itemController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 384;

    PrintPreviewDialog.show(
      context: context,
      title: 'PAINT LINE RELEASE ORDER STICKER PRINT PREVIEW',
      documentType: PrintDocumentType.jobCardSummary,
      qrData: 'PLAN|$_planNumber|$itemCode|$qty',
      codeText: 'PLAN|$_planNumber|$itemCode|$qty',
      itemCode: itemCode,
      itemDescription: 'Paint Schedule Authorization Ticket - Shift $_shift',
      primaryDetail: 'Planned Qty: $qty wheels • Line: $_line',
      secondaryDetail: 'Authorized By: Standard User',
      metadataFields: [
        {'PLAN #': _planNumber},
        {'SHIFT': _shift},
        {'LINE': _line},
        {'DATE': DateTime.now().toIso8601String().split('T')[0]},
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 1 — Paint Line Production Plan (SSR Section 3)'),
          const SizedBox(height: 8),
          Text(
            'Paint line plan is released in wheels per shift per line. System automatically calculates pallet quantities (std qty 96 for 17", 80 for 18").',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Create / Edit Plan Form
              Expanded(
                flex: 5,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RELEASE NEW PAINT LINE SCHEDULE',
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _itemController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Wheel Item Code (e.g. MXW-17-BLK)',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Planned Production Quantity (Wheels)',
                          suffixText: 'wheels',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _shift,
                              dropdownColor: context.bgSurfaceElevated,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Shift',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'A', child: Text('Shift A (06:00 - 14:00)')),
                                DropdownMenuItem(value: 'B', child: Text('Shift B (14:00 - 22:00)')),
                                DropdownMenuItem(value: 'C', child: Text('Shift C (22:00 - 06:00)')),
                              ],
                              onChanged: (val) => setState(() => _shift = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _line,
                              dropdownColor: context.bgSurfaceElevated,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Paint Line',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'PL1', child: Text('Paint Line 1 (PL1)')),
                                DropdownMenuItem(value: 'PL2', child: Text('Paint Line 2 (PL2)')),
                              ],
                              onChanged: (val) => setState(() => _line = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'RELEASE PLAN TO SHOP FLOOR',
                              icon: Icons.rocket_launch,
                              variant: AppButtonVariant.gradient,
                              isLoading: _isLoading,
                              onPressed: _onReleasePlan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            text: 'PRINT RELEASE STICKER',
                            icon: Icons.print_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: _onPrintSticker,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right Panel: Dynamic Live Plan vs Actual Monitoring Table
              Expanded(
                flex: 7,
                child: AppCard(
                  showGlow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIVE PLAN VS ACTUAL — SHIFT $_shift',
                                style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text('Plan Ref: $_planNumber', style: TextStyle(color: context.textMuted, fontSize: 12)),
                            ],
                          ),
                          AppButton(
                            text: 'EXPORT EXCEL',
                            icon: Icons.table_chart_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: _onExportExcel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.ribbonPink))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ITEM CODE')),
                                  DataColumn(label: Text('PLANNED QTY')),
                                  DataColumn(label: Text('ACTUAL PACKED')),
                                  DataColumn(label: Text('VARIANCE')),
                                  DataColumn(label: Text('COMPLETION %')),
                                ],
                                rows: summaryList.map((s) {
                                  final planned = s['plannedQty'] ?? 0;
                                  final packed = s['packedQty'] ?? 0;
                                  final varQty = s['varianceQty'] ?? (packed - planned);
                                  final pct = s['completionPercentage'] ?? '0.0';

                                  return DataRow(cells: [
                                    DataCell(Text(s['itemCode'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                                    DataCell(Text('$planned wheels')),
                                    DataCell(Text('$packed wheels', style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w700))),
                                    DataCell(Text('$varQty wheels', style: TextStyle(color: varQty < 0 ? AppColors.warn : AppColors.ok))),
                                    DataCell(Text('$pct%')),
                                  ]);
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
