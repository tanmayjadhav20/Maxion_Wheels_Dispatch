import 'package:qr/qr.dart';

import 'label_stock.dart';

/// Renders QR symbols as inline SVG for the print templates.
///
/// The print helpers previously pulled every QR from `api.qrserver.com`. On an
/// offline-first plant network that means a label roll of broken-image icons
/// exactly when the line is running degraded — and it leaked every pallet and
/// wheel serial to a third party. Encoding locally removes both problems and
/// prints faster, since the browser never waits on a network round trip.
class QrSvg {
  QrSvg._();

  static int _level(QrEcc ecc) => switch (ecc) {
        QrEcc.low => QrErrorCorrectLevel.L,
        QrEcc.medium => QrErrorCorrectLevel.M,
        QrEcc.quartile => QrErrorCorrectLevel.Q,
        QrEcc.high => QrErrorCorrectLevel.H,
      };

  /// Builds a self-contained `<svg>` for [data].
  ///
  /// [quietZoneModules] defaults to the 4 modules the QR spec requires; without
  /// it a scanner cannot lock onto the finder patterns when the symbol sits
  /// near a border or another element.
  ///
  /// The symbol is emitted as a single `<path>` of 1x1 module rects on a
  /// `viewBox` sized in modules, so it scales to any physical size with no
  /// rounding seams between modules — the hairline gaps you get from drawing
  /// one `<rect>` per module are what make a thermal print fail to scan.
  static String build(
    String data, {
    QrEcc ecc = QrEcc.medium,
    int quietZoneModules = 4,
    String cssClass = 'qr',
  }) {
    final safeData = data.isEmpty ? ' ' : data;

    QrImage image;
    try {
      image = QrImage(
        QrCode.fromData(data: safeData, errorCorrectLevel: _level(ecc)),
      );
    } on InputTooLongException {
      // Fall back to the lowest correction level, which holds the most data,
      // rather than printing a label with no symbol at all.
      image = QrImage(
        QrCode.fromData(data: safeData, errorCorrectLevel: QrErrorCorrectLevel.L),
      );
    }

    final count = image.moduleCount;
    final span = count + quietZoneModules * 2;

    final path = StringBuffer();
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (image.isDark(row, col)) {
          path.write('M${col + quietZoneModules} ${row + quietZoneModules}h1v1h-1z');
        }
      }
    }

    return '<svg class="$cssClass" xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $span $span" shape-rendering="crispEdges" '
        'role="img" aria-label="QR code">'
        '<rect width="$span" height="$span" fill="#fff"/>'
        '<path d="$path" fill="#000"/>'
        '</svg>';
  }

  /// Module count for [data] at [ecc] — useful for sanity-checking that a
  /// payload still prints at a legible module size on a given stock.
  static int moduleCount(String data, {QrEcc ecc = QrEcc.medium}) {
    try {
      return QrImage(
        QrCode.fromData(
          data: data.isEmpty ? ' ' : data,
          errorCorrectLevel: _level(ecc),
        ),
      ).moduleCount;
    } catch (_) {
      return 0;
    }
  }
}
