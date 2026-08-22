import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class PaintPlanScreen extends StatefulWidget {
  const PaintPlanScreen({super.key});

  @override
  State<PaintPlanScreen> createState() => _PaintPlanScreenState();
}

class _PaintPlanScreenState extends State<PaintPlanScreen> {
  final _itemController = TextEditingController(text: 'MXW-17-BLK');
  final _qtyController = TextEditingController(text: '960');

  bool _isLoading = false;
  String _shift = 'A';
  String _line = 'PL1';

  final List<Map<String, dynamic>> _plans = [
    {'planNumber': 'PLN26081101', 'line': 'PL1', 'shift': 'A', 'itemCode': 'MXW-17-BLK', 'plannedQty': 960, 'packedQty': 960, 'status': 'COMPLETED'},
    {'planNumber': 'PLN26081102', 'line': 'PL1', 'shift': 'B', 'itemCode': 'MXW-18-SLV', 'plannedQty': 800, 'packedQty': 800, 'status': 'COMPLETED'},
    {'planNumber': 'PLN26081103', 'line': 'PL2', 'shift': 'A', 'itemCode': 'MXW-17-BLK', 'plannedQty': 960, 'packedQty': 672, 'status': 'RUNNING'},
    {'planNumber': 'PLN26081104', 'line': 'PL2', 'shift': 'B', 'itemCode': 'MXW-19-CHR', 'plannedQty': 640, 'packedQty': 0, 'status': 'SCHEDULED'},
  ];

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _onReleasePlan() {
    final item = _itemController.text.trim();
    final qtyStr = _qtyController.text.trim();

    if (item.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Item Code and Planned Quantity'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final planNo = 'PLN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
          _plans.insert(0, {
            'planNumber': planNo,
            'line': _line,
            'shift': _shift,
            'itemCode': item,
            'plannedQty': int.tryParse(qtyStr) ?? 960,
            'packedQty': 0,
            'status': 'RELEASED',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Paint Line Production Plan released to shop floor!'), backgroundColor: AppColors.ok),
        );
      }
    });
  }

  void _onPrintSticker() {
    final item = _itemController.text.trim();
    PrintPreviewDialog.show(
      context: context,
      title: 'PAINT PRODUCTION RELEASE STICKER PREVIEW',
      documentType: PrintDocumentType.palletMaster,
      qrData: 'PLAN|PLN26081103|$item|$_shift',
      codeText: 'PLAN|PLN26081103|$item|$_shift',
      itemCode: item,
      itemDescription: 'Paint Line Release Run Sheet',
      primaryDetail: 'Paint Line: $_line · Shift $_shift',
      secondaryDetail: 'Planned Qty: ${_qtyController.text} Wheels',
      metadataFields: [
        {'ITEM CODE': item},
        {'LINE / SHIFT': '$_line / Shift $_shift'},
        {'PLANNED QTY': '${_qtyController.text} Wheels'},
      ],
    );
  }

  void _onExportPlansExcel() {
    exportToExcel(
      context,
      'Paint Line Production Plans',
      ['PLAN #', 'LINE / SHIFT', 'ITEM CODE', 'PLANNED QTY', 'PACKED QTY', 'STATUS'],
      _plans.map((p) => [
        p['planNumber'] as String,
        '${p['line']} · Shift ${p['shift']}',
        p['itemCode'] as String,
        '${p['plannedQty']} wheels',
        '${p['packedQty']} wheels',
        p['status'] as String,
      ]).toList(),
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

          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              final formCard = AppCard(
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
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isDesktop ? 180 : double.infinity,
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
                        SizedBox(
                          width: isDesktop ? 180 : double.infinity,
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AppButton(
                          text: 'RELEASE PLAN TO SHOP FLOOR',
                          icon: Icons.rocket_launch,
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: _onReleasePlan,
                        ),
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
              );

              final planTableCard = AppCard(
                showGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LIVE PAINT PRODUCTION PLANS MONITORING',
                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        AppButton(
                          text: 'EXPORT PLANS EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onExportPlansExcel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('PLAN #')),
                          DataColumn(label: Text('LINE / SHIFT')),
                          DataColumn(label: Text('ITEM CODE')),
                          DataColumn(label: Text('PLANNED')),
                          DataColumn(label: Text('PACKED')),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: _plans.map((p) {
                          final isCurrent = p['planNumber'] == 'PLN26081103';
                          final planned = p['plannedQty'] as int;
                          final packed = p['packedQty'] as int;

                          return DataRow(
                            selected: isCurrent,
                            cells: [
                              DataCell(Text(p['planNumber'] as String, style: TextStyle(fontWeight: FontWeight.w800, color: isCurrent ? AppColors.pink : context.textPrimary))),
                              DataCell(Text('${p['line']} · Shift ${p['shift']}')),
                              DataCell(Text(p['itemCode'] as String, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text('$planned wheels')),
                              DataCell(Text('$packed wheels', style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w700))),
                              DataCell(StatusPill(
                                label: p['status'] as String,
                                variant: p['status'] == 'RUNNING' ? PillVariant.purple : PillVariant.ok,
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: formCard),
                    const SizedBox(width: 24),
                    Expanded(flex: 7, child: planTableCard),
                  ],
                );
              }

              return Column(
                children: [
                  formCard,
                  const SizedBox(height: 24),
                  planTableCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
