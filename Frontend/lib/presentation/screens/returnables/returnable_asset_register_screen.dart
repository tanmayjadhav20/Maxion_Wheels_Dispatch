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

class ReturnableAssetRegisterScreen extends ConsumerStatefulWidget {
  const ReturnableAssetRegisterScreen({super.key});

  @override
  ConsumerState<ReturnableAssetRegisterScreen> createState() => _ReturnableAssetRegisterScreenState();
}

class _ReturnableAssetRegisterScreenState extends ConsumerState<ReturnableAssetRegisterScreen> with SingleTickerProviderStateMixin {
  static const List<Map<String, dynamic>> _defaultMasterItems = [
    {'itemCode': 'MXW-17-BLK', 'description': '17" Gloss Black Rim', 'palletType': 'STEEL-FRAME-A'},
    {'itemCode': 'MXW-16-BLK', 'description': '16" Matt Black Rim', 'palletType': 'STEEL-FRAME-A'},
    {'itemCode': 'MXW-18-SLV', 'description': '18" Silver Alloy', 'palletType': 'WOOD-PALLET-B'},
    {'itemCode': 'MXW-19-WHT', 'description': '19" Premium White', 'palletType': 'WOOD-PALLET-B'},
    {'itemCode': 'MXW-16-MAT', 'description': '16" Matte Black Stillage', 'palletType': 'HEAVY-STILLAGE-C'},
  ];

  final _assetQrController = TextEditingController(text: 'RP0001842');
  final _palletNoController = TextEditingController(text: 'P26000101');
  final _customerController = TextEditingController(text: 'Tata Motors Pune');

  late TabController _tabController;

  bool _isLoading = false;
  String _condition = 'Good';
  String _assetType = 'STEEL-FRAME-A';
  String _selectedItemCode = 'MXW-17-BLK';

  List<dynamic> _masterItems = _defaultMasterItems;
  List<Map<String, dynamic>> _rawAssets = [];
  List<Map<String, dynamic>> _customerSummary = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMasterItems();
    _fetchReturnables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assetQrController.dispose();
    _palletNoController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterItems() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.getItemsMaster();
      if (res['success'] == true && res['items'] != null && res['items'] is List) {
        final raw = res['items'] as List;
        final list = raw.map((i) {
          final m = i is Map ? i : <String, dynamic>{};
          return {
            'itemCode': (m['itemCode'] ?? '').toString(),
            'description': (m['description'] ?? 'Automotive Wheel').toString(),
            'palletType': (m['palletType'] ?? 'STEEL-FRAME-A').toString(),
          };
        }).toList();

        if (list.isNotEmpty && mounted) {
          setState(() {
            _masterItems = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchReturnables() async {
    setState(() => _isLoading = true);
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.getReturnables();
      if (res['success'] == true && res['assets'] != null) {
        final assets = (res['assets'] as List).map((a) {
          final m = a is Map ? a : <String, dynamic>{};
          return {
            'assetTag': (m['assetTag'] ?? '').toString(),
            'assetNumber': (m['assetNumber'] ?? '').toString(),
            'palletNumber': (m['palletNumber'] ?? 'P26000101').toString(),
            'itemCode': (m['itemCode'] ?? 'MXW-17-BLK').toString(),
            'type': (m['type'] ?? 'STEEL-FRAME-A').toString(),
            'condition': (m['condition'] ?? 'Good').toString(),
            'status': (m['status'] ?? 'In Stock (Empty)').toString(),
            'customerName': (m['customerName'] ?? '').toString(),
            'locationCode': (m['locationCode'] ?? 'WH1-A-01-A2').toString(),
            'ageingDays': (m['ageingDays'] as num?)?.toInt() ?? 0,
          };
        }).toList();

        final Map<String, Map<String, int>> customerMap = {};

        for (final a in assets) {
          final cust = a['customerName'] as String;
          if (cust.isNotEmpty) {
            if (!customerMap.containsKey(cust)) {
              customerMap[cust] = {'dispatchedQty': 0, 'returnedQty': 0, 'outstandingQty': 0};
            }
            customerMap[cust]!['dispatchedQty'] = (customerMap[cust]!['dispatchedQty'] ?? 0) + 1;
            if (a['status'] == 'With Customer') {
              customerMap[cust]!['outstandingQty'] = (customerMap[cust]!['outstandingQty'] ?? 0) + 1;
            } else {
              customerMap[cust]!['returnedQty'] = (customerMap[cust]!['returnedQty'] ?? 0) + 1;
            }
          }
        }

        if (mounted) {
          setState(() {
            _rawAssets = assets;
            _customerSummary = customerMap.entries.map((e) => {
              'customer': e.key,
              'dispatchedQty': e.value['dispatchedQty'],
              'returnedQty': e.value['returnedQty'],
              'outstandingQty': e.value['outstandingQty'],
            }).toList();

            final matchingWithCust = assets.where((a) => a['status'] == 'With Customer').toList();
            if (matchingWithCust.isNotEmpty && _assetQrController.text.isEmpty) {
              final withCust = matchingWithCust.first;
              _assetQrController.text = (withCust['assetNumber'] ?? withCust['assetTag'] ?? '').toString();
              _palletNoController.text = (withCust['palletNumber'] ?? 'P26000101').toString();
              _selectedItemCode = (withCust['itemCode'] ?? 'MXW-17-BLK').toString();
              _customerController.text = (withCust['customerName'] ?? '').toString();
            }
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _onReceiveAsset() async {
    final assetQr = _assetQrController.text.trim();
    final palletNo = _palletNoController.text.trim();
    final customer = _customerController.text.trim();
    final itemCode = _selectedItemCode;

    if (assetQr.isEmpty || customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Asset Barcode/QR and Customer name'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.receiveReturnable(
        assetQr,
        _condition,
        palletNumber: palletNo.isNotEmpty ? palletNo : 'P26000101',
        itemCode: itemCode,
        customerName: customer,
      );
      if (mounted) setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Returnable packaging (Pallet: ' + palletNo + ', Item: ' + itemCode + ') received and saved to database!'),
            backgroundColor: AppColors.ok,
          ),
        );
        _fetchReturnables();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res['message'] ?? 'Receive failed').toString()), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPrintSlip() {
    final qr = _assetQrController.text.trim();
    final palletNo = _palletNoController.text.trim();
    final itemCode = _selectedItemCode;
    final customer = _customerController.text.trim();

    PrintPreviewDialog.show(
      context: context,
      title: 'RETURNABLE ASSET RECEIPT SLIP PREVIEW',
      documentType: PrintDocumentType.palletMaster,
      qrData: 'MWR|' + qr,
      codeText: 'MWR|' + qr,
      itemCode: itemCode,
      itemDescription: 'Customer Returnable ' + _assetType,
      primaryDetail: 'Pallet: ' + (palletNo.isNotEmpty ? palletNo : 'N/A') + ' • Customer: ' + (customer.isNotEmpty ? customer : 'N/A'),
      secondaryDetail: 'Condition: ' + _condition + ' • Type: ' + _assetType,
      metadataFields: [
        {'ASSET #': qr},
        {'PALLET #': palletNo.isNotEmpty ? palletNo : 'P26000101'},
        {'ITEM CODE': itemCode},
        {'CUSTOMER': customer},
        {'CONDITION': _condition},
        {'RECEIVED BY': 'Gate Security / Inward Incharge'},
      ],
    );
  }

  void _onExportReturnablesExcel() {
    exportToExcel(
      context,
      'Returnable Asset Register',
      ['ASSET TAG', 'PALLET NO', 'ITEM CODE', 'ASSET TYPE', 'CUSTOMER / VENDOR', 'CONDITION', 'STATUS', 'LOCATION', 'AGEING (DAYS)'],
      _rawAssets.map((r) => [
        (r['assetNumber'] ?? r['assetTag'] ?? '').toString(),
        (r['palletNumber'] ?? 'N/A').toString(),
        (r['itemCode'] ?? 'N/A').toString(),
        (r['type'] ?? 'STEEL-FRAME-A').toString(),
        (r['customerName'] ?? 'In House').toString(),
        (r['condition'] ?? 'Good').toString(),
        (r['status'] ?? 'In Stock').toString(),
        (r['locationCode'] ?? 'WH1-A-01-A2').toString(),
        r['ageingDays'].toString(),
      ]).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawList = _masterItems.isNotEmpty ? _masterItems : _defaultMasterItems;
    final List<Map<String, dynamic>> itemList = rawList.map((i) {
      if (i is Map) {
        return {
          'itemCode': (i['itemCode'] ?? '').toString(),
          'description': (i['description'] ?? 'Automotive Wheel').toString(),
          'palletType': (i['palletType'] ?? 'STEEL-FRAME-A').toString(),
        };
      }
      return {'itemCode': 'MXW-17-BLK', 'description': '17" Gloss Black Rim', 'palletType': 'STEEL-FRAME-A'};
    }).toList();

    final bool itemFound = itemList.any((m) => (m['itemCode'] ?? '').toString() == _selectedItemCode);
    final String selectedItem = itemFound ? _selectedItemCode : (itemList.first['itemCode'] ?? 'MXW-17-BLK').toString();

    final safeRawAssets = _rawAssets.isNotEmpty ? _rawAssets : const <Map<String, dynamic>>[];
    final safeCustomerSummary = _customerSummary.isNotEmpty ? _customerSummary : const <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 9 — Returnable Asset Register (Trolleys, Dunnage & Pallets)'),
          const SizedBox(height: 8),
          Text(
            'Track customer returnable packaging assets (metal trolleys, plastic dunnage, special stillages). Links returnables directly to Pallet Number & Wheel Item Code.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final isDesktop = constraints.maxWidth > 950;

              final palletNoField = TextField(
                controller: _palletNoController,
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Associated Pallet #',
                  hintText: 'e.g. P26000101',
                  prefixIcon: const Icon(Icons.grid_view, color: AppColors.ribbonPink),
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              final itemCodeField = DropdownButtonFormField<String>(
                key: ValueKey(selectedItem),
                initialValue: selectedItem,
                isExpanded: true,
                dropdownColor: context.bgSurfaceElevated,
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Wheel Item Code',
                  prefixIcon: const Icon(Icons.circle, color: AppColors.ribbonPink, size: 16),
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                ),
                items: itemList.map((item) {
                  final code = (item['itemCode'] ?? '').toString();
                  final desc = (item['description'] ?? 'Wheel').toString();
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(code + ' (' + desc + ')', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedItemCode = val;
                    });
                  }
                },
              );

              final packagingTypeField = DropdownButtonFormField<String>(
                initialValue: _assetType,
                isExpanded: true,
                dropdownColor: context.bgSurfaceElevated,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Packaging Type',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'STEEL-FRAME-A', child: Text('STEEL-FRAME-A (Steel Stillage)')),
                  DropdownMenuItem(value: 'WOOD-PALLET-B', child: Text('WOOD-PALLET-B (Export Wooden Pallet)')),
                  DropdownMenuItem(value: 'HEAVY-STILLAGE-C', child: Text('HEAVY-STILLAGE-C (Heavy Metal Stillage)')),
                  DropdownMenuItem(value: 'PLASTIC-DUNNAGE-D', child: Text('PLASTIC-DUNNAGE-D (Plastic Dunnage)')),
                ],
                onChanged: (val) => setState(() => _assetType = val!),
              );

              final conditionField = DropdownButtonFormField<String>(
                initialValue: _condition,
                isExpanded: true,
                dropdownColor: context.bgSurfaceElevated,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Condition Upon Gate Entry',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Good', child: Text('Good (Ready for Reuse)')),
                  DropdownMenuItem(value: 'Damaged (Minor)', child: Text('Damaged (Minor Repair)')),
                  DropdownMenuItem(value: 'Damaged (Major)', child: Text('Damaged (Scrap Claim)')),
                ],
                onChanged: (val) => setState(() => _condition = val!),
              );

              final formCard = AppCard(
                showGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.ribbonPink.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.input, color: AppColors.ribbonPink, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'LOG RETURNABLE PACKAGING RECEIPT',
                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Asset Barcode
                    TextField(
                      controller: _assetQrController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Returnable Asset Barcode / QR (e.g. RP0001842)',
                        prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink),
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pallet No & Item Code row
                    if (isNarrow) ...[
                      palletNoField,
                      const SizedBox(height: 12),
                      itemCodeField,
                    ] else ...[
                      Row(
                        children: [
                          Expanded(flex: 5, child: palletNoField),
                          const SizedBox(width: 12),
                          Expanded(flex: 6, child: itemCodeField),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Customer Name
                    TextField(
                      controller: _customerController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Returning Customer / Vendor',
                        hintText: 'e.g. Tata Motors Pune / Mahindra Nashik',
                        prefixIcon: const Icon(Icons.business_outlined, color: AppColors.ribbonPink),
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Asset Type & Condition
                    if (isNarrow) ...[
                      packagingTypeField,
                      const SizedBox(height: 12),
                      conditionField,
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: packagingTypeField),
                          const SizedBox(width: 12),
                          Expanded(child: conditionField),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AppButton(
                          text: 'LOG RECEIPT & CREDIT BALANCE',
                          icon: Icons.check_circle_outline,
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: _onReceiveAsset,
                        ),
                        AppButton(
                          text: 'PRINT RECEIPT SLIP',
                          icon: Icons.print_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onPrintSlip,
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final tableCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: AppColors.ribbonPink,
                            unselectedLabelColor: context.textSecondary,
                            indicatorColor: AppColors.ribbonPink,
                            tabs: const [
                              Tab(text: 'INDIVIDUAL ASSET TRACKER'),
                              Tab(text: 'CUSTOMER PACKAGING BALANCE'),
                            ],
                          ),
                        ),
                        AppButton(
                          text: 'EXPORT EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onExportReturnablesExcel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 440,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Individual Asset Tracker
                          safeRawAssets.isEmpty
                              ? Center(child: Text('No returnable assets found', style: TextStyle(color: context.textSecondary)))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 18,
                                      horizontalMargin: 8,
                                      headingRowColor: WidgetStateProperty.all(context.bgSurfaceElevated),
                                      columns: const [
                                        DataColumn(label: Text('ASSET #')),
                                        DataColumn(label: Text('PALLET NO')),
                                        DataColumn(label: Text('ITEM CODE')),
                                        DataColumn(label: Text('TYPE')),
                                        DataColumn(label: Text('CUSTOMER')),
                                        DataColumn(label: Text('CONDITION')),
                                        DataColumn(label: Text('STATUS')),
                                        DataColumn(label: Text('AGEING')),
                                      ],
                                      rows: safeRawAssets.map((a) {
                                        final assetNo = (a['assetNumber'] ?? a['assetTag'] ?? '').toString();
                                        final palletNo = (a['palletNumber'] ?? 'N/A').toString();
                                        final itemCode = (a['itemCode'] ?? 'N/A').toString();
                                        final cust = (a['customerName'] ?? 'In House').toString();
                                        final status = (a['status'] ?? 'In Stock').toString();
                                        final cond = (a['condition'] ?? 'Good').toString();
                                        final age = (a['ageingDays'] as int?) ?? 0;

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(assetNo, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ribbonPink))),
                                            DataCell(Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(palletNo, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.blueAccent)),
                                            )),
                                            DataCell(Text(itemCode, style: const TextStyle(fontWeight: FontWeight.w700))),
                                            DataCell(Text((a['type'] ?? '').toString(), style: TextStyle(fontSize: 11, color: context.textMuted))),
                                            DataCell(Text(cust.isEmpty ? 'In House' : cust, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600))),
                                            DataCell(Text(cond, style: TextStyle(color: cond == 'Good' ? AppColors.ok : AppColors.warn, fontWeight: FontWeight.w700))),
                                            DataCell(StatusPill(
                                              label: status,
                                              variant: status == 'With Customer' ? PillVariant.warn : (status == 'In Repair' ? PillVariant.danger : PillVariant.ok),
                                            )),
                                            DataCell(Text(age > 0 ? age.toString() + ' d' : '—', style: TextStyle(color: age > 15 ? AppColors.danger : context.textSecondary))),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),

                          // Tab 2: Customer Packaging Balance
                          safeCustomerSummary.isEmpty
                              ? Center(child: Text('No customer balances available', style: TextStyle(color: context.textSecondary)))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 24,
                                      horizontalMargin: 12,
                                      headingRowColor: WidgetStateProperty.all(context.bgSurfaceElevated),
                                      columns: const [
                                        DataColumn(label: Text('CUSTOMER / VENDOR')),
                                        DataColumn(label: Text('DISPATCHED OUT')),
                                        DataColumn(label: Text('RETURNED IN')),
                                        DataColumn(label: Text('OUTSTANDING')),
                                        DataColumn(label: Text('STATUS')),
                                      ],
                                      rows: safeCustomerSummary.map((r) {
                                        final out = r['dispatchedQty'] as int;
                                        final ret = r['returnedQty'] as int;
                                        final bal = r['outstandingQty'] as int;
                                        final isOverdue = bal > 150;

                                        return DataRow(cells: [
                                          DataCell(Text(r['customer'] as String, style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary))),
                                          DataCell(Text(out.toString() + ' units')),
                                          DataCell(Text(ret.toString() + ' units', style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w700))),
                                          DataCell(Text(bal.toString() + ' units', style: TextStyle(color: isOverdue ? AppColors.danger : AppColors.warn, fontWeight: FontWeight.w800))),
                                          DataCell(StatusPill(
                                            label: isOverdue ? 'OVERDUE ALERT' : 'BALANCED',
                                            variant: isOverdue ? PillVariant.danger : PillVariant.ok,
                                          )),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                        ],
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
                    Expanded(flex: 7, child: tableCard),
                  ],
                );
              }

              return Column(
                children: [
                  formCard,
                  const SizedBox(height: 24),
                  tableCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
