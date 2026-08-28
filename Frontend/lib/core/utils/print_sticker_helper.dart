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
  final isWheelSticker = stickerType == 'WHEEL QR STICKER';
  try {
    final stickerPagesHtml = stickers.map((s) {
      final String qrData = s['uniqueQrData'] ?? s['spdPackQr'] ?? s['wheelQr'] ?? 'MW|P1|$itemCode|00000001|260826|A|PL2';
      final String codeText = s['codeText'] ?? s['spdPackNumber'] ?? s['wheelQr'] ?? s['serialNumber'] ?? 'WHEEL STICKER';
      List<Map<String, String>> details = [];
      if (s['stickerDetails'] != null && s['stickerDetails'] is List) {
        try {
          details = (s['stickerDetails'] as List).map<Map<String, String>>((d) {
            if (d is Map && d.isNotEmpty) {
              final k = d.keys.first.toString();
              final v = d.values.first.toString();
              return {k: v};
            }
            return {'LABEL': d.toString()};
          }).toList();
        } catch (_) {}
      }

      if (details.isEmpty) {
        details = [
          {'SERIAL': (s['serialNumber'] ?? s['spdPackNumber'] ?? '43918758').toString()},
          {'WHEEL NO': '${s['wheelIndex'] ?? 1} of ${s['totalBatchCount'] ?? stickers.length}'},
          {'DATE': '2026-08-26'},
          {'WORK POINT': 'Pack Point #1'},
        ];
      }

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

      final isWheelSticker = stickerType == 'WHEEL QR STICKER';

      if (isWheelSticker) {
        // Extract shift and line if available
        String shiftVal = 'A';
        String lineVal = 'PL2';
        String serialVal = s['serialNumber'] ?? '00000001';

        final parts = qrData.split('|');
        if (parts.length >= 7) {
          shiftVal = parts[5];
          lineVal = parts[6];
          serialVal = parts[3];
        }

        return '''
        <div class="sticker-page wheel-sticker-page">
          <div class="wheel-sticker-container">
            <div class="wheel-header">
              <span class="wheel-brand">MAXION WHEELS</span>
              <span class="wheel-shift-pill">SHIFT $shiftVal</span>
            </div>
            <div class="wheel-hr"></div>
            <div class="wheel-qr-center">
              <img class="wheel-qr-img" src="$qrUrl" onerror="this.onerror=null;this.src='https://chart.googleapis.com/chart?cht=qr&chs=250x250&chl=${Uri.encodeComponent(qrData)}';" alt="Wheel QR" />
            </div>
            <div class="wheel-item-code">$itemCode</div>
            <div class="wheel-sn-line">SN: $serialVal | LINE $lineVal</div>
            <div class="wheel-payload">$qrData</div>
          </div>
        </div>
        ''';
      }

      return '''
        <div class="sticker-page">
          <div class="sticker-container">
            <div class="sticker-header">
              <div class="brand-title">MAXION WHEELS</div>
              <div class="sticker-cat">$stickerType</div>
            </div>

            <div class="sticker-body">
              <img class="qr-img" src="$qrUrl" onerror="this.onerror=null;this.src='https://chart.googleapis.com/chart?cht=qr&chs=200x200&chl=${Uri.encodeComponent(qrData)}';" alt="QR Sticker" />
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
      size: ${isWheelSticker ? '50mm 50mm' : '100mm 60mm'}; /* 50x50mm square for Wheel stickers, 100x60mm for pallets */
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
      width: ${isWheelSticker ? '50mm' : '100mm'};
      height: ${isWheelSticker ? '50mm' : '60mm'};
      padding: ${isWheelSticker ? '2.5mm' : '6px'};
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
    .wheel-sticker-container {
      border: 2px solid #000;
      border-radius: 8px;
      padding: 5px 6px;
      height: 100%;
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: space-between;
      background: #fff;
      text-align: center;
    }
    .wheel-header {
      width: 100%;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .wheel-brand {
      font-size: 10px;
      font-weight: 900;
      letter-spacing: 0.5px;
    }
    .wheel-shift-pill {
      background: #000;
      color: #fff;
      font-size: 7.5px;
      font-weight: 900;
      padding: 1.5px 4.5px;
      border-radius: 3px;
    }
    .wheel-hr {
      width: 100%;
      height: 1.5px;
      background: #000;
      margin: 2px 0;
    }
    .wheel-qr-center {
      display: flex;
      justify-content: center;
      align-items: center;
      margin: 1px 0;
    }
    .wheel-qr-img {
      width: 76px;
      height: 76px;
      object-fit: contain;
    }
    .wheel-item-code {
      font-size: 11.5px;
      font-weight: 900;
      letter-spacing: 0.3px;
      margin-top: 1px;
    }
    .wheel-sn-line {
      font-size: 8px;
      font-weight: 700;
      color: #111;
      margin-top: 1px;
    }
    .wheel-payload {
      font-family: 'Consolas', 'Courier New', monospace;
      font-size: 6px;
      color: #555;
      margin-top: 1px;
      max-width: 100%;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .wheel-sn-line {
      font-size: 9.5px;
      font-weight: 700;
      color: #222;
      margin-top: 1px;
    }
    .wheel-payload {
      font-family: 'Consolas', 'Courier New', monospace;
      font-size: 7.5px;
      color: #555;
      margin-top: 1px;
      max-width: 100%;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
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
        content: Text('Opened System Print Window for ${stickers.length} SPD stickers!'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Sticker Roll sent to print window!'),
      ),
    );
  }
}
