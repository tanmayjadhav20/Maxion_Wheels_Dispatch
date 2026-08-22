enum PalletTypeSeries {
  P, // Full pallet
  H, // Half pallet
  M; // Merged pallet

  static PalletTypeSeries fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'P':
        return PalletTypeSeries.P;
      case 'H':
        return PalletTypeSeries.H;
      case 'M':
        return PalletTypeSeries.M;
      default:
        return PalletTypeSeries.P;
    }
  }
}
