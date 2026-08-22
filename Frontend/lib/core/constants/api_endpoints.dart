class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://localhost:5000/api';

  static const String login = '/auth/login';
  static const String currentUser = '/auth/me';

  static const String paintPlan = '/paint-plan';
  static const String planVsActual = '/paint-plan/plan-vs-actual';

  static const String prepChecklist = '/preparation/checklist';

  static const String printWheelQr = '/pack/print-wheel-qr';
  static const String activePallet = '/pack/active-pallet';
  static const String scanWheel = '/pack/scan-wheel';
  static const String closePallet = '/pack/close-pallet';
  static const String resumeHalfPallet = '/pack/resume-half-pallet';

  static const String warehouseMap = '/warehouse/map';
  static const String halfPalletRegister = '/warehouse/half-pallet-register';
  static const String putaway = '/warehouse/putaway';
  static const String relocate = '/warehouse/relocate';

  static const String indents = '/picking/indents';
  static const String pickLists = '/picking/pick-lists';
  static const String scanPick = '/picking/scan-pick';

  static const String gatePasses = '/dispatch/gate-passes';
  static const String createGatePass = '/dispatch/create-gate-pass';
  static const String scanLoading = '/dispatch/scan-loading';
  static const String verifyGateOut = '/dispatch/verify-gate-out';

  static const String returnableAssets = '/returnables/assets';
  static const String registerAsset = '/returnables/register';
  static const String receiveAsset = '/returnables/receive';
  static const String customerStatements = '/returnables/statements';

  static const String traceLookup = '/traceability/lookup';
  static const String scanToKnow = '/traceability/scan-to-know';
  static const String qualityHold = '/traceability/quality-hold';

  // QA Inspection & Wheel Replacement
  static const String qaInspectPallet = '/qa/inspect-pallet';
  static const String qaInspectionHistory = '/qa/inspection-history';

  // OEM / SPD Conversion
  static const String convertPalletToBoxes = '/conversion/pallet-to-boxes';
  static const String convertBoxesToPallet = '/conversion/boxes-to-pallet';
  static const String conversionHistory = '/conversion/history';

  // Job Cards
  static const String jobCards = '/job-cards';
  static const String generateJobCard = '/job-cards/generate';
  static const String submitJobCard = '/job-cards/submit';

  // HHT Guns & Devices
  static const String hhtDevices = '/hht/devices';
  static const String hhtAssignRole = '/hht/assign-role';
  static const String hhtHeartbeat = '/hht/heartbeat';

  static const String syncStatus = '/sync/status';
  static const String processSync = '/sync/process';
}
