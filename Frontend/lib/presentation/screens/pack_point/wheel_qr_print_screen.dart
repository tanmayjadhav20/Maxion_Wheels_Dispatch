import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/utils/export_helper.dart';
import '../../../core/utils/print_sticker_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pills.dart';
import '../../widgets/section_title.dart';

class WheelQrPrintScreen extends ConsumerStatefulWidget {
  const WheelQrPrintScreen({super.key});

  @override
  ConsumerState<WheelQrPrintScreen> createState() => _WheelQrPrintScreenState();
}

class _WheelQrPrintScreenState extends ConsumerState<WheelQrPrintScreen> {
  final _countController = TextEditingController(text: '96');
  final _customItemController = TextEditingController();
  
  String _selectedItemCode = 'MXW-17-BLK';
  String _selectedShift = 'A';
  String _selectedLine = 'PL2';
  final DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _masterItems = const [
    {'itemCode': 'MXW-17-BLK', 'description': '17" Gloss Black Rim', 'stdQty': 96},
    {'itemCode': 'MXW-16-BLK', 'description': '16" Matt Black Rim', 'stdQty': 96},
    {'itemCode': 'MXW-18-SLV', 'description': '18" Silver Alloy', 'stdQty': 80},
    {'itemCode': 'MXW-19-WHT', 'description': '19" Premium White', 'stdQty': 80},
    {'itemCode': 'MXW-16-MAT', 'description': '16" Matte Black Stillage', 'stdQty': 96},
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _countController.dispose();
    _customItemController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.getItemsMaster();
      if (res['success'] == true && res['items'] != null) {
        final list = (res['items'] as List<dynamic>).map((i) => {
          'itemCode': (i['itemCode'] ?? '').toString(),
          'description': (i['description'] ?? 'Automotive Wheel').toString(),
          'stdQty': i['stdPalletQty'] ?? 96,
        }).toList();

        setState(() {
          _masterItems = list;
          if (_masterItems.isNotEmpty && !_masterItems.any((m) => m['itemCode'] == _selectedItemCode)) {
            _selectedItemCode = _masterItems.first['itemCode'];
          }
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String _getPreviewQrData() {
    final now = _selectedDate;
    final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    const serial = '00000001';
    final item = _selectedItemCode.isNotEmpty ? _selectedItemCode : 'MXW-17-BLK';
    return 'MW|P1|$item|$serial|$dateStr|$_selectedShift|$_selectedLine';
  }

  void _onGenerateAndPrint() {
    final count = int.tryParse(_countController.text.trim()) ?? 96;
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity of stickers'), backgroundColor: AppColors.warn),
      );
      return;
    }

    final now = _selectedDate;
    final baseSerial = DateTime.now().millisecondsSinceEpoch;
    final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final dateIsoStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final item = _selectedItemCode;

    final stickers = List.generate(count, (i) {
      final serialStr = (baseSerial + i).toString();
      final serial = serialStr.length > 8 ? serialStr.substring(serialStr.length - 8) : serialStr.padLeft(8, '0');
      final wheelQr = 'MW|P1|$item|$serial|$dateStr|$_selectedShift|$_selectedLine';

      return {
        'uniqueQrData': wheelQr,
        'codeText': wheelQr,
        'serialNumber': serial,
        'wheelIndex': i + 1,
        'totalBatchCount': count,
        'stickerDetails': [
          {'SERIAL': serial},
          {'WHEEL NO': '${i + 1} of $count'},
          {'DATE': dateIsoStr},
          {'SHIFT / LINE': 'Shift $_selectedShift / $_selectedLine'},
        ],
      };
    });

    final matchedItem = _masterItems.firstWhere((m) => m['itemCode'] == item, orElse: () => {'description': 'Wheel Assembly'});

    openPrintableStickerBatch(
      context: context,
      stickerType: 'WHEEL QR STICKER',
      itemCode: item,
      itemDescription: matchedItem['description'] ?? 'Automotive Wheel Assembly',
      stickers: stickers,
    );
  }

  void _onExportBatchCsv() {
    final count = int.tryParse(_countController.text.trim()) ?? 96;
    final now = _selectedDate;
    final baseSerial = DateTime.now().millisecondsSinceEpoch;
    final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final dateIsoStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final item = _selectedItemCode;

    final headers = ['Index', 'Item Code', 'Serial Number', 'Date', 'Shift', 'Line', 'Full QR Data'];
    final rows = List.generate(count, (i) {
      final serialStr = (baseSerial + i).toString();
      final serial = serialStr.length > 8 ? serialStr.substring(serialStr.length - 8) : serialStr.padLeft(8, '0');
      final wheelQr = 'MW|P1|$item|$serial|$dateStr|$_selectedShift|$_selectedLine';

      return [
        (i + 1).toString(),
        item,
        serial,
        dateIsoStr,
        _selectedShift,
        _selectedLine,
        wheelQr,
      ];
    });

    exportToExcel(
      context,
      'Wheel_QR_Batch_${item}_$dateStr',
      headers,
      rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewQr = _getPreviewQrData();

    return SingleChildScrollView(
      padding: AppTokens.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Module 2 — Wheel QR & Barcode Generation Terminal'),
          const SizedBox(height: 6),
          Text(
            'Generate and mass-print unique QR stickers for individual wheels based on production inputs before scanning and building pallets at the pack point.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final isWide = constraints.maxWidth > 850;

              final shiftDropdown = DropdownButtonFormField<String>(
                value: _selectedShift,
                isExpanded: true,
                dropdownColor: context.bgSurfaceElevated,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'PRODUCTION SHIFT',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Shift A (06:00 - 14:00)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'B', child: Text('Shift B (14:00 - 22:00)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'C', child: Text('Shift C (22:00 - 06:00)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _selectedShift = v ?? 'A'),
              );

              final lineDropdown = DropdownButtonFormField<String>(
                value: _selectedLine,
                isExpanded: true,
                dropdownColor: context.bgSurfaceElevated,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  labelText: 'PAINT LINE',
                  filled: true,
                  fillColor: context.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'PL1', child: Text('Paint Line 1 (PL1)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'PL2', child: Text('Paint Line 2 (PL2)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'ASSY1', child: Text('Assembly Point 1', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _selectedLine = v ?? 'PL2'),
              );

              final inputCard = AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BATCH SPECIFICATION INPUTS',
                      style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Item Selector
                    DropdownButtonFormField<String>(
                      value: _masterItems.any((m) => m['itemCode'] == _selectedItemCode) ? _selectedItemCode : null,
                      isExpanded: true,
                      dropdownColor: context.bgSurfaceElevated,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'SELECT ITEM CODE',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _masterItems.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['itemCode'] as String,
                          child: Text('${item['itemCode']} — ${item['description']}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedItemCode = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity Input + Quick Presets
                    TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'STICKER QUANTITY TO GENERATE',
                        suffixText: 'stickers',
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PresetButton(label: '48 (Half)', count: 48, onSelect: (c) => setState(() => _countController.text = c.toString())),
                        _PresetButton(label: '96 (1 Pallet)', count: 96, onSelect: (c) => setState(() => _countController.text = c.toString())),
                        _PresetButton(label: '192 (2 Pallets)', count: 192, onSelect: (c) => setState(() => _countController.text = c.toString())),
                        _PresetButton(label: '384 (4 Pallets)', count: 384, onSelect: (c) => setState(() => _countController.text = c.toString())),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Shift & Line Selectors
                    if (isNarrow) ...[
                      shiftDropdown,
                      const SizedBox(height: 16),
                      lineDropdown,
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: shiftDropdown),
                          const SizedBox(width: 16),
                          Expanded(child: lineDropdown),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Action Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isNarrow ? double.infinity : null,
                          child: AppButton(
                            text: 'PRINT BATCH QR STICKERS',
                            icon: Icons.print,
                            variant: AppButtonVariant.gradient,
                            isLoading: _isLoading,
                            onPressed: _onGenerateAndPrint,
                          ),
                        ),
                        SizedBox(
                          width: isNarrow ? double.infinity : null,
                          child: AppButton(
                            text: 'EXPORT CSV / EXCEL',
                            icon: Icons.file_download_outlined,
                            variant: AppButtonVariant.ghost,
                            onPressed: _onExportBatchCsv,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final previewCard = AppCard(
                showGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STICKER LIVE PREVIEW',
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const StatusPill(label: 'SAMPLE #001', variant: PillVariant.purple),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'MAXION WHEELS',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(3)),
                                  child: Text('SHIFT $_selectedShift', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.black, thickness: 1.2, height: 4),
                            QrImageView(
                              data: previewQr,
                              version: QrVersions.auto,
                              size: 82,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedItemCode,
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.3),
                                ),
                                Text(
                                  'SN: 00000001 | LINE $_selectedLine',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 8),
                                ),
                                Text(
                                  previewQr,
                                  style: const TextStyle(color: Colors.black54, fontSize: 6.5, fontFamily: 'monospace'),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Standard Sticker Payload Format:', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 11)),
                          const SizedBox(height: 4),
                          const SelectableText(
                            'MW|Plant|ItemCode|Serial|YYMMDD|Shift|Line',
                            style: TextStyle(color: AppColors.ribbonPink, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: inputCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: previewCard),
                  ],
                );
              }

              return Column(
                children: [
                  inputCard,
                  const SizedBox(height: 20),
                  previewCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final int count;
  final ValueChanged<int> onSelect;

  const _PresetButton({required this.label, required this.count, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelect(count),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.bgSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(color: context.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
