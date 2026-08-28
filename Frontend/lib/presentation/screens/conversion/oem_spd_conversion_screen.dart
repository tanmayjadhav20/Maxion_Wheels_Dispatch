import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/camera_qr_scanner_dialog.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/responsive_tab_bar.dart';
import '../../widgets/section_title.dart';

class OemSpdConversionScreen extends ConsumerStatefulWidget {
  const OemSpdConversionScreen({super.key});

  @override
  ConsumerState<OemSpdConversionScreen> createState() => _OemSpdConversionScreenState();
}

class _OemSpdConversionScreenState extends ConsumerState<OemSpdConversionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Create Request
  late final TextEditingController _itemCodeController = TextEditingController();
  late final TextEditingController _qtyRequiredController = TextEditingController(text: '10');
  late final TextEditingController _customerController = TextEditingController();
  late final TextEditingController _refController = TextEditingController();

  // Tab 2: SPD Packing Execution
  late final TextEditingController _requestNoController = TextEditingController();
  late final TextEditingController _sourcePalletController = TextEditingController();
  late final TextEditingController _wheelQrController = TextEditingController();

  // Tab 3: Reverse Conversion
  late final TextEditingController _spdPackNumbersController = TextEditingController();
  late final TextEditingController _reverseScanInputController = TextEditingController();
  late final TextEditingController _targetLocationController = TextEditingController(text: 'WH1-STG-01');
  final Set<String> _selectedSpdPackNumbers = {};

  bool _isLoading = false;
  Map<String, dynamic>? _lastCreatedRequest;
  Map<String, dynamic>? _proposedPallet;
  List<dynamic> _spdRequests = const [];
  List<dynamic> _spdPacks = const [];
  List<dynamic> _masterItems = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialMasterData();
    _fetchSpdData();
  }

  Future<void> _loadInitialMasterData() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final itemsRes = await remoteApi.getItemsMaster();
      if (itemsRes['success'] == true && itemsRes['items'] != null) {
        final items = itemsRes['items'] as List<dynamic>;
        setState(() {
          _masterItems = items;
          if (_masterItems.isNotEmpty && _itemCodeController.text.isEmpty) {
            _itemCodeController.text = _masterItems.first['itemCode'] ?? '';
            _customerController.text = _masterItems.first['defaultCustomer'] ?? 'SPD Aftermarket Pune';
            _refController.text = 'PO-SPD-${DateTime.now().year}-${_masterItems.first['itemCode']}';
          }
        });
      }
    } catch (_) {}
  }

  void _fetchSpdData() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/conversion/spd-requests');
    if (res['success'] == true) {
      setState(() {
        _spdRequests = res['spdRequests'] ?? [];
        _spdPacks = res['spdPacks'] ?? [];
        
        if (_spdRequests.isNotEmpty && _requestNoController.text.isEmpty) {
          _requestNoController.text = _spdRequests.first['spdRequestNumber'] ?? '';
        }
        if (_spdPacks.isNotEmpty && _spdPackNumbersController.text.isEmpty) {
          final packNos = _spdPacks.take(4).map((p) => p['spdPackNumber']).join(', ');
          _spdPackNumbersController.text = packNos;
        }
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
      final req = res['spdRequest'];

      setState(() {
        _lastCreatedRequest = req;
        _proposedPallet = res['proposedPallet'];
        if (_lastCreatedRequest != null) {
          _requestNoController.text = _lastCreatedRequest!['spdRequestNumber'] ?? '';
        }
        if (_proposedPallet != null) {
          _sourcePalletController.text = _proposedPallet!['palletNumber'] ?? '';
        }
      });

      _fetchSpdData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'SPD Request created! Check information in Tab 2 to generate QR stickers.'),
        ),
      );

      // Auto-switch to Tab 2 (SPD Packing Execution & Sticker Generation)
      _tabController.animateTo(1);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Request creation failed')),
      );
    }
  }

  void _onGenerateAndPrintSpdStickers() async {
    final reqNo = _requestNoController.text.trim();
    if (reqNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select an SPD Request Number first.'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/conversion/generate-stickers', {
      'spdRequestNumber': reqNo,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final rawStickers = (res['spdStickers'] as List<dynamic>?) ?? [];
      final stickers = rawStickers.map((s) => Map<String, dynamic>.from(s as Map)).toList();

      _fetchSpdData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Generated ${stickers.length} SPD QR Stickers!'),
        ),
      );

      if (stickers.isNotEmpty) {
        final itemCode = _lastCreatedRequest?['itemCode'] ?? 'MXW-17-BLK';
        BatchPrintPreviewDialog.show(
          context: context,
          title: 'SPD REQUIREMENT STICKERS (${stickers.length} LABELS)',
          itemCode: itemCode,
          itemDescription: 'Individual Boxed SPD Spare Wheel (SP Series)',
          stickers: stickers,
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Failed to generate stickers')),
      );
    }
  }

  void _onPrintBatchSpdStickersForRequest(Map<String, dynamic> req) {
    final itemCode = req['itemCode'] ?? 'MXW-17-BLK';
    final qty = req['qtyRequired'] ?? 10;
    final reqNo = req['spdRequestNumber'] ?? 'SR2600038';
    final cust = req['customerName'] ?? 'SPD Customer';

    List<Map<String, dynamic>> stickers = [];
    if (req['spdStickers'] != null && (req['spdStickers'] as List).isNotEmpty) {
      stickers = (req['spdStickers'] as List).map((s) => Map<String, dynamic>.from(s)).toList();
    } else {
      for (int i = 1; i <= qty; i++) {
        final spNo = 'SP26000${410 + i}';
        final qrData = 'MWS|$spNo';
        stickers.add({
          'spdPackNumber': spNo,
          'spdPackQr': qrData,
          'uniqueQrData': qrData,
          'codeText': spNo,
          'serialNumber': spNo,
          'itemCode': itemCode,
          'wheelIndex': i,
          'totalBatchCount': qty,
          'primaryDetail': 'SPD Req: $reqNo • Sticker $i of $qty',
          'secondaryDetail': 'Customer: $cust',
          'stickerDetails': [
            {'PACK #': spNo},
            {'REQ #': reqNo},
            {'LABEL': '$i OF $qty'},
            {'CUSTOMER': cust}
          ]
        });
      }
    }

    BatchPrintPreviewDialog.show(
      context: context,
      title: 'SPD REQUIREMENT STICKERS (${stickers.length} LABELS)',
      itemCode: itemCode,
      itemDescription: 'Individual Boxed SPD Spare Wheel (SP Series)',
      stickers: stickers,
    );
  }

  void _onScanSpdWheelCamera() {
    final itemCode = _lastCreatedRequest?['itemCode'] ?? 'MXW-17-BLK';
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: itemCode,
      onQrScanned: (scannedQr) {
        final qr = scannedQr.trim();
        if (qr.isNotEmpty) {
          setState(() {
            _wheelQrController.text = qr;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ok,
              duration: const Duration(milliseconds: 1200),
              content: Text('Scanned Wheel QR: $qr'),
            ),
          );
        }
      },
    );
  }

  void _onScanSourcePalletCamera() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: 'PALLET_SPD',
      onQrScanned: (scannedQr) {
        final clean = scannedQr.replaceAll('MWP|', '').replaceAll('MWR|', '').trim();
        setState(() {
          _sourcePalletController.text = clean;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ok,
            duration: const Duration(milliseconds: 1200),
            content: Text('Scanned Source Pallet: $clean'),
          ),
        );
      },
    );
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
      final List<dynamic> rawStickers = res['spdStickers'] ?? res['spdPacks'] ?? [];
      final List<Map<String, dynamic>> stickers = rawStickers.map((s) {
        final spNo = (s['spdPackNumber'] ?? s['codeText'] ?? 'SP26000411').toString();
        final qrData = (s['spdPackQr'] ?? s['uniqueQrData'] ?? 'MWS|$spNo').toString();
        return {
          'spdPackNumber': spNo,
          'spdPackQr': qrData,
          'uniqueQrData': qrData,
          'codeText': spNo,
          'serialNumber': spNo,
          'itemCode': (s['itemCode'] ?? 'MXW-17-BLK').toString(),
          'itemDescription': 'Individual Boxed SPD Spare Wheel (SP Series)',
          'wheelIndex': s['wheelIndex'] ?? 1,
          'totalBatchCount': rawStickers.length,
          'primaryDetail': (s['primaryDetail'] ?? 'SPD Req: $reqNo • Source: $palletNo').toString(),
          'secondaryDetail': (s['secondaryDetail'] ?? 'Customer: SPD Customer').toString(),
          'stickerDetails': s['stickerDetails'] ?? [
            {'PACK #': spNo},
            {'REQ #': reqNo},
            {'SOURCE': palletNo}
          ]
        };
      }).toList();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'SPD Wheels packed with ${stickers.length} QR stickers!'),
        ),
      );
      _fetchSpdData();

      if (stickers.isNotEmpty) {
        BatchPrintPreviewDialog.show(
          context: context,
          title: 'SPD PACKED WHEEL QR STICKERS (${stickers.length} LABELS)',
          itemCode: 'MXW-17-BLK',
          itemDescription: 'Individual Boxed SPD Spare Wheels (SP Series)',
          stickerType: 'SPD INDIVIDUAL PACK STICKER',
          stickers: stickers,
        );
      }
    } else {
      if (!mounted) return;
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

  void _onToggleSpdPack(String packNo) {
    setState(() {
      if (_selectedSpdPackNumbers.contains(packNo)) {
        _selectedSpdPackNumbers.remove(packNo);
      } else {
        _selectedSpdPackNumbers.add(packNo);
      }
      _spdPackNumbersController.text = _selectedSpdPackNumbers.join(', ');
    });
  }

  void _onSelectAllInStockSpdPacks() {
    setState(() {
      for (final sp in _spdPacks) {
        final no = sp['spdPackNumber'] ?? sp['codeText'];
        if (no != null) _selectedSpdPackNumbers.add(no.toString());
      }
      _spdPackNumbersController.text = _selectedSpdPackNumbers.join(', ');
    });
  }

  void _onClearSpdPackSelection() {
    setState(() {
      _selectedSpdPackNumbers.clear();
      _spdPackNumbersController.clear();
      _reverseScanInputController.clear();
    });
  }

  void _onScanReverseSpdPackCamera() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: 'SPD_BOX_QR',
      onQrScanned: (scannedQr) {
        final clean = scannedQr.replaceAll('MWS|', '').replaceAll('SP|', '').trim();
        if (clean.isNotEmpty) {
          _onAddScannedReversePack(clean);
        }
      },
    );
  }

  void _onAddScannedReversePack(String input) {
    final clean = input.replaceAll('MWS|', '').replaceAll('SP|', '').trim();
    if (clean.isEmpty) return;

    final matched = _spdPacks.firstWhere(
      (sp) => (sp['spdPackNumber'] ?? sp['codeText'] ?? '').toString().toUpperCase() == clean.toUpperCase(),
      orElse: () => null,
    );

    if (matched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warn,
          content: Text('SPD Pack "$clean" was not found in active in-stock warehouse packs.'),
        ),
      );
      return;
    }

    final packNo = (matched['spdPackNumber'] ?? matched['codeText']).toString();
    setState(() {
      _selectedSpdPackNumbers.add(packNo);
      _spdPackNumbersController.text = _selectedSpdPackNumbers.join(', ');
      _reverseScanInputController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        duration: const Duration(milliseconds: 1200),
        content: Text('Added $packNo to re-assembly queue (${_selectedSpdPackNumbers.length} selected)'),
      ),
    );
  }

  void _onConvertSpdToPallet() async {
    List<String> packNumbers = _selectedSpdPackNumbers.toList();

    if (packNumbers.isEmpty && _spdPackNumbersController.text.trim().isNotEmpty) {
      packNumbers = _spdPackNumbersController.text
          .trim()
          .split(',')
          .map((e) => e.replaceAll('MWS|', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (packNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warn,
          content: Text('Please select or scan at least one In-Stock SPD Pack to re-assemble.'),
        ),
      );
      return;
    }

    final targetLocation = _targetLocationController.text.trim().isEmpty ? 'WH1-STG-01' : _targetLocationController.text.trim();

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.post('/conversion/spd-to-pallet', {
      'spdPackNumbers': packNumbers,
      'targetLocationCode': targetLocation,
    });
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final newPallet = res['newPallet'] as Map<String, dynamic>? ?? {};
      final palletNo = newPallet['palletNumber'] ?? 'P26000160';
      final typeSeries = newPallet['typeSeries'] ?? 'P';
      final itemCode = newPallet['itemCode'] ?? 'MXW-17-BLK';
      final packedQty = newPallet['packedQty'] ?? packNumbers.length;
      final masterQr = newPallet['masterQr'] ?? 'MWP|$palletNo';

      setState(() {
        _selectedSpdPackNumbers.clear();
        _spdPackNumbersController.clear();
      });

      _fetchSpdData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text(res['message'] ?? 'Assembled ${packNumbers.length} SPD Packs into Pallet $palletNo!'),
        ),
      );

      // Open Pallet Master Slip Print Preview
      BatchPrintPreviewDialog.show(
        context: context,
        title: 'RE-ASSEMBLED OEM PALLET SLIP ($palletNo)',
        itemCode: itemCode,
        itemDescription: 'OEM Bulk Pallet ($typeSeries Series) • Converted from SPD Stock',
        stickerType: 'PALLET MASTER QR',
        stickers: [
          {
            'codeText': palletNo,
            'serialNumber': palletNo,
            'uniqueQrData': masterQr,
            'primaryDetail': 'Pallet $palletNo ($typeSeries) • Qty: $packedQty Wheels',
            'secondaryDetail': 'Location: $targetLocation • Converted from ${packNumbers.length} SPD Packs',
            'stickerDetails': [
              {'PALLET #': palletNo},
              {'SERIES': typeSeries},
              {'ITEM': itemCode},
              {'QTY': '$packedQty Wheels'},
              {'LOCATION': targetLocation},
              {'SOURCE': '${packNumbers.length} SPD Cartons'}
            ]
          }
        ],
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.danger, content: Text(res['message'] ?? 'Re-assembly failed')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemCodeController.dispose();
    _qtyRequiredController.dispose();
    _customerController.dispose();
    _refController.dispose();
    _requestNoController.dispose();
    _sourcePalletController.dispose();
    _wheelQrController.dispose();
    _spdPackNumbersController.dispose();
    _reverseScanInputController.dispose();
    _targetLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController.length != 3) {
      final oldIndex = _tabController.index.clamp(0, 2);
      _tabController.dispose();
      _tabController = TabController(length: 3, vsync: this, initialIndex: oldIndex);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final tabHeight = isMobile ? 820.0 : 660.0;

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
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

          ResponsiveTabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.add_task_outlined), text: '1. RAISE SPD REQUEST (SR)'),
              Tab(icon: Icon(Icons.qr_code_scanner_outlined), text: '2. HHT SPD PACKING'),
              Tab(icon: Icon(Icons.unarchive_outlined), text: '3. REVERSE (SPD → PALLET)'),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: tabHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Raise SPD Request
                AppCard(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, cardConstraints) {
                        final isNarrow = cardConstraints.maxWidth < 600;

                        final itemField = TextField(
                          controller: _itemCodeController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Item Code',
                            filled: true,
                            fillColor: context.bgSurfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );

                        final qtyField = TextField(
                          controller: _qtyRequiredController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Quantity Required (Wheels)',
                            filled: true,
                            fillColor: context.bgSurfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );

                        final custField = TextField(
                          controller: _customerController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Customer / SPD Reference',
                            filled: true,
                            fillColor: context.bgSurfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );

                        final refField = TextField(
                          controller: _refController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'PO / Schedule Reference',
                            filled: true,
                            fillColor: context.bgSurfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STEP 1 — RAISE SPD CONVERSION REQUEST',
                              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            if (isNarrow) ...[
                              itemField,
                              const SizedBox(height: 12),
                              qtyField,
                              const SizedBox(height: 12),
                              custField,
                              const SizedBox(height: 12),
                              refField,
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(child: itemField),
                                  const SizedBox(width: 16),
                                  Expanded(child: qtyField),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: custField),
                                  const SizedBox(width: 16),
                                  Expanded(child: refField),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: _isLoading ? 'CREATING...' : 'RAISE SPD REQUEST & AUTO-SELECT PALLET',
                                variant: AppButtonVariant.gradient,
                                isLoading: _isLoading,
                                onPressed: _onCreateSpdRequest,
                              ),
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
                            if (_lastCreatedRequest != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'PRINT ALL ${_lastCreatedRequest!['qtyRequired'] ?? 10} SPD STICKERS FOR THIS REQUIREMENT (BATCH)',
                                  icon: Icons.print_outlined,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: () => _onPrintBatchSpdStickersForRequest(_lastCreatedRequest!),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Tab 2: HHT SPD Packing Execution
                AppCard(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, cardConstraints) {
                        final isNarrow = cardConstraints.maxWidth < 600;

                        final reqField = TextField(
                          controller: _requestNoController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'SPD Request Number (SR...)',
                            filled: true,
                            fillColor: context.bgSurfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );

                        final palletField = TextField(
                          controller: _sourcePalletController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Source Pallet Master QR (P / H / PM)',
                            filled: true,
                            fillColor: context.bgSurfaceElevated,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.camera_alt, color: AppColors.ribbonPink),
                              tooltip: 'Scan Source Pallet with Camera',
                              onPressed: _onScanSourcePalletCamera,
                            ),
                          ),
                        );

                        final activeReq = _spdRequests.firstWhere(
                          (r) => r['spdRequestNumber'] == _requestNoController.text.trim(),
                          orElse: () => _lastCreatedRequest ?? {},
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'STEP 2 — VERIFY SPD INFO & GENERATE QR STICKERS',
                                  style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                if (activeReq['status'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.ok.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${activeReq['status']}',
                                      style: const TextStyle(color: AppColors.ok, fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Request Information Summary Card
                            if (activeReq.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SPD Request: ${activeReq['spdRequestNumber']} • Item: ${activeReq['itemCode']}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('Required Qty: ${activeReq['qtyRequired'] ?? 10} Wheels • Customer: ${activeReq['customerName'] ?? "SPD Aftermarket"}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            if (isNarrow) ...[
                              reqField,
                              const SizedBox(height: 12),
                              palletField,
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(child: reqField),
                                  const SizedBox(width: 16),
                                  Expanded(child: palletField),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Explicit Button to Generate and Print QR Stickers
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: 'GENERATE & PRINT SPD QR STICKERS',
                                icon: Icons.qr_code_2,
                                variant: AppButtonVariant.gradient,
                                isLoading: _isLoading,
                                onPressed: _onGenerateAndPrintSpdStickers,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Theme.of(context).dividerColor),
                            const SizedBox(height: 16),

                            Text(
                              'STEP 3 — PACK WHEELS & SEAL CARTONS',
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _wheelQrController,
                                    style: TextStyle(color: context.textPrimary),
                                    onSubmitted: (_) => _onPackSpdWheel(),
                                    decoration: InputDecoration(
                                      labelText: 'Scan Wheel QR on Pallet (MW|P1|...)',
                                      prefixIcon: const Icon(Icons.barcode_reader, color: AppColors.ribbonPink),
                                      filled: true,
                                      fillColor: context.bgSurfaceElevated,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.camera_alt, color: AppColors.ribbonPink),
                                        tooltip: 'Scan Wheel QR with Camera',
                                        onPressed: _onScanSpdWheelCamera,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppButton(
                                  text: isNarrow ? 'SCAN' : 'SCAN CAMERA',
                                  icon: Icons.camera_alt,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: _onScanSpdWheelCamera,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (isNarrow) ...[
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'PACK WHEEL TO SPD CARTON',
                                  icon: Icons.inventory,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: _onPackSpdWheel,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'FINISH SPD JOB & ISSUE RESIDUAL HALF PALLET (H)',
                                  icon: Icons.done_all,
                                  variant: AppButtonVariant.ghost,
                                  onPressed: _onFinishSpdJob,
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      text: 'PACK WHEEL TO SPD CARTON',
                                      icon: Icons.inventory,
                                      variant: AppButtonVariant.secondary,
                                      onPressed: _onPackSpdWheel,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AppButton(
                                      text: 'FINISH SPD JOB & ISSUE RESIDUAL HALF PALLET (H)',
                                      icon: Icons.done_all,
                                      variant: AppButtonVariant.ghost,
                                      onPressed: _onFinishSpdJob,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            Divider(color: Theme.of(context).dividerColor),
                            const SizedBox(height: 12),
                            Text('STOCK EFFECT UPON FINISH (AUTOMATIC):', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('1. Taken wheels become independent SPD Packs (SP26000411...)\n2. Source Pallet closes as Split-Consumed\n3. Remaining wheels re-issued as a new Half Pallet (H26000091) in top-up cycle', style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4)),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Tab 3: Reverse Conversion (SPD Packs -> OEM Pallet)
                AppCard(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, cardConstraints) {
                        final isNarrow = cardConstraints.maxWidth < 600;
                        final inStockPacks = _spdPacks;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header and Count Badge
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'REVERSE FLOW — CONVERT SPD PACKS TO OEM PALLET',
                                  style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.ribbonPink.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${inStockPacks.length} IN-STOCK SPD PACKS',
                                    style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w800, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Explanatory Workflow Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.bgSurfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, color: AppColors.ribbonPink, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'WHAT IS REVERSE CONVERSION?',
                                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Unpacks individual 1-wheel SPD cartons (SP...) and re-assembles them back into an OEM Bulk Pallet (P or H series) with a newly generated Pallet Master QR, restoring them for OEM vehicle assembly shipments.',
                                          style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.35),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'STEP 1 — SCAN OR SELECT IN-STOCK SPD BOXES',
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),

                            // Scanner Input Field
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _reverseScanInputController,
                                    style: TextStyle(color: context.textPrimary),
                                    onSubmitted: (val) => _onAddScannedReversePack(val),
                                    decoration: InputDecoration(
                                      labelText: 'Scan SPD Carton QR (MWS|SP... / SP26000...)',
                                      prefixIcon: const Icon(Icons.barcode_reader, color: AppColors.ribbonPink),
                                      filled: true,
                                      fillColor: context.bgSurfaceElevated,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.camera_alt, color: AppColors.ribbonPink),
                                        tooltip: 'Scan SPD Box with Camera',
                                        onPressed: _onScanReverseSpdPackCamera,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppButton(
                                  text: isNarrow ? 'SCAN' : 'SCAN CAMERA',
                                  icon: Icons.camera_alt,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: _onScanReverseSpdPackCamera,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Quick Select Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppButton(
                                  text: 'SELECT ALL IN-STOCK (${inStockPacks.length})',
                                  icon: Icons.select_all,
                                  variant: AppButtonVariant.ghost,
                                  onPressed: inStockPacks.isEmpty ? null : _onSelectAllInStockSpdPacks,
                                ),
                                AppButton(
                                  text: 'CLEAR (${_selectedSpdPackNumbers.length})',
                                  icon: Icons.clear_all,
                                  variant: AppButtonVariant.ghost,
                                  onPressed: _selectedSpdPackNumbers.isEmpty ? null : _onClearSpdPackSelection,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Interactive SPD Packs List / Grid
                            if (inStockPacks.isEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, color: context.textMuted, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No In-Stock SPD Packs in Warehouse',
                                        style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Raise an SPD request in Tab 1 and pack wheels in Tab 2 to create cartons.',
                                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                constraints: const BoxConstraints(maxHeight: 220),
                                decoration: BoxDecoration(
                                  color: context.bgSurfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: inStockPacks.length,
                                  separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor, height: 1),
                                  itemBuilder: (context, index) {
                                    final pack = inStockPacks[index];
                                    final packNo = (pack['spdPackNumber'] ?? pack['codeText'] ?? 'SP26000411').toString();
                                    final itemCode = (pack['itemCode'] ?? 'MXW-17-BLK').toString();
                                    final isSelected = _selectedSpdPackNumbers.contains(packNo);

                                    return InkWell(
                                      onTap: () => _onToggleSpdPack(packNo),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              activeColor: AppColors.ribbonPink,
                                              onChanged: (_) => _onToggleSpdPack(packNo),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(packNo, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 13), overflow: TextOverflow.ellipsis),
                                                  Text('Item: $itemCode • Carton QR: MWS|$packNo', style: TextStyle(color: context.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.ok.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('IN-STOCK', style: TextStyle(color: AppColors.ok, fontWeight: FontWeight.w800, fontSize: 10)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Divider(color: Theme.of(context).dividerColor),
                            const SizedBox(height: 14),

                            Text(
                              'STEP 2 — DESTINATION PALLET & LOCATION',
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),

                            TextField(
                              controller: _targetLocationController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Target Warehouse Staging Location (e.g. WH1-STG-01)',
                                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.ribbonPink),
                                filled: true,
                                fillColor: context.bgSurfaceElevated,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Dynamic Live Forecast Banner
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.ok.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.ok.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: AppColors.ok, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedSpdPackNumbers.isEmpty
                                          ? 'Select or scan SPD packs above to preview destination pallet creation.'
                                          : '${_selectedSpdPackNumbers.length} SPD Box(es) Selected ➔ Will create Pallet (${_selectedSpdPackNumbers.length >= 4 ? "Full Pallet 'P'" : "Half Pallet 'H'"}) at ${_targetLocationController.text}',
                                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: _isLoading
                                    ? 'RE-ASSEMBLING...'
                                    : 'RE-ASSEMBLE ${_selectedSpdPackNumbers.length} SPD PACKS INTO OEM PALLET & PRINT MASTER QR',
                                icon: Icons.unarchive,
                                variant: AppButtonVariant.gradient,
                                isLoading: _isLoading,
                                onPressed: _selectedSpdPackNumbers.isEmpty ? null : _onConvertSpdToPallet,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
