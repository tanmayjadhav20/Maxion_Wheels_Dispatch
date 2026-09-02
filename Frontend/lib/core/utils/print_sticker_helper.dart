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
/// pack point printer without rescaling or halftone dithering.
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
      count: stickers.length,
    );

    final blob = html.Blob([document], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        content: Text(
          '${stickers.length} x ${stock.displayName} (${stock.sizeLabel}) ready — '
          'choose A4 sheet or thermal roll, then press Print.',
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
          '<span class="k">${_esc(d.key)}:</span> '
          '<span class="v">${_esc(d.value)}</span>'
          '</div>')
      .join();

  final desc = itemDescription == null || itemDescription.isEmpty
      ? ''
      : '<div class="desc">${_esc(itemDescription)}</div>';

  final codePt = switch (codeText.length) {
    <= 10 => 20,
    <= 14 => 16,
    <= 18 => 13,
    _ => 11,
  };

  return '''
<section class="label pallet">
  <div class="frame">
    <header class="bar">
      <span class="brand">MAXION WHEELS</span>
      <span class="kind">${_esc(stickerType.toUpperCase())}</span>
    </header>

    <div class="main">
      <div class="qr">${QrSvg.build(qrData, ecc: stock.errorCorrection)}</div>
      <div class="ident">
        <div class="code" style="font-size:${codePt}pt">${_esc(codeText)}</div>
        <div class="item">ITEM: ${_esc(itemCode)}</div>
        $desc
      </div>
    </div>

    <div class="grid">$detailCells</div>

    <footer class="foot">
      <span class="payload">${_esc(qrData)}</span>
      <span class="seq">$index / $total</span>
    </footer>
  </div>
</section>
''';
}

/// 50 x 25 mm wheel / SPD pack scanning label.
///
/// High-contrast pure black on pure white layout with large, readable fonts.
/// No grey shades, inverted backgrounds, or rounded badges that trigger thermal halftone dots.
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
    <div class="row-top">
      <span class="item">${_esc(itemCode)}</span>
      <span class="shift-box">${_esc(shift)}</span>
    </div>
    <div class="row-sn">${_esc(serial)}</div>
    <div class="row-meta">LINE ${_esc(line)} &bull; $index/$total</div>
  </div>
</section>
''';
}

// ---------------------------------------------------------------------------
// Document shell & Thermal-Optimized CSS
// ---------------------------------------------------------------------------

/// How many labels of a given stock tile onto one A4 sheet.
class _SheetLayout {
  const _SheetLayout({
    required this.cols,
    required this.rows,
    required this.orientation,
  });

  final int cols;
  final int rows;
  final String orientation;

  int get perSheet => cols * rows;
}

/// Chooses the A4 orientation that fits the most labels per sheet.
///
/// A4 is 210 x 297 mm; an 8 mm margin keeps the grid inside the non-printable
/// edge every office laser reserves, and a 3 mm gutter gives scissors somewhere
/// to go when the labels are run on plain paper.
_SheetLayout _sheetLayoutFor(LabelStock stock) {
  const margin = 8.0;
  const gutter = 3.0;

  int fit(double available, double size) {
    final n = ((available + gutter) / (size + gutter)).floor();
    return n < 1 ? 1 : n;
  }

  final portrait = _SheetLayout(
    cols: fit(210 - margin * 2, stock.widthMm),
    rows: fit(297 - margin * 2, stock.heightMm),
    orientation: 'portrait',
  );
  final landscape = _SheetLayout(
    cols: fit(297 - margin * 2, stock.widthMm),
    rows: fit(210 - margin * 2, stock.heightMm),
    orientation: 'landscape',
  );

  return landscape.perSheet > portrait.perSheet ? landscape : portrait;
}

String _document({
  required LabelStock stock,
  required String title,
  required String body,
  required int count,
}) {
  final w = _mm(stock.widthMm);
  final h = _mm(stock.heightMm);
  final qrSize = stock == LabelStock.pallet ? '36mm' : '21mm';

  final sheet = _sheetLayoutFor(stock);
  final sheets = (count / sheet.perSheet).ceil();

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>${_esc(title)}</title>

<!-- Two mutually exclusive print stylesheets, switched by the toolbar.
     `@page` cannot be nested inside a selector, so each mode lives in its own
     sheet and the inactive one is disabled via media="not all". -->
<style id="mode-sheet" media="all">
  /* A4 SHEET — for an office laser/inkjet loaded with plain or Avery paper.
     This is the default because a thermal media size in @page is silently
     ignored when the printer has A4 loaded: every label then lands in the
     corner of its own sheet, which is how 96 labels became 96 sheets. */
  @page { size: A4 ${sheet.orientation}; margin: 0; }

  .doc {
    padding: 8mm;
    display: grid;
    grid-template-columns: repeat(${sheet.cols}, $w);
    grid-auto-rows: $h;
    gap: 3mm;
    justify-content: center;
    align-content: start;
  }

  .label {
    page-break-inside: avoid;
    break-inside: avoid;
  }
</style>

<style id="mode-roll" media="not all">
  /* THERMAL ROLL — one die-cut label per page, for the Zebra/Honeywell
     printers actually loaded with ${stock.sizeLabel} stock. */
  @page { size: $w $h; margin: 0; }

  .doc { padding: 0; }

  .label {
    page-break-after: always;
    break-after: page;
  }

  .label:last-child {
    page-break-after: auto;
    break-after: auto;
  }
</style>

<style>
  *, *::before, *::after {
    box-sizing: border-box;
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
    box-shadow: none !important;
    text-shadow: none !important;
  }

  html, body {
    margin: 0;
    padding: 0;
    background: #ffffff !important;
    background-color: #ffffff !important;
    color: #000000 !important;
    font-family: Arial, Helvetica, sans-serif;
  }

  .label {
    width: $w;
    height: $h;
    overflow: hidden;
    /* Explicit white so the label never inherits a tinted page or a dark
       print-preview backdrop. */
    background: #ffffff !important;
    background-color: #ffffff !important;
    color: #000000 !important;
    /* Cut/registration outline. Every label carries one so an operator can
       see the label edge on plain paper and trim to it. */
    border: 1px solid #000000;
    position: relative;
  }

  /* ---------------- Screen-only toolbar ---------------- */
  .bar-ui {
    position: sticky;
    top: 0;
    z-index: 20;
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 14px;
    background: #ffffff;
    border-bottom: 1px solid #d4d4d8;
    font: 13px/1.4 'Segoe UI', Arial, sans-serif;
  }

  .bar-ui .meta { flex: 1; color: #52525b; }
  .bar-ui .meta strong { color: #18181b; }

  .bar-ui button {
    padding: 7px 13px;
    font: 600 12px 'Segoe UI', Arial, sans-serif;
    color: #18181b;
    background: #f4f4f5;
    border: 1px solid #d4d4d8;
    border-radius: 6px;
    cursor: pointer;
  }

  .bar-ui button:hover { background: #e4e4e7; }
  .bar-ui button.on {
    color: #ffffff;
    background: #E0218A;
    border-color: #E0218A;
  }
  .bar-ui button.go {
    color: #ffffff;
    background: #18181b;
    border-color: #18181b;
  }

  /* The toolbar is a screen affordance only; it must never reach the paper. */
  @media print { .bar-ui { display: none !important; } }

  .qr {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .qr svg {
    display: block;
    width: 100%;
    height: 100%;
    shape-rendering: crispEdges;
  }

  /* ---------------- 50 x 25 mm Scanning Label ---------------- */
  .scan {
    padding: 1.5mm 2mm;
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 2mm;
    width: $w;
    height: $h;
  }

  .scan .qr {
    width: $qrSize;
    height: $qrSize;
    flex: 0 0 $qrSize;
  }

  .scan .ident {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    justify-content: space-around;
    height: $qrSize;
    overflow: hidden;
  }

  .scan .row-top {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 1mm;
    line-height: 1.1;
  }

  /* The item code is the field an operator reads off the label, so it claims
     the row and the shift chip is what gives way. Without the explicit
     flex/min-width the chip won the squeeze and a code like 18663 ellipsised
     down to "18...". */
  .scan .item {
    flex: 1 1 auto;
    min-width: 0;
    font-size: 11pt;
    font-weight: 900;
    letter-spacing: -0.2px;
    color: #000000;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  /* Just the shift letter: "SHIFT A" spelled out cost ~10 mm of a 23 mm
     column. The boxed glyph sits above "LINE PL2", which makes it legible in
     context, and the QR payload carries the shift verbatim regardless. */
  .scan .shift-box {
    flex: 0 0 auto;
    font-size: 8pt;
    font-weight: 900;
    line-height: 1;
    color: #000000;
    border: 1px solid #000000;
    padding: 0.6mm 1mm;
    white-space: nowrap;
  }

  .scan .row-sn {
    font-family: 'Consolas', 'Courier New', monospace;
    font-size: 10.5pt;
    font-weight: 900;
    letter-spacing: 0.2px;
    color: #000000;
    line-height: 1.1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .scan .row-meta {
    font-size: 7pt;
    font-weight: 700;
    color: #000000;
    line-height: 1.1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  /* ---------------- 100 x 75 mm Pallet Master ---------------- */
  .pallet {
    padding: 2.5mm;
    display: flex;
    flex-direction: column;
    width: $w;
    height: $h;
  }

  /* No border here: the outer .label rule is the single cut line, and a second
     rule 2.5 mm inside it just reads as a printing error. */
  .pallet .frame {
    padding: 1mm;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }

  .pallet .bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid #000000;
    padding-bottom: 1.5mm;
    margin-bottom: 2mm;
  }

  .pallet .brand {
    font-size: 12pt;
    font-weight: 900;
    letter-spacing: 0.5px;
    color: #000000;
  }

  .pallet .kind {
    font-size: 8pt;
    font-weight: 800;
    letter-spacing: 0.3px;
    border: 1.5px solid #000000;
    padding: 1px 4px;
    border-radius: 3px;
  }

  .pallet .main {
    display: flex;
    gap: 4mm;
    align-items: center;
    flex: 1;
    min-height: 0;
  }

  .pallet .qr {
    width: $qrSize;
    height: $qrSize;
    flex: 0 0 $qrSize;
  }

  .pallet .ident {
    min-width: 0;
    flex: 1;
  }

  .pallet .code {
    font-weight: 900;
    line-height: 1.05;
    letter-spacing: -0.3px;
    overflow-wrap: anywhere;
    color: #000000;
  }

  .pallet .item {
    font-size: 12pt;
    font-weight: 800;
    margin-top: 1.5mm;
    color: #000000;
  }

  .pallet .desc {
    font-size: 8pt;
    font-weight: 600;
    margin-top: 1mm;
    color: #000000;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }

  .pallet .grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.5mm 4mm;
    border-top: 1.5px solid #000000;
    padding-top: 2mm;
    margin-top: 2mm;
  }

  .pallet .cell {
    font-size: 8pt;
    line-height: 1.25;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    color: #000000;
  }

  .pallet .cell .k { font-weight: 700; }
  .pallet .cell .v { font-weight: 900; }

  .pallet .foot {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 2mm;
    margin-top: 2mm;
    padding-top: 1mm;
    border-top: 1px dashed #000000;
    font-size: 6.5pt;
    color: #000000;
  }

  .pallet .payload {
    font-family: 'Consolas', 'Courier New', monospace;
    font-weight: 700;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .pallet .seq {
    font-weight: 900;
    white-space: nowrap;
  }
</style>
</head>
<body>
<div class="bar-ui">
  <div class="meta">
    <strong>${_esc(stock.displayName)}</strong> &middot; ${stock.sizeLabel}
    &middot; $count label${count == 1 ? '' : 's'}
  </div>
  <button id="btn-sheet" class="on" type="button">A4 sheet &mdash; ${sheet.perSheet}/page ($sheets sheet${sheets == 1 ? '' : 's'})</button>
  <button id="btn-roll" type="button">Thermal roll &mdash; ${stock.sizeLabel}</button>
  <button class="go" type="button" onclick="window.print()">Print</button>
</div>

<div class="doc">
$body
</div>

<script>
  (function () {
    var sheetCss = document.getElementById('mode-sheet');
    var rollCss = document.getElementById('mode-roll');
    var sheetBtn = document.getElementById('btn-sheet');
    var rollBtn = document.getElementById('btn-roll');

    function setMode(mode) {
      var onSheet = mode === 'sheet';
      // Disabling a whole stylesheet is what takes its @page rule out of play.
      sheetCss.media = onSheet ? 'all' : 'not all';
      rollCss.media = onSheet ? 'not all' : 'all';
      sheetBtn.className = onSheet ? 'on' : '';
      rollBtn.className = onSheet ? '' : 'on';
    }

    sheetBtn.onclick = function () { setMode('sheet'); };
    rollBtn.onclick = function () { setMode('roll'); };
  })();
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
