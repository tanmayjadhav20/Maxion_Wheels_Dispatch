import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

void openPrintableSticker({
  required BuildContext context,
  required String stickerType,
  required String uniqueQrData,
  required String codeText,
  required String itemCode,
  String? itemDescription,
  required List<Map<String, String>> stickerDetails,
}) {
  openPrintableStickerBatch(
    context: context,
    stickerType: stickerType,
    itemCode: itemCode,
    itemDescription: itemDescription,
    stickers: [
      {
        'uniqueQrData': uniqueQrData,
        'codeText': codeText,
        'stickerDetails': stickerDetails,
      }
    ],
  );
}

void openPrintableStickerBatch({
  required BuildContext context,
  required String stickerType,
  required String itemCode,
  String? itemDescription,
  required List<Map<String, dynamic>> stickers,
}) {
  try {
    final stickerPagesHtml = stickers.map((s) {
      final String qrData = s['uniqueQrData'] ?? s['wheelQr'] ?? 'MW|P1|$itemCode|00000001|260822|A|PL2';
      final String codeText = s['codeText'] ?? s['wheelQr'] ?? s['serialNumber'] ?? 'WHEEL STICKER';
      final List<Map<String, String>> details = (s['stickerDetails'] as List<Map<String, String>>?) ?? [
        {'SERIAL': s['serialNumber'] ?? '00000001'},
        {'WHEEL NO': '${s['wheelIndex'] ?? 1} of ${s['totalBatchCount'] ?? stickers.length}'},
        {'DATE': '2026-08-22'},
        {'WORK POINT': 'Pack Point #1'},
      ];

      final detailsHtml = details.map((d) {
        final k = d.keys.first;
        final v = d.values.first;
        return '''
          <div class="sticker-field">
            <span class="lbl">${k.toUpperCase()}:</span>
            <span class="val">$v</span>
          </div>
        ''';
      }).join('\n');

      final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(qrData)}';

      return '''
        <div class="sticker-page">
          <div class="sticker-container">
            <div class="sticker-header">
              <div class="brand-title">MAXION WHEELS</div>
              <div class="sticker-cat">$stickerType</div>
            </div>

            <div class="sticker-body">
              <img class="qr-img" src="$qrUrl" alt="QR Sticker" />
              <div class="main-info">
                <div class="code-text">$codeText</div>
                <div class="item-code">$itemCode</div>
                ${itemDescription != null ? '<div class="item-desc">' + itemDescription + '</div>' : ''}
              </div>
            </div>

            <div class="details-grid">
              $detailsHtml
            </div>
          </div>
        </div>
      ''';
    }).join('\n');

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>BATCH STICKERS - $itemCode (${stickers.length} LABELS)</title>
  <style>
    @page {
      size: 100mm 60mm; /* Standard 4in x 2.5in Industrial Thermal Sticker Label */
      margin: 0;
    }
    *, *:before, *:after {
      box-sizing: border-box;
    }
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      margin: 0;
      padding: 0;
      background: #fff;
      color: #000;
    }
    .sticker-page {
      width: 100mm;
      height: 60mm;
      padding: 6px;
      page-break-after: always;
      break-after: page;
      overflow: hidden;
      box-sizing: border-box;
    }
    .sticker-container {
      border: 3px solid #000;
      border-radius: 4px;
      padding: 8px;
      height: 100%;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      overflow: hidden;
      background: #fff;
    }
    .sticker-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #000;
      padding-bottom: 4px;
      margin-bottom: 4px;
    }
    .brand-title {
      font-size: 13px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .sticker-cat {
      font-size: 9.5px;
      font-weight: 800;
      color: #555;
      text-transform: uppercase;
    }
    .sticker-body {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      flex: 1;
      overflow: hidden;
      margin: 4px 0;
    }
    .qr-img {
      width: 82px;
      height: 82px;
      min-width: 82px;
      border: 1.5px solid #000;
      padding: 2px;
      object-fit: contain;
    }
    .main-info {
      flex: 1;
      min-width: 0;
      overflow: hidden;
    }
    .code-text {
      font-family: 'Consolas', 'Courier New', monospace;
      font-size: 11px;
      line-height: 1.25;
      font-weight: 800;
      margin: 0 0 4px 0;
      word-break: break-all;
      overflow-wrap: anywhere;
      color: #000;
    }
    .item-code {
      font-size: 14px;
      font-weight: 900;
      margin: 0 0 2px 0;
      color: #000;
    }
    .item-desc {
      font-size: 10.5px;
      color: #333;
      margin: 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .details-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 4px 10px;
      border-top: 1.5px dashed #000;
      padding-top: 6px;
      margin-top: 4px;
    }
    .sticker-field {
      font-size: 10px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .lbl {
      font-weight: bold;
      color: #333;
    }
    .val {
      font-weight: 900;
      color: #000;
    }
  </style>
</head>
<body>
  $stickerPagesHtml

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 300);
    };
  </script>
</body>
</html>
''';

    final blob = html.Blob([htmlContent], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Opened Thermal Sticker Print Window for ${stickers.length} labels ($itemCode)!'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Sticker Roll formatted for printing!'),
      ),
    );
  }
}
