class QrUtils {
  QrUtils._();

  static bool isWheelQr(String qr) => qr.startsWith('MW|');
  static bool isPalletQr(String qr) => qr.startsWith('MWP|');
  static bool isLocationQr(String qr) => qr.startsWith('MWL|');
  static bool isReturnableTag(String qr) => qr.startsWith('MWR|');
  static bool isGatePassQr(String qr) => qr.startsWith('MWG|');

  static String extractCleanCode(String qr) {
    if (qr.contains('|')) {
      final parts = qr.split('|');
      return parts.length > 1 ? parts[1] : qr;
    }
    return qr;
  }
}
