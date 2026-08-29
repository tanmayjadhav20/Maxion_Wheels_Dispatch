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
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController(text: '384');

  bool _isLoading = false;
  bool _isFetching = false;
  String _shift = 'A';
  String _line = 'PL1';

  List<dynamic> _halfPallets = [];
  bool _createNewPalletOption = false;
  bool _hasHalfMatch = false;
  Map<String, dynamic>? _matchedHalfPallet;

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _masterItems = [
    {'itemCode': 'MXW-17-BLK', 'description': '17" Gloss Black Rim', 'stdQty': 96},
    {'itemCode': 'MXW-16-BLK', 'description': '16" Matt Black Rim', 'stdQty': 96},
    {'itemCode': 'MXW-18-SLV', 'description': '18" Silver Alloy', 'stdQty': 80},
    {'itemCode': 'MXW-19-WHT', 'description': '19" Premium White', 'stdQty': 80},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isFetching = true);
    try {
      final remoteApi = ref.read(remoteApiProvider);

      // Load master items
      final itemsRes = await remoteApi.getItemsMaster();
      if (itemsRes['success'] == true && itemsRes['items'] != null) {
        final rawItems = (itemsRes['items'] as List<dynamic>).map((i) => {
          'itemCode': (i['itemCode'] ?? '').toString(),
          'description': (i['description'] ?? 'Automotive Wheel').toString(),
          'stdQty': (i['stdPalletQty'] as num?)?.toInt() ?? 96,
        }).toList();

        if (mounted && rawItems.isNotEmpty) {
          setState(() {
            _masterItems = rawItems;
            if (_itemController.text.isEmpty) {
              _itemController.text = (_masterItems.first['itemCode'] ?? '').toString();
            }
          });
        }
      }

      // Load half pallets register
      final halfRes = await remoteApi.getHalfPalletRegister();
      if (halfRes['success'] == true && halfRes['halfPallets'] != null) {
        if (mounted) {
          setState(() {
            _halfPallets = halfRes['halfPallets'] as List<dynamic>;
          });
        }
      }

      // Load paint plans
      final plansRes = await remoteApi.getPaintPlans();
      if (plansRes['success'] == true && plansRes['paintPlans'] != null) {
        final rawPlans = plansRes['paintPlans'] as List<dynamic>;
        final mappedPlans = rawPlans.map<Map<String, dynamic>>((p) {
          final items = (p['items'] as List<dynamic>?) ?? [];
          final firstItem = items.isNotEmpty ? (items.first as Map<String, dynamic>? ?? {}) : <String, dynamic>{};
          return {
            'planNumber': (p['planNumber'] ?? '').toString(),
            'line': (p['line'] ?? 'PL1').toString(),
            'shift': (p['shift'] ?? 'A').toString(),
            'itemCode': (firstItem['itemCode'] ?? p['itemCode'] ?? '').toString(),
            'plannedQty': (firstItem['plannedQty'] as num?)?.toInt() ?? (p['plannedQty'] as num?)?.toInt() ?? 0,
            'packedQty': (firstItem['packedQty'] as num?)?.toInt() ?? (p['packedQty'] as num?)?.toInt() ?? 0,
            'status': (p['status'] ?? 'RELEASED').toString(),
            'newPalletCreated': p['newPalletCreated'],
          };
        }).toList();

        if (mounted) {
          setState(() {
            _plans = mappedPlans;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading paint plan data: $e');
    } finally {
      if (mounted) {
        _checkHalfPalletMatch(_itemController.text.trim());
        setState(() => _isFetching = false);
      }
    }
  }

  void _checkHalfPalletMatch(String itemCode) {
    final code = itemCode.trim();
    if (code.isEmpty) {
      setState(() {
        _hasHalfMatch = false;
        _matchedHalfPallet = null;
        _createNewPalletOption = true;
      });
      return;
    }

    final match = _halfPallets.firstWhere(
      (h) => (h['itemCode'] as String? ?? '').toUpperCase() == code.toUpperCase(),
      orElse: () => null,
    );

    setState(() {
      if (match != null) {
        _hasHalfMatch = true;
        _matchedHalfPallet = Map<String, dynamic>.from(match as Map);
        _createNewPalletOption = false; // By default reuse half pallet
      } else {
        _hasHalfMatch = false;
        _matchedHalfPallet = null;
        _createNewPalletOption = true; // Auto-enable create new pallet when no match
      }
    });
  }

  Future<void> _onReleasePlan() async {
    final item = _itemController.text.trim();
    final qtyStr = _qtyController.text.trim();

    if (item.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Item Code and Planned Quantity'), backgroundColor: AppColors.warn),
      );
      return;
    }

    final plannedQty = int.tryParse(qtyStr) ?? 384;
    setState(() => _isLoading = true);

    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.createPaintPlan(
        itemCode: item,
        plannedQty: plannedQty,
        shift: _shift,
        line: _line,
        createNewPallet: _createNewPalletOption,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (res['success'] == true) {
          final newPalletNo = res['newPalletCreated'];
          final planNo = res['paintPlan']?['planNumber'] ?? 'PLN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

          setState(() {
            _plans.insert(0, {
              'planNumber': planNo,
              'line': _line,
              'shift': _shift,
              'itemCode': item,
              'plannedQty': plannedQty,
              'packedQty': 0,
              'status': 'RELEASED',
              'newPalletCreated': newPalletNo,
            });
          });

          final message = newPalletNo != null
              ? 'New Paint Plan released! New Pallet [$newPalletNo] allocated because wheel item code did not match half stored pallets.'
              : 'New Paint Plan released! Reusing existing half pallet ${_matchedHalfPallet?['palletNumber'] ?? ''}.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              backgroundColor: AppColors.ok,
              duration: const Duration(seconds: 4),
            ),
          );

          // Refresh all data from server
          await _loadInitialData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to release plan'), backgroundColor: AppColors.danger),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final planNo = 'PLN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        final newPalletNo = _createNewPalletOption ? 'P26000${(149 + _plans.length)}' : null;
        setState(() {
          _plans.insert(0, {
            'planNumber': planNo,
            'line': _line,
            'shift': _shift,
            'itemCode': item,
            'plannedQty': plannedQty,
            'packedQty': 0,
            'status': 'RELEASED',
            'newPalletCreated': newPalletNo,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newPalletNo != null
                ? 'Plan released! New Pallet [$newPalletNo] allocated for item $item.'
                : 'Plan released using half pallet!'),
            backgroundColor: AppColors.ok,
          ),
        );
      }
    }
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
        {'CREATE NEW PALLET': _createNewPalletOption ? 'YES (Fresh P-Pallet)' : 'NO (Reuse Half Pallet)'},
      ],
    );
  }

  void _onExportPlansExcel() {
    exportToExcel(
      context,
      'Paint Line Production Plans',
      ['PLAN #', 'LINE / SHIFT', 'ITEM CODE', 'PLANNED QTY', 'PACKED QTY', 'STATUS', 'ALLOCATED PALLET'],
      _plans.map((p) => [
        (p['planNumber'] ?? '').toString(),
        '${p['line']} · Shift ${p['shift']}',
        (p['itemCode'] ?? '').toString(),
        '${p['plannedQty']} wheels',
        '${p['packedQty']} wheels',
        (p['status'] ?? '').toString(),
        (p['newPalletCreated'] ?? 'Half Pallet Reused').toString(),
      ]).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RELEASE NEW PAINT LINE SCHEDULE',
                          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        if (_isFetching)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ribbonPink),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Master Items Quick Picker Dropdown
                    if (_masterItems.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(_itemController.text.trim()),
                        value: _masterItems.any((m) => (m['itemCode'] ?? '').toString() == _itemController.text.trim())
                            ? _itemController.text.trim()
                            : (_masterItems.isNotEmpty ? (_masterItems.first['itemCode'] ?? '').toString() : null),
                        isExpanded: true,
                        dropdownColor: context.bgSurfaceElevated,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'SELECT FROM MASTER ITEMS (OR TYPE BELOW)',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _masterItems.map((item) {
                          final code = (item['itemCode'] ?? '').toString();
                          final desc = (item['description'] ?? '').toString();
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('$code — $desc', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _itemController.text = val;
                            });
                            _checkHalfPalletMatch(val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: _itemController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Wheel Item Code (e.g. MXW-17-BLK, MXW-18-SLV, MXW-19-CHR)',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) => _checkHalfPalletMatch(val),
                    ),
                    const SizedBox(height: 12),

                    // --- Half Pallet Match Indicator Card ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _hasHalfMatch
                            ? AppColors.ok.withValues(alpha: 0.1)
                            : AppColors.warn.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _hasHalfMatch ? context.okInk : context.warnInk,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasHalfMatch ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                color: _hasHalfMatch ? context.okInk : context.warnInk,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hasHalfMatch
                                      ? 'Matching Half Pallet Found: ${_matchedHalfPallet?['palletNumber']} (${_matchedHalfPallet?['packedQty']} wheels in ${_matchedHalfPallet?['locationCode'] ?? 'HB1'})'
                                      : 'No matching half-stored pallet found in storage for ${_itemController.text.trim().isEmpty ? 'this item' : _itemController.text.trim()}',
                                  style: TextStyle(
                                    color: _hasHalfMatch ? context.okInk : context.warnInk,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => setState(() => _createNewPalletOption = !_createNewPalletOption),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _createNewPalletOption,
                                    activeColor: AppColors.ribbonPink,
                                    onChanged: (val) => setState(() => _createNewPalletOption = val ?? false),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _hasHalfMatch
                                          ? 'Override & Create New Pallet (Ignore existing half pallet)'
                                          : 'Create New Pallet option (Allocate fresh P-series pallet for this plan)',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                          width: isDesktop ? 240 : double.infinity,
                          child: DropdownButtonFormField<String>(
                            value: _shift,
                            isExpanded: true,
                            dropdownColor: context.bgSurfaceElevated,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Shift',
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'A', child: Text('Shift A (06:00 - 14:00)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'B', child: Text('Shift B (14:00 - 22:00)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'C', child: Text('Shift C (22:00 - 06:00)', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) => setState(() => _shift = val ?? 'A'),
                          ),
                        ),
                        SizedBox(
                          width: isDesktop ? 240 : double.infinity,
                          child: DropdownButtonFormField<String>(
                            value: _line,
                            isExpanded: true,
                            dropdownColor: context.bgSurfaceElevated,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Paint Line',
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PL1', child: Text('Paint Line 1 (PL1)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'PL2', child: Text('Paint Line 2 (PL2)', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) => setState(() => _line = val ?? 'PL1'),
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
                          text: _createNewPalletOption ? 'RELEASE PLAN & CREATE NEW PALLET' : 'RELEASE PLAN TO SHOP FLOOR',
                          icon: _createNewPalletOption ? Icons.add_box : Icons.rocket_launch,
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LIVE PAINT PRODUCTION PLANS (${_plans.length})',
                              style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18, color: AppColors.ribbonPink),
                              tooltip: 'Refresh Paint Plans from Database',
                              onPressed: _loadInitialData,
                            ),
                          ],
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
                    _plans.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: context.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, color: context.textMuted, size: 36),
                                const SizedBox(height: 12),
                                Text(
                                  'No Paint Plans Found',
                                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Release a new schedule using the form on the left or tap refresh.',
                                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 14),
                                AppButton(
                                  text: 'REFRESH DATABASE',
                                  icon: Icons.refresh,
                                  variant: AppButtonVariant.ghost,
                                  onPressed: _loadInitialData,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              horizontalMargin: 12,
                              columns: const [
                                DataColumn(label: Text('PLAN #')),
                                DataColumn(label: Text('LINE / SHIFT')),
                                DataColumn(label: Text('ITEM CODE')),
                                DataColumn(label: Text('PLANNED')),
                                DataColumn(label: Text('PACKED')),
                                DataColumn(label: Text('ALLOCATED PALLET')),
                                DataColumn(label: Text('STATUS')),
                              ],
                              rows: _plans.map((p) {
                                final planNum = (p['planNumber'] ?? '').toString();
                                final planned = (p['plannedQty'] as num?)?.toInt() ?? 0;
                                final packed = (p['packedQty'] as num?)?.toInt() ?? 0;
                                final allocatedPallet = p['newPalletCreated'] ?? 'Half Pallet Reused';

                                return DataRow(
                                  cells: [
                                    DataCell(Text(planNum, style: TextStyle(fontWeight: FontWeight.w800, color: context.brandInk))),
                                    DataCell(Text('${p['line']} · Shift ${p['shift']}')),
                                    DataCell(Text((p['itemCode'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
                                    DataCell(Text('$planned wheels')),
                                    DataCell(
                                      Text(
                                        '$packed / $planned',
                                        style: TextStyle(
                                          color: packed >= planned && planned > 0 ? context.okInk : (packed > 0 ? context.infoInk : context.textMuted),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (p['newPalletCreated'] != null)
                                              ? AppColors.pink.withValues(alpha: 0.15)
                                              : AppColors.ok.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          allocatedPallet.toString(),
                                          style: TextStyle(
                                            color: (p['newPalletCreated'] != null) ? AppColors.pink : context.okInk,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(StatusPill(
                                      label: (p['status'] ?? 'RELEASED').toString(),
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

