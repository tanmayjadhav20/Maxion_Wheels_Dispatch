import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/camera_qr_scanner_dialog.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class PalletBuildScreen extends ConsumerStatefulWidget {
  const PalletBuildScreen({super.key});

  @override
  ConsumerState<PalletBuildScreen> createState() => _PalletBuildScreenState();
}

class _PalletBuildScreenState extends ConsumerState<PalletBuildScreen> {
  static const List<Map<String, dynamic>> _defaultMasterItems = [
    {'itemCode': 'MXW-17-BLK', 'description': '17" Gloss Black Rim', 'stdQty': 96, 'wheelsPerLayer': 24},
    {'itemCode': 'MXW-16-BLK', 'description': '16" Matt Black Rim', 'stdQty': 96, 'wheelsPerLayer': 24},
    {'itemCode': 'MXW-18-SLV', 'description': '18" Silver Alloy', 'stdQty': 80, 'wheelsPerLayer': 20},
    {'itemCode': 'MXW-19-WHT', 'description': '19" Premium White', 'stdQty': 80, 'wheelsPerLayer': 20},
    {'itemCode': 'MXW-16-MAT', 'description': '16" Matte Black Stillage', 'stdQty': 96, 'wheelsPerLayer': 24},
  ];

  late final TextEditingController _wheelQrController;
  late final TextEditingController _capacityController;
  late final FocusNode _scannerFocusNode;

  int _packedCount = 0;
  int _stdQty = 96;
  int _currentLayer = 1;
  int _wheelsPerLayer = 24;
  String _activeItem = 'MXW-17-BLK';
  String _palletNumber = 'P26000160';
  bool _isLoading = false;

  List<dynamic> _masterItems = _defaultMasterItems;
  bool _hasHalfPalletAvailable = false;
  String _halfPalletNo = '';
  int _halfPalletQty = 0;
  String _halfPalletLocation = '';

  @override
  void initState() {
    super.initState();
    _wheelQrController = TextEditingController();
    _capacityController = TextEditingController(text: '96');
    _scannerFocusNode = FocusNode();
    _masterItems = _defaultMasterItems;

    _loadMasterItems();
    _fetchActivePallet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scannerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scannerFocusNode.dispose();
    _wheelQrController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterItems() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.getItemsMaster();
      if (res['success'] == true && res['items'] != null && res['items'] is List) {
        final rawList = res['items'] as List;
        final list = rawList.map((i) {
          final m = i is Map ? i : <String, dynamic>{};
          return {
            'itemCode': (m['itemCode'] ?? '').toString(),
            'description': (m['description'] ?? 'Automotive Wheel').toString(),
            'stdQty': (m['stdPalletQty'] as num?)?.toInt() ?? 96,
            'wheelsPerLayer': (m['wheelsPerLayer'] as num?)?.toInt() ?? 24,
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

  void _recalcLayers() {
    final int capacity = _stdQty > 0 ? _stdQty : 96;
    _wheelsPerLayer = (capacity / 4).ceil();
    if (_wheelsPerLayer < 1) _wheelsPerLayer = 1;
    _currentLayer = (_packedCount / _wheelsPerLayer).ceil();
    if (_currentLayer < 1) _currentLayer = 1;
  }

  Future<void> _fetchActivePallet() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.get('/pack/active-pallet');
      if (res['success'] == true && res['activePallet'] != null) {
        final p = res['activePallet'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _palletNumber = (p['palletNumber'] ?? '').toString();
            _activeItem = (p['itemCode'] ?? _activeItem).toString();
            _packedCount = (p['packedQty'] as num?)?.toInt() ?? 0;
            final serverStdQty = (p['stdQty'] as num?)?.toInt() ?? 96;
            _stdQty = serverStdQty;
            _capacityController.text = serverStdQty.toString();
            _recalcLayers();
          });
        }
      }

      final halfRes = await remoteApi.get('/pack/half-pallets');
      if (halfRes['success'] == true && halfRes['halfPallets'] is List) {
        final list = halfRes['halfPallets'] as List;
        final matchingHalf = list.firstWhere(
          (h) => (h is Map && (h['itemCode'] ?? '').toString().toUpperCase() == _activeItem.toUpperCase()),
          orElse: () => null,
        );
        if (mounted) {
          setState(() {
            if (matchingHalf != null && matchingHalf is Map) {
              _hasHalfPalletAvailable = true;
              _halfPalletNo = (matchingHalf['palletNumber'] ?? '').toString();
              _halfPalletQty = (matchingHalf['packedQty'] as num?)?.toInt() ?? 0;
              _halfPalletLocation = (matchingHalf['locationCode'] ?? 'WH1-H-01').toString();
            } else {
              _hasHalfPalletAvailable = false;
            }
          });
        }
      }
    } catch (_) {}
  }

  void _onItemChanged(String newItemCode) async {
    if (newItemCode.trim().isEmpty) return;

    final rawList = _masterItems.isNotEmpty ? _masterItems : _defaultMasterItems;
    final matched = rawList.firstWhere(
      (m) => (m is Map && (m['itemCode'] ?? '').toString() == newItemCode),
      orElse: () => {'itemCode': newItemCode, 'stdQty': _stdQty},
    );

    final newStdQty = (matched is Map ? (matched['stdQty'] as num?)?.toInt() : null) ?? _stdQty;

    setState(() {
      _activeItem = newItemCode;
      _stdQty = newStdQty;
      _capacityController.text = newStdQty.toString();
      _recalcLayers();
      _isLoading = true;
    });

    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.scanWheel(
        _activeItem,
        null,
        palletCapacity: _stdQty,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res['success'] == true && res['activePallet'] != null) {
          final p = res['activePallet'] as Map<String, dynamic>;
          setState(() {
            _palletNumber = (p['palletNumber'] ?? _palletNumber).toString();
            _packedCount = (p['packedQty'] as num?)?.toInt() ?? 0;
            _stdQty = (p['stdQty'] as num?)?.toInt() ?? _stdQty;
            _recalcLayers();
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }

    _fetchActivePallet();
  }

  void _onCapacityChanged(int newCapacity) async {
    if (newCapacity <= 0) return;

    setState(() {
      _stdQty = newCapacity;
      _capacityController.text = newCapacity.toString();
      _recalcLayers();
    });

    try {
      final remoteApi = ref.read(remoteApiProvider);
      await remoteApi.scanWheel(
        _activeItem,
        null,
        palletCapacity: _stdQty,
      );
    } catch (_) {}
  }

  void _onScanWheel([String? inputQr]) async {
    final qr = (inputQr ?? _wheelQrController.text).trim();

    setState(() => _isLoading = true);
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.scanWheel(
        _activeItem,
        qr.isEmpty ? null : qr,
        palletCapacity: _stdQty,
      );
      if (mounted) setState(() => _isLoading = false);

      if (res['success'] == true) {
        final activePallet = res['activePallet'];
        if (mounted) {
          setState(() {
            if (activePallet != null && activePallet is Map) {
              _palletNumber = (activePallet['palletNumber'] ?? _palletNumber).toString();
              _activeItem = (activePallet['itemCode'] ?? _activeItem).toString();
              _packedCount = (activePallet['packedQty'] as num?)?.toInt() ?? (_packedCount + 1);
              _stdQty = (activePallet['stdQty'] as num?)?.toInt() ?? _stdQty;
            } else {
              _packedCount += 1;
            }
            _recalcLayers();
            _wheelQrController.clear();
          });

          _scannerFocusNode.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ok,
              duration: const Duration(milliseconds: 1200),
              content: Text('BEEP! Wheel scanned for ' + _activeItem + '. Count: ' + _packedCount.toString() + ' / ' + _stdQty.toString() + ' (Layer ' + _currentLayer.toString() + ')'),
            ),
          );
        }
      } else {
        if (mounted) {
          _scannerFocusNode.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text((res['message'] ?? 'Scan failed').toString()),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _scannerFocusNode.requestFocus();
      }
    }
  }

  void _onClosePallet() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Close Pallet ' + _palletNumber, style: TextStyle(color: ctx.textPrimary)),
        content: Text(
          'Close pallet ' + _palletNumber + ' with ' + _packedCount.toString() + ' of ' + _stdQty.toString() + ' wheels and save to database.',
          style: TextStyle(color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          AppButton(
            text: 'CONFIRM CLOSE PALLET',
            variant: AppButtonVariant.gradient,
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final remoteApi = ref.read(remoteApiProvider);
                final res = await remoteApi.closePallet('Standard Qty Reached');
                if (mounted) setState(() => _isLoading = false);

                if (res['success'] == true) {
                  final closedPallet = res['closedPallet'];
                  final closedNo = (closedPallet != null && closedPallet is Map ? (closedPallet['palletNumber'] ?? _palletNumber) : _palletNumber).toString();
                  final typeSeries = (closedPallet != null && closedPallet is Map ? (closedPallet['typeSeries'] ?? 'P') : 'P').toString();
                  final packed = (closedPallet != null && closedPallet is Map ? (closedPallet['packedQty'] ?? _packedCount) : _packedCount).toString();
                  final nowIso = DateTime.now().toIso8601String().split('T').first;

                  _fetchActivePallet();

                  if (!mounted) return;
                  PrintPreviewDialog.show(
                    context: context,
                    title: 'PALLET MASTER LABEL PRINT PREVIEW',
                    documentType: PrintDocumentType.palletMaster,
                    qrData: 'MWP|' + closedNo,
                    codeText: 'MWP|' + closedNo,
                    itemCode: _activeItem,
                    itemDescription: 'Standard Wheel Item',
                    primaryDetail: 'Total Wheels: ' + packed + ' / ' + _stdQty.toString(),
                    secondaryDetail: 'Series: ' + typeSeries + ' • Status: STORED',
                    metadataFields: [
                      {'PALLET #': closedNo},
                      {'DATE': nowIso},
                      {'LOCATION': 'WH1-STG-01'},
                    ],
                  );
                }
              } catch (_) {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _onRecallHalfPallet() async {
    if (_halfPalletNo.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.resumeHalfPallet(_halfPalletNo);
      if (mounted) setState(() => _isLoading = false);

      if (res['success'] == true) {
        final activePallet = res['activePallet'];
        if (mounted) {
          setState(() {
            _palletNumber = (activePallet != null && activePallet is Map ? (activePallet['palletNumber'] ?? _palletNumber) : _palletNumber).toString();
            _packedCount = (activePallet != null && activePallet is Map ? (activePallet['packedQty'] as num?)?.toInt() : null) ?? _halfPalletQty;
            _recalcLayers();
            _hasHalfPalletAvailable = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Half Pallet ' + _halfPalletNo + ' loaded! Resuming packing into PM series.')),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCameraScanner() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: _activeItem,
      onQrScanned: (scannedQr) {
        _onScanWheel(scannedQr);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fillPercentage = _stdQty > 0 ? (_packedCount / _stdQty).clamp(0.0, 1.0) : 0.0;
    final bool isPalletFull = _packedCount >= _stdQty && _stdQty > 0;

    final List<dynamic> rawMaster = _masterItems.isNotEmpty ? _masterItems : _defaultMasterItems;
    final List<Map<String, dynamic>> itemList = rawMaster.map((i) {
      if (i is Map) {
        return {
          'itemCode': (i['itemCode'] ?? '').toString(),
          'description': (i['description'] ?? 'Automotive Wheel').toString(),
          'stdQty': (i['stdQty'] as num?)?.toInt() ?? 96,
        };
      }
      return {'itemCode': 'MXW-17-BLK', 'description': '17" Gloss Black Rim', 'stdQty': 96};
    }).toList();

    final bool itemFound = itemList.any((m) => (m['itemCode'] ?? '').toString() == _activeItem);
    final String selectedItem = itemFound ? _activeItem : (itemList.first['itemCode'] ?? 'MXW-17-BLK').toString();

    return GestureDetector(
      onTap: () => _scannerFocusNode.requestFocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: AppTokens.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Modules 3, 4 & 5 — Pack Point & Pallet Build'),
            const SizedBox(height: 8),
            Text(
              'Select item code & configure pallet capacity to start scanning wheels. High-speed floor interface with live counter, layer tracking, auto-close (P/H/PM), and half pallet reuse.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Top Configuration Card: Item Code Selector & Manual Pallet Capacity
            AppCard(
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.ribbonPink.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune, color: AppColors.ribbonPink, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'PACK POINT SPECIFICATION & PALLET CAPACITY',
                              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      StatusPill(
                        label: 'PALLET: ' + _palletNumber,
                        variant: PillVariant.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, cfgConstraints) {
                      final isWide = cfgConstraints.maxWidth > 700;

                      final itemSelectorWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT WHEEL ITEM CODE',
                            style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: ValueKey(selectedItem),
                            initialValue: selectedItem,
                            isExpanded: true,
                            dropdownColor: context.bgSurfaceElevated,
                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              prefixIcon: const Icon(Icons.circle, color: AppColors.ribbonPink, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: itemList.map((item) {
                              final code = (item['itemCode'] ?? '').toString();
                              final desc = (item['description'] ?? 'Automotive Wheel').toString();
                              final std = item['stdQty'] ?? 96;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(code + ' — ' + desc + ' (Std: ' + std.toString() + ')', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _onItemChanged(val);
                              }
                            },
                          ),
                        ],
                      );

                      final capacityWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PALLET CAPACITY (SET MANUALLY)',
                            style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.ribbonPink),
                                tooltip: 'Decrease Capacity',
                                onPressed: () {
                                  final current = int.tryParse(_capacityController.text.trim()) ?? _stdQty;
                                  if (current > 1) {
                                    _onCapacityChanged(current - 1);
                                  }
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
                                  decoration: InputDecoration(
                                    suffixText: 'wheels',
                                    filled: true,
                                    fillColor: context.bgSurfaceElevated,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  ),
                                  onSubmitted: (val) {
                                    final parsed = int.tryParse(val.trim());
                                    if (parsed != null && parsed > 0) {
                                      _onCapacityChanged(parsed);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.ribbonPink),
                                tooltip: 'Increase Capacity',
                                onPressed: () {
                                  final current = int.tryParse(_capacityController.text.trim()) ?? _stdQty;
                                  _onCapacityChanged(current + 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: itemSelectorWidget),
                            const SizedBox(width: 20),
                            Expanded(flex: 4, child: capacityWidget),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          itemSelectorWidget,
                          const SizedBox(height: 14),
                          capacityWidget,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Quick Capacity Presets
                  Row(
                    children: [
                      Text(
                        'QUICK PRESETS:',
                        style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PresetCapacityChip(label: '4 (Sample)', capacity: 4, current: _stdQty, onSelect: _onCapacityChanged),
                              const SizedBox(width: 6),
                              _PresetCapacityChip(label: '48 (Half Pallet)', capacity: 48, current: _stdQty, onSelect: _onCapacityChanged),
                              const SizedBox(width: 6),
                              _PresetCapacityChip(label: '80 (18" Alloy)', capacity: 80, current: _stdQty, onSelect: _onCapacityChanged),
                              const SizedBox(width: 6),
                              _PresetCapacityChip(label: '96 (17" Stillage)', capacity: 96, current: _stdQty, onSelect: _onCapacityChanged),
                              const SizedBox(width: 6),
                              _PresetCapacityChip(label: '120 (Export Box)', capacity: 120, current: _stdQty, onSelect: _onCapacityChanged),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stored Half Pallet Recall Banner (Module 5)
            if (_hasHalfPalletAvailable) ...[
              AppCard(
                showGlow: true,
                child: LayoutBuilder(
                  builder: (context, bannerConstraints) {
                    final isBannerNarrow = bannerConstraints.maxWidth < 650;
                    final iconWidget = Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.warnTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.history_outlined, color: context.warnInk, size: 28),
                    );

                    final textWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATCHING HALF PALLET AVAILABLE — USE IT FIRST!',
                          style: TextStyle(color: context.warnInk, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stored Pallet ' + _halfPalletNo + ' has ' + _halfPalletQty.toString() + '/' + _stdQty.toString() + ' wheels for ' + _activeItem + ' at Location ' + _halfPalletLocation + '. Fetch and scan master QR to merge into PM series!',
                          style: TextStyle(color: context.textSecondary, fontSize: 12),
                        ),
                      ],
                    );

                    final buttonWidget = AppButton(
                      text: 'RECALL & MERGE (PM)',
                      variant: AppButtonVariant.gradient,
                      isLoading: _isLoading,
                      onPressed: _onRecallHalfPallet,
                    );

                    if (isBannerNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              iconWidget,
                              const SizedBox(width: 12),
                              Expanded(child: textWidget),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: buttonWidget),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        iconWidget,
                        const SizedBox(width: 16),
                        Expanded(child: textWidget),
                        const SizedBox(width: 16),
                        buttonWidget,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Main Pack Point Counter Layout (Responsive)
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                Widget leftCounterCard = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            label: isPalletFull ? 'PALLET CAPACITY REACHED' : 'PACKING IN PROGRESS',
                            variant: isPalletFull ? PillVariant.ok : PillVariant.purple,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.ribbonPink.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ITEM: ' + _activeItem,
                              style: TextStyle(color: context.brandInk, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PALLET #' + _palletNumber + ' • TARGET CAPACITY: ' + _stdQty.toString() + ' WHEELS',
                        style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _packedCount.toString(),
                              style: TextStyle(
                                color: isPalletFull ? context.okInk : AppColors.ribbonPink,
                                fontSize: 88,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              ' / ' + _stdQty.toString(),
                              style: TextStyle(
                                color: context.textMuted,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fillPercentage,
                          minHeight: 8,
                          backgroundColor: context.bgSurfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isPalletFull ? context.okInk : AppColors.ribbonPink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'LAYER ' + _currentLayer.toString() + ' OF 4 (' + _wheelsPerLayer.toString() + ' WHEELS / LAYER) • ' + (fillPercentage * 100).toInt().toString() + '% FILLED',
                        style: TextStyle(
                          color: isPalletFull ? context.okInk : context.infoInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          AppButton(
                            text: isPalletFull ? 'CLOSE FULL PALLET & PRINT MASTER QR' : 'CLOSE PALLET',
                            icon: Icons.check_circle_outline,
                            variant: isPalletFull ? AppButtonVariant.gradient : AppButtonVariant.gradient,
                            isLoading: _isLoading,
                            onPressed: _onClosePallet,
                          ),
                          AppButton(
                            text: 'RESET / NEW PALLET',
                            icon: Icons.refresh,
                            variant: AppButtonVariant.ghost,
                            onPressed: () {
                              _onItemChanged(_activeItem);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                Widget rightScannerCard = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LIVE CAMERA & GUN SCANNER',
                            style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            tooltip: 'Open Live Camera QR Scanner',
                            icon: const Icon(Icons.camera_alt, color: AppColors.ribbonPink),
                            onPressed: _openCameraScanner,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan Wheel QR with device camera viewfinder or HHT gun scanner (Target: ' + _activeItem + '):',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'OPEN LIVE CAMERA QR SCANNER',
                        icon: Icons.camera_alt_outlined,
                        isFullWidth: true,
                        variant: AppButtonVariant.gradient,
                        onPressed: _openCameraScanner,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR HARDWARE SCANNER / MANUAL', style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _wheelQrController,
                        focusNode: _scannerFocusNode,
                        autofocus: true,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'WHEEL QR / BARCODE SCANNER INPUT',
                          labelStyle: TextStyle(color: context.textMuted),
                          prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink),
                          suffixIcon: IconButton(
                            tooltip: 'Clear Input',
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _wheelQrController.clear();
                              _scannerFocusNode.requestFocus();
                            },
                          ),
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (val) => _onScanWheel(val),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'SCAN WHEEL (OR PULL HHT TRIGGER)',
                        icon: Icons.flash_on,
                        isFullWidth: true,
                        isLoading: _isLoading,
                        onPressed: () => _onScanWheel(),
                      ),
                    ],
                  ),
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: leftCounterCard),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: rightScannerCard),
                    ],
                  );
                }

                return Column(
                  children: [
                    leftCounterCard,
                    const SizedBox(height: 24),
                    rightScannerCard,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCapacityChip extends StatelessWidget {
  final String label;
  final int capacity;
  final int current;
  final ValueChanged<int> onSelect;

  const _PresetCapacityChip({
    required this.label,
    required this.capacity,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = capacity == current;
    return InkWell(
      onTap: () => onSelect(capacity),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ribbonPink.withValues(alpha: 0.2) : context.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.ribbonPink : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.ribbonPink : context.textPrimary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
