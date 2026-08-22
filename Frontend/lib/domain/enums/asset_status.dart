enum ReturnableAssetStatus {
  inStock,
  issuedToFloor,
  loadedOnVehicle,
  withCustomer,
  returned,
  inRepair,
  scrapped;

  static ReturnableAssetStatus fromCode(String code) {
    switch (code) {
      case 'In Stock (Empty)':
        return ReturnableAssetStatus.inStock;
      case 'Issued to Floor':
        return ReturnableAssetStatus.issuedToFloor;
      case 'Loaded on Vehicle':
        return ReturnableAssetStatus.loadedOnVehicle;
      case 'With Customer':
        return ReturnableAssetStatus.withCustomer;
      case 'Returned':
        return ReturnableAssetStatus.returned;
      case 'In Repair':
        return ReturnableAssetStatus.inRepair;
      case 'Scrapped':
        return ReturnableAssetStatus.scrapped;
      default:
        return ReturnableAssetStatus.inStock;
    }
  }
}
