import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/print_sticker_helper.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/print_preview_dialog.dart';
import '../../widgets/section_title.dart';

class PalletBuildScreen extends ConsumerStatefulWidget {
  const PalletBuildScreen({super.key});

  @override
  ConsumerState<PalletBuildScreen> createState() => _PalletBuildScreenState();
}

class _PalletBuildScreenState extends ConsumerState<PalletBuildScreen> {
  final _wheelQrController = TextEditingController();
  int _packedCount = 37;
  final int _stdQty = 96;
  int _currentLayer = 2;
  String _activeItem = 'MXW-17-BLK';
  String _palletNumber = 'P26000148';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchActivePallet();
  }

  Future<void> _fetchActivePallet() async {
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.get('/pack/active-pallet');
    if (res['success'] == true && res['activePallet'] != null) {
      final p = res['activePallet'];
      setState(() {
        _palletNumber = p['palletNumber'] ?? _palletNumber;
        _activeItem = p['itemCode'] ?? _activeItem;
        _packedCount = p['packedQty'] ?? 0;
        _currentLayer = (_packedCount / 24).ceil();
        if (_currentLayer < 1) _currentLayer = 1;
      });
    }
  }

  void _onPrintWheelQrBatch() {
    final countController = TextEditingController(text: '$_stdQty');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Row(
          children: [
            const Icon(Icons.qr_code_2, color: AppColors.ribbonPink),
            const SizedBox(width: 10),
            Text('BATCH WHEEL STICKER PRINTING', style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify quantity of Wheel QR stickers to print for Item $_activeItem:',
              style: TextStyle(color: ctx.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'PALLET WHEEL STICKERS COUNT',
                labelStyle: TextStyle(color: ctx.textMuted),
                suffixText: 'wheels',
                filled: true,
                fillColor: ctx.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ribbonPink),
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('PRINT ALL STICKERS (CTRL+P)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              final reqCount = int.tryParse(countController.text) ?? _stdQty;
              Navigator.pop(ctx);

              final baseSerial = DateTime.now().millisecondsSinceEpoch;
              const dateStr = '260822';
              final stickers = List.generate(reqCount, (i) {
                final serialStr = (baseSerial + i).toString();
                final serial = serialStr.length > 8 ? serialStr.substring(serialStr.length - 8) : serialStr.padLeft(8, '0');
                final wheelQr = 'MW|P1|$_activeItem|$serial|$dateStr|A|PL2';
                return {
                  'uniqueQrData': wheelQr,
                  'codeText': wheelQr,
                  'serialNumber': serial,
                  'wheelIndex': i + 1,
                  'totalBatchCount': reqCount,
                  'stickerDetails': [
                    {'SERIAL': serial},
                    {'WHEEL NO': '${i + 1} of $reqCount'},
                    {'DATE': '2026-08-22'},
                    {'WORK POINT': 'Pack Point #1'},
                  ],
                };
              });

              if (_wheelQrController.text.isEmpty && stickers.isNotEmpty) {
                _wheelQrController.text = stickers.first['uniqueQrData'] as String;
              }

              openPrintableStickerBatch(
                context: context,
                stickerType: 'WHEEL QR STICKER',
                itemCode: _activeItem,
                itemDescription: '17 Inch Steel Wheel - Gloss Black',
                stickers: stickers,
              );
            },
          ),
        ],
      ),
    );
  }

  void _onScanWheel() async {
    final qr = _wheelQrController.text.trim();

    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.scanWheel(_activeItem, qr.isEmpty ? null : qr);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final activePallet = res['activePallet'];
      setState(() {
        _packedCount = activePallet?['packedQty'] ?? (_packedCount + 1);
        _currentLayer = (_packedCount / 24).ceil();
        if (_currentLayer < 1) _currentLayer = 1;
        _wheelQrController.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ok,
          content: Text('BEEP! Wheel scanned. Count: $_packedCount / $_stdQty (Layer $_currentLayer)'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(res['message'] ?? 'Scan failed'),
        ),
      );
    }
  }

  void _onClosePallet() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Close Pallet $_palletNumber', style: TextStyle(color: ctx.textPrimary)),
        content: Text(
          'Close pallet $_palletNumber with $_packedCount of $_stdQty wheels and save to database.',
          style: TextStyle(color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ribbonPink),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final remoteApi = ref.read(remoteApiProvider);
              final res = await remoteApi.closePallet('Shift Complete / Shift End');
              setState(() => _isLoading = false);

              if (res['success'] == true) {
                final closedPallet = res['closedPallet'];
                final closedNo = closedPallet?['palletNumber'] ?? _palletNumber;
                final typeSeries = closedPallet?['typeSeries'] ?? 'P';

                _fetchActivePallet();

                if (!mounted) return;
                PrintPreviewDialog.show(
                  context: context,
                  title: 'PALLET MASTER LABEL PRINT PREVIEW',
                  documentType: PrintDocumentType.palletMaster,
                  qrData: 'MWP|$closedNo',
                  codeText: 'MWP|$closedNo',
                  itemCode: _activeItem,
                  itemDescription: '17 Inch Steel Wheel - Gloss Black',
                  primaryDetail: 'Total Wheels: ${closedPallet?['packedQty']} / $_stdQty',
                  secondaryDetail: 'Series: $typeSeries • Status: STORED',
                  metadataFields: [
                    {'PALLET #': closedNo},
                    {'DATE': '2026-08-22'},
                    {'LOCATION': 'WH1-STG-01'},
                  ],
                );
              }
            },
            child: const Text('CONFIRM CLOSE & PRINT MASTER QR'),
          ),
        ],
      ),
    );
  }

  void _onRecallHalfPallet() async {
    setState(() => _isLoading = true);
    final remoteApi = ref.read(remoteApiProvider);
    final res = await remoteApi.resumeHalfPallet('H26000037');
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final activePallet = res['activePallet'];
      setState(() {
        _palletNumber = activePallet?['palletNumber'] ?? 'PM26000012';
        _packedCount = activePallet?['packedQty'] ?? 48;
        _currentLayer = (_packedCount / 24).ceil();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Half Pallet H26000037 loaded! Resuming packing at 48/96 into PM series.')),
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
          const SectionTitle(title: 'Modules 3, 4 & 5 — Pack Point & Pallet Build'),
          const SizedBox(height: 8),
          Text(
            'Scan wheels onto pallet. High-speed floor interface with large counter, layer tracking, auto-close (P/H/PM), and half pallet reuse.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Stored Half Pallet Recall Banner (Module 5)
          AppCard(
            showGlow: true,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warnTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_outlined, color: AppColors.warn, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HALF PALLET AVAILABLE — USE IT FIRST!',
                        style: TextStyle(color: AppColors.warn, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stored Pallet H26000037 has 48/96 wheels at Location WH1-H-01-HB (Age: 1 day). Fetch and scan master QR to merge into PM series!',
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  text: 'RECALL & MERGE (PM)',
                  variant: AppButtonVariant.gradient,
                  isLoading: _isLoading,
                  onPressed: _onRecallHalfPallet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Pack Point Counter Layout (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;

              Widget leftCounterCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const StatusPill(label: 'PACK POINT #1 ACTIVE', variant: PillVariant.ok),
                    const SizedBox(height: 16),
                    Text(
                      'CURRENT ITEM: $_activeItem • PALLET: $_palletNumber',
                      style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    // Gigantic Count Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_packedCount',
                          style: const TextStyle(
                            color: AppColors.ribbonPink,
                            fontSize: 88,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ' / $_stdQty',
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'LAYER $_currentLayer OF 4 (24 WHEELS / LAYER)',
                      style: const TextStyle(color: AppColors.ok, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        AppButton(
                          text: 'PRINT WHEEL QR STICKERS (BATCH 96)',
                          icon: Icons.print_outlined,
                          variant: AppButtonVariant.ghost,
                          onPressed: _onPrintWheelQrBatch,
                        ),
                        AppButton(
                          text: 'CLOSE PALLET',
                          icon: Icons.check_circle_outline,
                          variant: AppButtonVariant.gradient,
                          isLoading: _isLoading,
                          onPressed: _onClosePallet,
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
                    Text(
                      'HANDHELD GUN SCANNER',
                      style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Simulate hardware scanner trigger or manual key-in:',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _wheelQrController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'WHEEL QR / BARCODE',
                        prefixIcon: Icon(Icons.qr_code, color: AppColors.ribbonPink),
                      ),
                      onSubmitted: (_) => _onScanWheel(),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'SIMULATE HARDWARE TRIGGER SCAN',
                      icon: Icons.flash_on,
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _onScanWheel,
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
    );
  }
}
