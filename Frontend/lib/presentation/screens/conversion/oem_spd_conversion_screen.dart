import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class OemSpdConversionScreen extends ConsumerStatefulWidget {
  const OemSpdConversionScreen({super.key});

  @override
  ConsumerState<OemSpdConversionScreen> createState() => _OemSpdConversionScreenState();
}

class _OemSpdConversionScreenState extends ConsumerState<OemSpdConversionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Create Request
  final _itemCodeController = TextEditingController(text: 'MXW-17-BLK');
  final _qtyRequiredController = TextEditingController(text: '10');
  final _customerController = TextEditingController(text: 'SPD Aftermarket Pune');
  final _refController = TextEditingController(text: 'PO-SPD-9921');

  // Tab 2: SPD Packing Execution
  final _requestNoController = TextEditingController(text: 'SR2600038');
  final _sourcePalletController = TextEditingController(text: 'P26000101');
  final _wheelQrController = TextEditingController(text: 'MW|P1|MXW-17-BLK|000001742|260822|A|PL2');

  // Tab 3: Reverse Conversion
  final _spdPackNumbersController = TextEditingController(text: 'SP26000411, SP26000412');

  bool _isLoading = false;
  Map<String, dynamic>? _lastCreatedRequest;
  Map<String, dynamic>? _proposedPallet;
  List<dynamic> _spdRequests = [];
  List<dynamic> _spdPacks = [];
  List<dynamic> _residualHalfPallets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchSpdData();
  }

  void _fetchSpdData() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/conversion/spd-requests');
    if (res['success'] == true) {
      setState(() {
        _spdRequests = res['spdRequests'] ?? [];
        _spdPacks = res['spdPacks'] ?? [];
        _residualHalfPallets = res['halfPalletsFromSpd'] ?? [];
      });
    }
  }

  void _onCreateSpdRequest() async {
    final itemCode = _itemCodeController.text.trim();
    final qty = int.tryParse(_qtyRequiredController.text.trim()) ?? 10;
    if (itemCode.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/conversion/spd-request', {
      'itemCode': itemCode,
      'qtyRequired': qty,
      'customerName': _customerController.text.trim(),
      'reference': _refController.text.trim(),
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _lastCreatedRequest = res['spdRequest'];
        _proposedPallet = res['proposedPallet'];
        if (_lastCreatedRequest != null) {
          _requestNoController.text = _lastCreatedRequest!['spdRequestNumber'] ?? '';
        }
        if (_proposedPallet != null) {
          _sourcePalletController.text = _proposedPallet!['palletNumber'] ?? '';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'SPD Request created!'),
        ),
      );
      _fetchSpdData();
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Request creation failed')),
      );
    }
  }

  void _onPackSpdWheel() async {
    final reqNo = _requestNoController.text.trim();
    final palletNo = _sourcePalletController.text.trim();
    final wheelQr = _wheelQrController.text.trim();
    if (reqNo.isEmpty || palletNo.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/conversion/pack-spd-wheel', {
      'spdRequestNumber': reqNo,
      'sourcePalletNumber': palletNo,
      'wheelQr': wheelQr,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final spQr = res['spdPack']?['spdPackQr'] ?? 'MWS|SP26000411';
      final spNo = res['spdPack']?['spdPackNumber'] ?? 'SP26000411';
      final residualH = res['residualHalfPallet']?['palletNumber'];

      PrintPreviewDialog.show(
        context: context,
        title: 'SPD INDIVIDUAL PACK (SP) LABEL PRINT PREVIEW',
        documentType: PrintDocumentType.spdPack,
        qrData: spQr,
        codeText: spQr,
        itemCode: 'MXW-17-BLK',
        itemDescription: 'Individual Boxed SPD Spare Wheel (SP Series)',
        primaryDetail: 'SPD Request: $reqNo • Source: $palletNo',
        secondaryDetail: residualH != null ? 'Residual Pallet: $residualH (Half Pallet Stored)' : 'Source Pallet Completed',
        metadataFields: [
          {'PACK #': spNo},
          {'DATE': '2026-08-22'},
          {'STATUS': 'PACKED_FOR_SPD'},
        ],
      );

      _fetchSpdData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Packing failed')),
      );
    }
  }

  void _onFinishSpdJob() async {
    final reqNo = _requestNoController.text.trim();
    final palletNo = _sourcePalletController.text.trim();
    if (reqNo.isEmpty || palletNo.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/conversion/finish-spd-job', {
      'spdRequestNumber': reqNo,
      'sourcePalletNumber': palletNo,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'SPD Partial Take finished successfully!'),
        ),
      );
      _fetchSpdData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Finish failed')),
      );
    }
  }

  void _onConvertSpdToPallet() async {
    final rawPacks = _spdPackNumbersController.text.trim();
    if (rawPacks.isEmpty) return;

    final packNumbers = rawPacks.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/conversion/spd-to-pallet', {
      'spdPackNumbers': packNumbers,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Assembled SPD Packs into Pallet successfully!'),
        ),
      );
      _fetchSpdData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Assembly failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTokens.pScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 12 — SPD Conversion (SSR Section 8)'),
          const SizedBox(height: 8),
          Text(
            'Partial take driven by request quantity (SR2600038). Takes requested wheels off an OEM pallet, packs each wheel individually with an SPD label (SP26000411 / MWS|...), closes source pallet as Split-Consumed, and re-issues remaining wheels as a new Half Pallet (H26000091) into the top-up cycle.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.ribbonPink,
            labelColor: AppColors.ribbonPink,
            unselectedLabelColor: context.textMuted,
            tabs: const [
              Tab(icon: Icon(Icons.add_task_outlined), text: '1. RAISE SPD REQUEST (SR)'),
              Tab(icon: Icon(Icons.qr_code_scanner_outlined), text: '2. HHT SPD PACKING'),
              Tab(icon: Icon(Icons.unarchive_outlined), text: '3. REVERSE (SPD → PALLET)'),
              Tab(icon: Icon(Icons.analytics_outlined), text: '4. STOCK BY CHANNEL & REPORTS'),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 540,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Raise SPD Request
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP 1 — RAISE SPD CONVERSION REQUEST',
                        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _itemCodeController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Item Code',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _qtyRequiredController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Quantity Required (Wheels)',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customerController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Customer / SPD Reference',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _refController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'PO / Schedule Reference',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: _isLoading ? 'CREATING...' : 'RAISE SPD REQUEST & AUTO-SELECT PALLET (ORDER OF PREFERENCE)',
                        variant: AppButtonVariant.gradient,
                        isLoading: _isLoading,
                        onPressed: _onCreateSpdRequest,
                      ),
                      const SizedBox(height: 20),
                      if (_proposedPallet != null) ...[
                        Divider(color: Theme.of(context).dividerColor),
                        const SizedBox(height: 12),
                        const Text('SYSTEM PROPOSED SOURCE PALLET (Order of Preference):', style: TextStyle(color: AppColors.ok, fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          'Pallet ${_proposedPallet!['palletNumber']} (${_proposedPallet!['typeSeries']}) • Qty: ${_proposedPallet!['packedQty']} • Location: ${_proposedPallet!['locationCode']}',
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tab 2: HHT SPD Packing Execution
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP 2 — HHT GUIDED SPD WHEEL PACKING & SP LABEL PRINTING',
                        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _requestNoController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'SPD Request Number (SR...)',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _sourcePalletController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Source Pallet Master QR (P / H / PM)',
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _wheelQrController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Scan Wheel QR on Pallet (MW|P1|...)',
                          prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink),
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'PACK WHEEL & PRINT SP LABEL (MWS|SP...)',
                              variant: AppButtonVariant.gradient,
                              onPressed: _onPackSpdWheel,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              text: 'FINISH SPD JOB & ISSUE RESIDUAL HALF PALLET (H)',
                              variant: AppButtonVariant.secondary,
                              onPressed: _onFinishSpdJob,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 12),
                      Text('STOCK EFFECT UPON FINISH (AUTOMATIC):', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('1. Taken wheels become independent SPD Packs (SP26000411...)\n2. Source Pallet closes as Split-Consumed\n3. Remaining wheels re-issued as a new Half Pallet (H26000091) in top-up cycle', style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),

                // Tab 3: Reverse Conversion
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REVERSE FLOW — CONVERT SPD PACKS BACK TO OEM PALLET (P / H)',
                        style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _spdPackNumbersController,
                        maxLines: 3,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Comma Separated SPD Pack Numbers (e.g. SP26000411, SP26000412)',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: _isLoading ? 'RE-ASSEMBLING...' : 'RE-ASSEMBLE SPD PACKS INTO OEM PALLET',
                        variant: AppButtonVariant.gradient,
                        isLoading: _isLoading,
                        onPressed: _onConvertSpdToPallet,
                      ),
                    ],
                  ),
                ),

                // Tab 4: Stock by Channel & Reports
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SPD STOCK BY CHANNEL & RESIDUAL HALF PALLETS REPORT',
                            style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          AppButton(
                            text: 'EXPORT SPD STOCK EXCEL',
                            icon: Icons.table_chart_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: () {
                              exportToExcel(
                                context,
                                'SPD Stock & Residual Half Pallets Summary',
                                ['METRIC', 'COUNT / VALUE', 'STATUS'],
                                [
                                  ['Active SPD Requests', '${_spdRequests.length} Requests', 'ACTIVE'],
                                  ['In-Stock SPD Packs (SP Series)', '${_spdPacks.length} Packs', 'IN_STOCK'],
                                  ['Residual Half Pallets Created', '${_residualHalfPallets.length} Pallets', 'STORED_FOR_TOP_UP'],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              tileColor: context.bgSurfaceElevated,
                              title: Text('Active SPD Requests', style: TextStyle(color: context.textMuted, fontSize: 11)),
                              subtitle: Text('${_spdRequests.length} Requests', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListTile(
                              tileColor: context.bgSurfaceElevated,
                              title: Text('In-Stock SPD Packs (SP)', style: TextStyle(color: context.textMuted, fontSize: 11)),
                              subtitle: Text('${_spdPacks.length} Packs', style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w800, fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListTile(
                              tileColor: context.bgSurfaceElevated,
                              title: Text('Half Pallets Created by SPD', style: TextStyle(color: context.textMuted, fontSize: 11)),
                              subtitle: Text('${_residualHalfPallets.length} Pallets', style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w800, fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
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
