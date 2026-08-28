import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/camera_qr_scanner_dialog.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class QualityInspectionScreen extends ConsumerStatefulWidget {
  const QualityInspectionScreen({super.key});

  @override
  ConsumerState<QualityInspectionScreen> createState() => _QualityInspectionScreenState();
}

class _QualityInspectionScreenState extends ConsumerState<QualityInspectionScreen> {
  final _palletQrController = TextEditingController();
  final _inspectionRefController = TextEditingController();
  final _removedWheelController = TextEditingController();
  final _replacementWheelController = TextEditingController();

  bool _isLoading = false;
  String _palletStatus = 'AVAILABLE';
  String _defectReason = 'Sample Taken (Destructive Test)';
  String _activeItemCode = 'MXW-17-BLK';

  List<dynamic> _availablePallets = const [];
  List<dynamic> _palletWheels = const [];
  List<dynamic> _qaHistory = const [];
  List<Map<String, String>> _removedWheels = const [];
  List<String> _replacementWheelsList = const [];

  @override
  void initState() {
    super.initState();
    _inspectionRefController.text = 'QA-${DateTime.now().year.toString().substring(2)}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _loadInitialData();
    _fetchQaHistory();
  }

  @override
  void dispose() {
    _palletQrController.dispose();
    _inspectionRefController.dispose();
    _removedWheelController.dispose();
    _replacementWheelController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.getWarehouseMap();
      if (res['success'] == true && res['pallets'] != null) {
        final rawPallets = res['pallets'] as List<dynamic>? ?? const [];
        setState(() {
          _availablePallets = List<dynamic>.from(rawPallets);
        });

        final stored = _availablePallets.firstWhere(
          (p) => p is Map && (p['status'] == 'STORED' || p['status'] == 'OPEN' || p['status'] == 'STORED_HALF'),
          orElse: () => _availablePallets.isNotEmpty ? _availablePallets.first : null,
        );
        if (stored != null && stored is Map && _palletQrController.text.isEmpty) {
          final pNo = (stored['palletNumber'] ?? '').toString();
          _palletQrController.text = pNo;
          _activeItemCode = (stored['itemCode'] ?? 'MXW-17-BLK').toString();
          _loadPalletDetails(pNo);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPalletDetails(String palletNo) async {
    if (palletNo.isEmpty) return;
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.traceLookup(palletNo);
      if (res['success'] == true && res['details'] != null) {
        final details = res['details'] as Map<String, dynamic>;
        setState(() {
          _activeItemCode = (details['itemCode'] ?? _activeItemCode).toString();
          _palletStatus = (details['status'] ?? _palletStatus).toString();
          if (details['wheels'] != null && details['wheels'] is List) {
            _palletWheels = List<dynamic>.from(details['wheels'] as List);
          }
        });
      }
    } catch (_) {}
  }

  void _fetchQaHistory() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.getInspectionHistory();
    if (res['success'] == true && res['inspections'] != null) {
      setState(() {
        _qaHistory = List<dynamic>.from(res['inspections'] as List);
      });
    }
  }

  void _onScanPalletCamera() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: 'PALLET_QA',
      onQrScanned: (scannedQr) {
        final clean = scannedQr.replaceAll('MWP|', '').replaceAll('MWR|', '').trim();
        setState(() {
          _palletQrController.text = clean;
        });
        _loadPalletDetails(clean);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ok,
            duration: const Duration(milliseconds: 1200),
            content: Text('Scanned Pallet: $clean'),
          ),
        );
      },
    );
  }

  void _onOpenPalletForInspection() async {
    final palletNo = _palletQrController.text.trim();
    if (palletNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or select Pallet Master QR first'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.openPalletForInspection(
      palletNo,
      reason: _defectReason,
      inspectionRef: _inspectionRefController.text.trim().isNotEmpty ? _inspectionRefController.text.trim() : null,
    );
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _palletStatus = 'UNDER_QA_INSPECTION';
        if (res['inspectionRecord']?['inspectionRef'] != null) {
          _inspectionRefController.text = res['inspectionRecord']['inspectionRef'].toString();
        }
      });

      _loadPalletDetails(palletNo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Pallet locked under QA Inspection.'),
          backgroundColor: AppColors.warn,
        ),
      );
      _fetchQaHistory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to open pallet for QA'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _onScanRemovedWheelCamera() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: _activeItemCode,
      onQrScanned: (scannedQr) {
        final qr = scannedQr.trim();
        if (qr.isNotEmpty) {
          _addRemovedWheel(qr);
        }
      },
    );
  }

  void _addRemovedWheel(String wheelQr) {
    if (wheelQr.isEmpty) return;
    if (_removedWheels.any((w) => w['qr'] == wheelQr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wheel $wheelQr is already logged for removal.'), backgroundColor: AppColors.warn),
      );
      return;
    }

    final updated = List<Map<String, String>>.from(_removedWheels);
    updated.add({
      'qr': wheelQr,
      'reason': _defectReason,
    });

    setState(() {
      _removedWheels = updated;
      _removedWheelController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        duration: const Duration(milliseconds: 1200),
        content: Text('Removed wheel logged: $wheelQr [$_defectReason]'),
      ),
    );
  }

  void _onScanReplacementWheelCamera() {
    CameraQrScannerDialog.show(
      context: context,
      activeItemCode: _activeItemCode,
      onQrScanned: (scannedQr) {
        final qr = scannedQr.trim();
        if (qr.isNotEmpty && !_replacementWheelsList.contains(qr)) {
          final updated = List<String>.from(_replacementWheelsList);
          updated.add(qr);
          setState(() {
            _replacementWheelsList = updated;
            _replacementWheelController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ok,
              duration: const Duration(milliseconds: 1200),
              content: Text('Replacement wheel scanned: $qr'),
            ),
          );
        }
      },
    );
  }

  void _onSwapWheels() async {
    final palletNo = _palletQrController.text.trim();
    if (palletNo.isEmpty) return;

    if (_removedWheels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or select at least one removed wheel first.'), backgroundColor: AppColors.warn),
      );
      return;
    }

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.inspectAndReplaceWheels(
      palletNo,
      _removedWheels.map((w) => w['qr']!).toList(),
      reason: _defectReason,
    );
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Replacement wheels inserted from current production batch.'),
          backgroundColor: AppColors.ok,
        ),
      );
      _loadPalletDetails(palletNo);
      _fetchQaHistory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Wheel swap failed'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _onCloseInspection(bool closeAsShort) async {
    final palletNum = _palletQrController.text.trim();
    if (palletNum.isEmpty) return;

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.closeQaInspection(
      palletNum,
      closeShort: closeAsShort,
    );
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _palletStatus = 'AVAILABLE';
        _palletQrController.clear();
        _removedWheels = const [];
        _replacementWheelsList = const [];
        _palletWheels = const [];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'QA Inspection sealed and pallet released!'),
          backgroundColor: AppColors.ok,
        ),
      );
      _fetchQaHistory();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to close QA inspection'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _palletStatus == 'UNDER_QA_INSPECTION';

    final safeAvailablePallets = _availablePallets;
    final safePalletWheels = _palletWheels;
    final safeQaHistory = _qaHistory;
    final safeRemovedWheels = _removedWheels;

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 11 — Quality Inspection & Wheel Replacement (SSR Section 7)'),
          const SizedBox(height: 8),
          Text(
            'Scan pallet QR, lock under QA inspection, scan out removed wheels with barcode/camera scanner, insert fresh wheels from production, and re-seal pallet with revision label (R1) or issue as Half Pallet (H).',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final isDesktop = constraints.maxWidth > 900;

              final qaCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1 Header
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.ribbonPink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.qr_code_scanner, color: AppColors.ribbonPink, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'STEP 1 — SCAN & LOCK PALLET FOR QA AUDIT',
                              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        StatusPill(
                          label: isLocked ? 'LOCKED (UNDER QA)' : 'AVAILABLE',
                          variant: isLocked ? PillVariant.warn : PillVariant.ok,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pallet Input with Camera Scanner Button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _palletQrController,
                            style: TextStyle(color: context.textPrimary),
                            onSubmitted: _loadPalletDetails,
                            decoration: InputDecoration(
                              labelText: 'Pallet Master QR / Pallet No (P / H / PM)',
                              prefixIcon: const Icon(Icons.inventory_2, color: AppColors.ribbonPink),
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.camera_alt, color: AppColors.ribbonPink),
                                tooltip: 'Scan Pallet QR with Camera',
                                onPressed: _onScanPalletCamera,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: isNarrow ? 'SCAN' : 'SCAN CAMERA',
                          icon: Icons.camera_alt,
                          variant: AppButtonVariant.secondary,
                          onPressed: _onScanPalletCamera,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Pallet Dropdown Picker
                    if (safeAvailablePallets.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: safeAvailablePallets.any((p) => p is Map && p['palletNumber'] == _palletQrController.text.trim())
                            ? _palletQrController.text.trim()
                            : null,
                        isExpanded: true,
                        dropdownColor: context.bgSurfaceElevated,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Quick Select Pallet from Warehouse Database',
                          filled: true,
                          fillColor: context.bgSurfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: safeAvailablePallets.map((p) {
                          if (p is! Map) {
                            return const DropdownMenuItem<String>(value: '', child: Text('Pallet'));
                          }
                          final pNo = (p['palletNumber'] ?? '').toString();
                          final item = (p['itemCode'] ?? '').toString();
                          final qty = (p['packedQty'] ?? 0).toString();
                          final status = (p['status'] ?? '').toString();
                          return DropdownMenuItem<String>(
                            value: pNo,
                            child: Text('$pNo • $item (Qty: $qty) [$status]', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null && val.isNotEmpty) {
                            setState(() => _palletQrController.text = val);
                            _loadPalletDetails(val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: _inspectionRefController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'QA Inspection Reference Number',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1 Actions
                    if (isNarrow) ...[
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: _isLoading ? 'LOCKING...' : 'OPEN PALLET & LOCK FROM MOVEMENTS',
                          icon: Icons.lock_clock,
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: _onOpenPalletForInspection,
                        ),
                      ),
                    ] else ...[
                      AppButton(
                        text: _isLoading ? 'LOCKING...' : 'OPEN PALLET & LOCK FROM MOVEMENTS',
                        icon: Icons.lock_clock,
                        variant: AppButtonVariant.gradient,
                        isLoading: _isLoading,
                        onPressed: _onOpenPalletForInspection,
                      ),
                    ],

                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    // Step 2: Scan Out Removed Wheels
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.warn.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.remove_circle_outline, color: AppColors.warn, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'STEP 2 — SCAN OUT REMOVED WHEELS',
                              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          '${safeRemovedWheels.length} Wheels Removed',
                          style: const TextStyle(color: AppColors.ribbonPink, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Defect Reason Selector
                    DropdownButtonFormField<String>(
                      value: _defectReason,
                      isExpanded: true,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Defect / Removal Reason',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Sample Taken (Destructive Test)', child: Text('Sample Taken (Destructive Test)')),
                        DropdownMenuItem(value: 'Defect Found (Paint Blemish)', child: Text('Defect Found (Paint Blemish)')),
                        DropdownMenuItem(value: 'Dimensional Variation', child: Text('Dimensional Variation')),
                        DropdownMenuItem(value: 'Sent for Rework', child: Text('Sent for Rework')),
                        DropdownMenuItem(value: 'Scrap', child: Text('Scrap')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _defectReason = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Wheel Scanner Input & Camera Scanner Button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _removedWheelController,
                            style: TextStyle(color: context.textPrimary),
                            onSubmitted: _addRemovedWheel,
                            decoration: InputDecoration(
                              hintText: 'Scan wheel QR (MW|P1|...) or Serial...',
                              prefixIcon: const Icon(Icons.barcode_reader, color: AppColors.warn),
                              filled: true,
                              fillColor: context.bgSurfaceElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.camera_alt, color: AppColors.ribbonPink),
                                tooltip: 'Scan Wheel QR with Camera',
                                onPressed: _onScanRemovedWheelCamera,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: isNarrow ? 'SCAN' : 'SCAN WHEEL QR',
                          icon: Icons.camera_alt,
                          variant: AppButtonVariant.secondary,
                          onPressed: _onScanRemovedWheelCamera,
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: 'ADD',
                          icon: Icons.add,
                          variant: AppButtonVariant.ghost,
                          onPressed: () => _addRemovedWheel(_removedWheelController.text.trim()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Select from Pallet Wheels
                    if (safePalletWheels.isNotEmpty) ...[
                      Text('Or Tap Wheel on this Pallet to Remove:', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 75,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: safePalletWheels.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (ctx, idx) {
                            final w = safePalletWheels[idx];
                            if (w is! Map) return const SizedBox.shrink();
                            final qr = (w['wheelQr'] ?? '').toString();
                            final serial = (w['serialNumber'] ?? 'SN-${idx + 1}').toString();
                            final isRemoved = safeRemovedWheels.any((rw) => rw['qr'] == qr);

                            return InkWell(
                              onTap: isRemoved ? null : () => _addRemovedWheel(qr.isNotEmpty ? qr : serial),
                              child: Container(
                                width: 130,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isRemoved ? AppColors.danger.withValues(alpha: 0.15) : context.bgSurfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isRemoved ? AppColors.danger : Theme.of(context).dividerColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('SN: $serial', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(isRemoved ? 'REMOVED' : 'TAP TO REMOVE', style: TextStyle(color: isRemoved ? AppColors.danger : AppColors.ok, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Visual Chips for Logged Removed Wheels
                    if (safeRemovedWheels.isNotEmpty) ...[
                      const Text('Removed Wheels Logged:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: safeRemovedWheels.map((rw) {
                          return Chip(
                            backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                            side: const BorderSide(color: AppColors.danger),
                            label: Text('${rw['qr']} [${rw['reason']}]', style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                            deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                            onDeleted: () {
                              final updated = List<Map<String, String>>.from(_removedWheels);
                              updated.removeWhere((w) => w['qr'] == rw['qr']);
                              setState(() {
                                _removedWheels = updated;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 16),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    // Step 3: Scan In Replacement Wheels
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppColors.ok.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.add_circle_outline, color: AppColors.ok, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'STEP 3 — SCAN IN REPLACEMENT WHEELS',
                              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        AppButton(
                          text: isNarrow ? 'SCAN QR' : 'SCAN REPLACEMENT QR',
                          icon: Icons.camera_alt,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onScanReplacementWheelCamera,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: isNarrow ? double.infinity : null,
                      child: AppButton(
                        text: 'AUTO-SWAP & INSERT REPLACEMENTS FROM CURRENT BATCH',
                        icon: Icons.autorenew,
                        variant: AppButtonVariant.gradient,
                        onPressed: _onSwapWheels,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    // Step 4: Close & Re-Seal Pallet
                    Text(
                      'STEP 4 — CLOSE QA INSPECTION & RE-SEAL PALLET',
                      style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isNarrow ? double.infinity : null,
                          child: AppButton(
                            text: 'RE-SEAL FULL PALLET (REVISION LABEL R1/R2)',
                            icon: Icons.verified,
                            variant: AppButtonVariant.gradient,
                            onPressed: () => _onCloseInspection(false),
                          ),
                        ),
                        SizedBox(
                          width: isNarrow ? double.infinity : null,
                          child: AppButton(
                            text: 'CLOSE SHORT AS HALF PALLET (H)',
                            icon: Icons.warning_amber_rounded,
                            variant: AppButtonVariant.danger,
                            onPressed: () => _onCloseInspection(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final historyCard = AppCard(
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
                          'RECENT QA AUDIT LOG',
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        AppButton(
                          text: 'EXPORT EXCEL',
                          icon: Icons.table_chart_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: () {
                            exportToExcel(
                              context,
                              'QA Audit & Inspection Log',
                              ['PALLET #', 'DEFECT REASON', 'WHEELS REPLACED', 'INSPECTOR', 'STATUS'],
                              safeQaHistory.map<List<String>>((h) => [
                                '${h['palletNumber']}',
                                '${h['reason']}',
                                '${h['replacedWheelsCount'] ?? 1} Wheels',
                                '${h['inspectorName']}',
                                '${h['status'] ?? "COMPLETED"}',
                              ]).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (safeQaHistory.isEmpty)
                      const Padding(padding: EdgeInsets.all(16), child: Text('No QA inspections logged yet.'))
                    else
                      Column(
                        children: safeQaHistory.map((h) {
                          if (h is! Map) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: context.bgSurfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.verified, color: AppColors.ok),
                              title: Text('Pallet ${h['palletNumber'] ?? ""}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                              subtitle: Text('${h['reason']} • ${h['inspectorName']}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                              trailing: const StatusPill(label: 'COMPLETED', variant: PillVariant.ok),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: qaCard),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: historyCard),
                  ],
                );
              }

              return Column(
                children: [
                  qaCard,
                  const SizedBox(height: 24),
                  historyCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
