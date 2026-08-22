import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/print_document_helper.dart';
import '../../core/utils/print_sticker_helper.dart';
import 'app_button.dart';
import 'pills.dart';

enum PrintDocumentType {
  wheelQr,
  palletMaster,
  spdPack,
  gatePassA4,
  returnableAssetTag,
  jobCardSummary,
}

class BatchPrintPreviewDialog extends StatefulWidget {
  final String title;
  final String itemCode;
  final String? itemDescription;
  final List<Map<String, dynamic>> stickers;

  const BatchPrintPreviewDialog({
    super.key,
    required this.title,
    required this.itemCode,
    this.itemDescription,
    required this.stickers,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String itemCode,
    String? itemDescription,
    required List<Map<String, dynamic>> stickers,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => BatchPrintPreviewDialog(
        title: title,
        itemCode: itemCode,
        itemDescription: itemDescription,
        stickers: stickers,
      ),
    );
  }

  @override
  State<BatchPrintPreviewDialog> createState() => _BatchPrintPreviewDialogState();
}

class _BatchPrintPreviewDialogState extends State<BatchPrintPreviewDialog> {
  String _selectedPrinter = 'Pack Point Thermal Transfer Printer (300 DPI)';

  void _triggerBatchPrint() {
    openPrintableStickerBatch(
      context: context,
      stickerType: 'WHEEL QR STICKER',
      itemCode: widget.itemCode,
      itemDescription: widget.itemDescription,
      stickers: widget.stickers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.ribbonPink, size: 24),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          StatusPill(
            label: '${widget.stickers.length} UNIQUE STICKER LABELS',
            variant: PillVariant.ok,
          ),
        ],
      ),
      content: SizedBox(
        width: 750,
        height: 520,
        child: Column(
          children: [
            // Top info bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ITEM: ${widget.itemCode} ${widget.itemDescription != null ? "(${widget.itemDescription})" : ""}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'BATCH ROLL: ${widget.stickers.length} LABELS',
                    style: const TextStyle(color: AppColors.ribbonPink, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Scrollable Grid of all 96 Wheel QR Stickers
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.stickers.length,
                itemBuilder: (context, index) {
                  final s = widget.stickers[index];
                  final qrData = s['uniqueQrData'] ?? s['wheelQr'] ?? '';
                  final serialNo = s['serialNumber'] ?? '00000000';
                  final wheelIdx = s['wheelIndex'] ?? (index + 1);

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 64.0,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#$wheelIdx OF ${widget.stickers.length}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'SERIAL: $serialNo',
                                    style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                qrData,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.itemCode,
                                style: const TextStyle(color: Color(0xFFE0218A), fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _selectedPrinter,
              dropdownColor: AppColors.bgSurfaceElevated,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Target Industrial Barcode Printer',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Pack Point Thermal Transfer Printer (300 DPI)', child: Text('Pack Point Thermal Printer (300 DPI)')),
                DropdownMenuItem(value: 'Warehouse Staging Label Printer (203 DPI)', child: Text('Warehouse Staging Printer (203 DPI)')),
                DropdownMenuItem(value: 'Dispatch Office A4 Laser Printer', child: Text('Dispatch Office A4 Laser Printer')),
                DropdownMenuItem(value: 'Security Gate House Printer', child: Text('Security Gate House Printer')),
              ],
              onChanged: (val) => setState(() => _selectedPrinter = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
        AppButton(
          text: 'PRINT ALL ${widget.stickers.length} STICKERS TO ROLL (CTRL + P)',
          icon: Icons.print,
          variant: AppButtonVariant.gradient,
          onPressed: _triggerBatchPrint,
        ),
      ],
    );
  }
}

class PrintPreviewDialog extends StatefulWidget {
  final String title;
  final PrintDocumentType documentType;
  final String qrData;
  final String codeText;
  final String itemCode;
  final String? itemDescription;
  final String? primaryDetail;
  final String? secondaryDetail;
  final List<Map<String, String>> metadataFields;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final bool autoTriggerSystemPrint;

  const PrintPreviewDialog({
    super.key,
    required this.title,
    required this.documentType,
    required this.qrData,
    required this.codeText,
    required this.itemCode,
    this.itemDescription,
    this.primaryDetail,
    this.secondaryDetail,
    this.metadataFields = const [],
    this.tableHeaders = const ['PARAMETER', 'RECORDED VALUE', 'STATUS'],
    this.tableRows = const [],
    this.autoTriggerSystemPrint = true,
  });

  static void show({
    required BuildContext context,
    required String title,
    required PrintDocumentType documentType,
    required String qrData,
    required String codeText,
    required String itemCode,
    String? itemDescription,
    String? primaryDetail,
    String? secondaryDetail,
    List<Map<String, String>> metadataFields = const [],
    List<String> tableHeaders = const ['PARAMETER', 'RECORDED VALUE', 'STATUS'],
    List<List<String>> tableRows = const [],
    bool autoTriggerSystemPrint = true,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PrintPreviewDialog(
        title: title,
        documentType: documentType,
        qrData: qrData,
        codeText: codeText,
        itemCode: itemCode,
        itemDescription: itemDescription,
        primaryDetail: primaryDetail,
        secondaryDetail: secondaryDetail,
        metadataFields: metadataFields,
        tableHeaders: tableHeaders,
        tableRows: tableRows,
        autoTriggerSystemPrint: autoTriggerSystemPrint,
      ),
    );
  }

  @override
  State<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<PrintPreviewDialog> {
  String _selectedPrinter = 'Pack Point Thermal Transfer Printer (300 DPI)';

  @override
  void initState() {
    super.initState();
    if (widget.autoTriggerSystemPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerSystemPrint();
      });
    }
  }

  void _triggerSystemPrint() {
    final isSticker = widget.documentType != PrintDocumentType.gatePassA4 && widget.documentType != PrintDocumentType.jobCardSummary;

    if (isSticker) {
      final stickerType = widget.documentType == PrintDocumentType.wheelQr
          ? 'WHEEL QR STICKER'
          : widget.documentType == PrintDocumentType.spdPack
              ? 'SPD SPARE PACK STICKER'
              : widget.documentType == PrintDocumentType.returnableAssetTag
                  ? 'RETURNABLE TAG'
                  : 'PALLET MASTER STICKER';

      openPrintableSticker(
        context: context,
        stickerType: stickerType,
        uniqueQrData: widget.qrData,
        codeText: widget.codeText,
        itemCode: widget.itemCode,
        itemDescription: widget.itemDescription,
        stickerDetails: widget.metadataFields.isNotEmpty
            ? widget.metadataFields
            : [
                {'QR CODE': widget.codeText},
                if (widget.primaryDetail != null) {'DETAIL': widget.primaryDetail!},
              ],
      );
    } else {
      final rows = widget.tableRows.isNotEmpty
          ? widget.tableRows
          : [
              ['Document Code / QR', widget.codeText, 'VERIFIED'],
              ['Item Code', widget.itemCode, 'ACTIVE'],
              if (widget.primaryDetail != null) ['Primary Detail', widget.primaryDetail!, 'OK'],
              if (widget.secondaryDetail != null) ['Secondary Detail', widget.secondaryDetail!, 'OK'],
            ];

      openPrintableDocument(
        context: context,
        documentTitle: widget.title,
        codeText: widget.codeText,
        qrData: widget.qrData,
        itemCode: widget.itemCode,
        itemDescription: widget.itemDescription,
        metadata: widget.metadataFields,
        tableHeaders: widget.tableHeaders,
        tableRows: rows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isA4 = widget.documentType == PrintDocumentType.gatePassA4 || widget.documentType == PrintDocumentType.jobCardSummary;

    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.ribbonPink),
              const SizedBox(width: 10),
              Text(widget.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          StatusPill(
            label: isA4 ? 'A4 DOCUMENT PRINT' : 'PHYSICAL QR STICKER LABEL (4x2")',
            variant: PillVariant.info,
          ),
        ],
      ),
      content: SizedBox(
        width: isA4 ? 650 : 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PHYSICAL THERMAL STICKER LABEL PREVIEW
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MAXION WHEELS PUNE',
                          style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                          child: Text(
                            isA4 ? 'DOCUMENT' : 'STICKER LABEL',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Colors.black),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: QrImageView(
                            data: widget.qrData,
                            version: QrVersions.auto,
                            size: 85.0,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.codeText,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: widget.codeText.length > 20 ? 11.5 : 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.itemCode,
                                style: const TextStyle(color: Color(0xFFE0218A), fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              if (widget.itemDescription != null)
                                Text(
                                  widget.itemDescription!,
                                  style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.metadataFields.isNotEmpty) ...[
                      const Divider(height: 16, color: Colors.black26),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: widget.metadataFields.map((field) {
                          final key = field.keys.first;
                          final val = field.values.first;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${key.toUpperCase()}: ', style: const TextStyle(color: Colors.black54, fontSize: 9.5, fontWeight: FontWeight.bold)),
                              Text(val, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedPrinter,
                dropdownColor: AppColors.bgSurfaceElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Target Industrial Barcode Printer',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pack Point Thermal Transfer Printer (300 DPI)', child: Text('Pack Point Thermal Printer (300 DPI)')),
                  DropdownMenuItem(value: 'Warehouse Staging Label Printer (203 DPI)', child: Text('Warehouse Staging Printer (203 DPI)')),
                  DropdownMenuItem(value: 'Dispatch Office A4 Laser Printer', child: Text('Dispatch Office A4 Laser Printer')),
                  DropdownMenuItem(value: 'Security Gate House Printer', child: Text('Security Gate House Printer')),
                ],
                onChanged: (val) => setState(() => _selectedPrinter = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
        AppButton(
          text: 'PRINT PHYSICAL QR STICKER (CTRL + P)',
          icon: Icons.print,
          variant: AppButtonVariant.gradient,
          onPressed: _triggerSystemPrint,
        ),
      ],
    );
  }
}
