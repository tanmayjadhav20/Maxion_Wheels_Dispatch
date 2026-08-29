/// The physical label stock loaded on the plant's thermal printers.
///
/// Maxion stocks exactly two Avery Chromo die-cuts, so every label the system
/// prints must be one of these. Sizes here are the *die-cut* dimensions — the
/// `@page` box must match them exactly or the printer will scale the artwork
/// and drift across the roll.
///
///   Pallet   100 mm x 75 mm — 1UP, 1.5" core outside,  500 pcs/roll
///   Scanning  50 mm x 25 mm — 1UP, 1.5" core outside, 2000 pcs/roll
enum LabelStock {
  /// Master pallet label. Goes on the pallet/stillage shroud, read by forklift
  /// HHT at putaway and picking, and by security at the gate.
  pallet(
    widthMm: 100,
    heightMm: 75,
    perRoll: 500,
    displayName: 'Pallet Label',
    // 100x75 has room to spare, so buy the extra damage tolerance: these ride
    // outdoors on trailers and get scuffed by strapping.
    errorCorrection: QrEcc.quartile,
    qrSizeMm: 34,
  ),

  /// Individual wheel / SPD pack scanning label. Small die-cut applied at the
  /// pack point and scanned once per wheel.
  scanning(
    widthMm: 50,
    heightMm: 25,
    perRoll: 2000,
    displayName: 'Scanning Label',
    // Only 25 mm of height to work with. Medium keeps the module count down so
    // each module stays several printer dots wide, which matters more for
    // read rate at this size than the extra correction Quartile would add.
    errorCorrection: QrEcc.medium,
    qrSizeMm: 19,
  );

  const LabelStock({
    required this.widthMm,
    required this.heightMm,
    required this.perRoll,
    required this.displayName,
    required this.errorCorrection,
    required this.qrSizeMm,
  });

  final double widthMm;
  final double heightMm;
  final int perRoll;
  final String displayName;
  final QrEcc errorCorrection;

  /// Edge length of the QR symbol including its quiet zone.
  final double qrSizeMm;

  /// Roll core, identical for both stocks.
  static const String coreInches = '1.5"';

  /// 1UP — one label across the web, for both stocks.
  static const int up = 1;

  double get aspectRatio => widthMm / heightMm;

  /// e.g. `100 MM X 75 MM`, matching how the roll itself is labelled.
  String get sizeLabel =>
      '${_trim(widthMm)} MM X ${_trim(heightMm)} MM';

  String get specLabel =>
      'Avery Chromo $sizeLabel • ${up}UP $coreInches Core Outside • $perRoll pcs/roll';

  /// Resolves the stock for a sticker type used by the print helpers.
  ///
  /// Anything applied to a unit load — a pallet, stillage, or returnable asset
  /// — gets the large stock: those carry a full data grid and are read from a
  /// forklift or across a gate. Anything applied to a single wheel or boxed
  /// pack gets the small stock.
  ///
  /// Note that "SPD INDIVIDUAL PACK" and "SPD SPARE PACK" are single boxed
  /// wheels despite the word "pack", so they must not match the unit-load
  /// keywords below.
  static LabelStock forStickerType(String? stickerType) {
    final t = (stickerType ?? '').toUpperCase();
    const unitLoad = ['PALLET', 'MASTER', 'ASSET', 'RETURNABLE', 'STILLAGE'];
    if (unitLoad.any(t.contains)) return LabelStock.pallet;
    return LabelStock.scanning;
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

/// QR error-correction level, mapped to the `qr` package's constants at the
/// point of use so callers never deal with its bare ints.
enum QrEcc { low, medium, quartile, high }
