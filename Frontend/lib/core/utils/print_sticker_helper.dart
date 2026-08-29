import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'label_stock.dart';
import 'qr_svg.dart';

/// Opens a print window for a single label.
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

/// Opens a print window for a roll of labels.
///
/// Artwork is laid out against the exact Avery Chromo die-cut for the sticker
/// type (see [LabelStock]) and dimensioned entirely in millimetres, so the same
/// template prints true on both the 203 DPI staging printer and the 300 DPI
/// pack point printer without rescaling.
void openPrintableStickerBatch({
  required BuildContext context,
  required String stickerType,
  required String itemCode,
  String? itemDescription,
  required List<Map<String, dynamic>> stickers,
}) {
  final stock = LabelStock.forStickerType(stickerType);

  try {
    final pages = <String>[];
    for (var i = 0; i < stickers.length; i++) {
      pages.add(
        stock == LabelStock.pallet
            ? _palletLabel(
                sticker: stickers[i],
                stickerType: stickerType,
                itemCode: itemCode,
                itemDescription: itemDescription,
                index: i + 1,
                total: stickers.length,
                stock: stock,
              )
            : _scanningLabel(
                sticker: stickers[i],
                itemCode: itemCode,
                index: i + 1,
                total: stickers.length,
                stock: stock,
              ),
      );
    }

    final document = _document(
      stock: stock,
      title: '${stock.displayName.toUpperCase()} — $itemCode (${stickers.length})',
      body: pages.join('\n'),
    );

    final blob = html.Blob([document], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        content: Text(
          '${stickers.length} x ${stock.displayName} '
          '(${stock.sizeLabel}) sent to the print window.',
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text('Could not open the print window: $e'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layouts
// ---------------------------------------------------------------------------

/// 100 x 75 mm master pallet label.
///
/// Read at distance by forklift HHT and at the gate, so the pallet number is
/// the dominant element and the QR is large enough to scan off a raised rack.
String _palletLabel({
  required Map<String, dynamic> sticker,
  required String stickerType,
  required String itemCode,
  required String? itemDescription,
  required int index,
  required int total,
  required LabelStock stock,
}) {
  final qrData = _qrData(sticker, itemCode);
  final codeText = _codeText(sticker);
  final details = _details(sticker, fallbackSerial: codeText);

  final detailCells = details
      .take(6)
      .map((d) => '<div class="cell">'
          '<span class="k">${_esc(d.key)}</span>'
          '<span class="v">${_esc(d.value)}</span>'
          '</div>')
      .join();

  final desc = itemDescription == null || itemDescription.isEmpty
      ? ''
      : '<div class="desc">${_esc(itemDescription)}</div>';

  // CSS has no equivalent of a shrink-to-fit box, so step the code down by
  // length. The ident column is ~57 mm wide; without this a 13-character code
  // like MWR|RP0001842 wraps and breaks mid-token at the base size.
  final codePt = switch (codeText.length) {
    <= 10 => 19,
    <= 14 => 15,
    <= 18 => 12,
    _ => 10,
  };

  return '''
<section class="label pallet">
  <header class="bar">
    <span class="brand">MAXION WHEELS</span>
    <span class="kind">${_esc(stickerType)}</span>
  </header>

  <div class="main">
    <div class="qr">${QrSvg.build(qrData, ecc: stock.errorCorrection)}</div>
    <div class="ident">
      <div class="code" style="font-size:${codePt}pt">${_esc(codeText)}</div>
      <div class="item">${_esc(itemCode)}</div>
      $desc
    </div>
  </div>

  <div class="grid">$detailCells</div>

  <footer class="foot">
    <span class="payload">${_esc(qrData)}</span>
    <span class="seq">$index / $total</span>
  </footer>
</section>
''';
}

/// 50 x 25 mm wheel / SPD pack scanning label.
///
/// Landscape strip: QR hard left, three lines of identity to its right. There
/// is no room for the raw payload here and no need for it — this label is
/// scanned, not read.
String _scanningLabel({
  required Map<String, dynamic> sticker,
  required String itemCode,
  required int index,
  required int total,
  required LabelStock stock,
}) {
  final qrData = _qrData(sticker, itemCode);

  // Payload format: MW|Plant|ItemCode|Serial|YYMMDD|Shift|Line
  final parts = qrData.split('|');
  final serial = parts.length > 3
      ? parts[3]
      : (sticker['serialNumber'] ?? _codeText(sticker)).toString();
  final shift = parts.length > 5 ? parts[5] : (sticker['shift'] ?? 'A').toString();
  final line = parts.length > 6 ? parts[6] : (sticker['line'] ?? 'PL2').toString();

  return '''
<section class="label scan">
  <div class="qr">${QrSvg.build(qrData, ecc: stock.errorCorrection)}</div>
  <div class="ident">
    <div class="top">
      <span class="item">${_esc(itemCode)}</span>
      <span class="shift">${_esc(shift)}</span>
    </div>
    <div class="sn">${_esc(serial)}</div>
    <div class="meta">LINE ${_esc(line)} &middot; $index/$total</div>
  </div>
</section>
''';
}

// ---------------------------------------------------------------------------
// Document shell
// ---------------------------------------------------------------------------

String _document({
  required LabelStock stock,
  required String title,
  required String body,
}) {
  final w = _mm(stock.widthMm);
  final h = _mm(stock.heightMm);
  final qr = _mm(stock.qrSizeMm);

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>${_esc(title)}</title>
<style>
  /* Die-cut media box. Must equal the stock exactly or the image walks
     down the roll: ${stock.specLabel} */
  @page { size: $w $h; margin: 0; }

  *, *::before, *::after { box-sizing: border-box; }

  html, body {
    margin: 0;
    padding: 0;
    background: #fff;
    color: #000;
    font-family: 'Helvetica Neue', Arial, sans-serif;
    /* Thermal transfer needs the solid black bars to actually render. */
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  .label {
    width: $w;
    height: $h;
    overflow: hidden;
    background: #fff;
    page-break-after: always;
    break-after: page;
  }
  /* Without this the job emits one blank label at the end of every roll. */
  .label:last-child { page-break-after: auto; break-after: auto; }

  /* No border is drawn at the die edge: on 1UP die-cut stock any registration
     drift turns an edge rule into a visibly crooked label. Content is held
     inside a safe margin instead. */

  .qr svg { display: block; width: 100%; height: 100%; }

  /* ---------------- 100 x 75 mm pallet ---------------- */
  .pallet {
    padding: 3mm;
    display: flex;
    flex-direction: column;
  }
  .pallet .bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #000;
    color: #fff;
    padding: 1.1mm 2mm;
    border-radius: 0.8mm;
  }
  .pallet .brand { font-size: 9pt; font-weight: 800; letter-spacing: 0.2mm; }
  .pallet .kind { font-size: 5.5pt; font-weight: 700; letter-spacing: 0.15mm; }

  .pallet .main {
    display: flex;
    gap: 3mm;
    align-items: center;
    padding: 2.2mm 0;
    flex: 1;
    min-height: 0;
  }
  .pallet .qr { width: $qr; height: $qr; flex: 0 0 $qr; }
  .pallet .ident { min-width: 0; flex: 1; }
  .pallet .code {
    font-weight: 800;
    line-height: 1.04;
    letter-spacing: -0.2mm;
    overflow-wrap: anywhere;
    max-height: 15mm;
    overflow: hidden;
  }
  .pallet .item {
    font-size: 11pt;
    font-weight: 700;
    margin-top: 0.8mm;
  }
  .pallet .desc {
    font-size: 6.5pt;
    margin-top: 0.5mm;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }

  .pallet .grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.8mm 3mm;
    border-top: 0.4mm solid #000;
    padding-top: 1.5mm;
  }
  .pallet .cell {
    font-size: 6.5pt;
    line-height: 1.25;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .pallet .cell .k { font-weight: 600; }
  .pallet .cell .k::after { content: ' '; }
  .pallet .cell .v { font-weight: 800; }

  .pallet .foot {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 2mm;
    margin-top: 1.2mm;
    font-size: 5pt;
  }
  .pallet .payload {
    font-family: 'Consolas', 'Courier New', monospace;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .pallet .seq { font-weight: 700; white-space: nowrap; }

  /* ---------------- 50 x 25 mm scanning ---------------- */
  .scan {
    padding: 1.5mm;
    display: flex;
    align-items: center;
    gap: 1.5mm;
  }
  .scan .qr { width: $qr; height: $qr; flex: 0 0 $qr; }
  .scan .ident {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 0.4mm;
  }
  .scan .top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1mm;
  }
  .scan .item {
    font-size: 7pt;
    font-weight: 800;
    letter-spacing: -0.05mm;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .scan .shift {
    flex: 0 0 auto;
    background: #000;
    color: #fff;
    font-size: 5pt;
    font-weight: 800;
    padding: 0.3mm 1mm;
    border-radius: 0.6mm;
  }
  .scan .sn {
    font-family: 'Consolas', 'Courier New', monospace;
    font-size: 8pt;
    font-weight: 700;
    letter-spacing: -0.05mm;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .scan .meta {
    font-size: 5pt;
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
</style>
</head>
<body>
$body
<script>
  window.onload = function () { setTimeout(function () { window.print(); }, 250); };
</script>
</body>
</html>
''';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _qrData(Map<String, dynamic> s, String itemCode) {
  final v = s['uniqueQrData'] ?? s['spdPackQr'] ?? s['wheelQr'];
  if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  return 'MW|P1|$itemCode|00000001|260826|A|PL2';
}

String _codeText(Map<String, dynamic> s) {
  for (final key in const ['codeText', 'spdPackNumber', 'wheelQr', 'serialNumber']) {
    final v = s[key];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return '—';
}

/// Normalises the loosely-typed `stickerDetails` payload the screens pass in.
List<MapEntry<String, String>> _details(
  Map<String, dynamic> s, {
  required String fallbackSerial,
}) {
  final raw = s['stickerDetails'];
  final out = <MapEntry<String, String>>[];

  if (raw is List) {
    for (final d in raw) {
      if (d is Map && d.isNotEmpty) {
        out.add(MapEntry(
          d.keys.first.toString().toUpperCase(),
          d.values.first.toString(),
        ));
      }
    }
  }

  if (out.isEmpty) {
    out.addAll([
      MapEntry('SERIAL', fallbackSerial),
      MapEntry('QTY', (s['quantity'] ?? s['packedQty'] ?? '—').toString()),
      MapEntry('LOCATION', (s['locationCode'] ?? '—').toString()),
      MapEntry('DATE', (s['date'] ?? '—').toString()),
    ]);
  }
  return out;
}

/// Trims a trailing `.0` so the CSS reads `75mm`, not `75.0mm`.
String _mm(double v) =>
    v == v.roundToDouble() ? '${v.toStringAsFixed(0)}mm' : '${v}mm';

/// Serials and item codes are operator- and API-supplied, and this string is
/// injected straight into a document the browser then renders.
String _esc(String v) => v
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
