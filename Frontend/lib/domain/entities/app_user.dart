import '../enums/user_role.dart';

class AppUser {
  final String id;
  final String employeeCode;
  final String badgeBarcode;
  final String name;
  final UserRole role;
  final List<String> permissions;

  AppUser({
    required this.id,
    required this.employeeCode,
    required this.badgeBarcode,
    required this.name,
    required this.role,
    required this.permissions,
  });

  bool hasPermission(String perm) =>
      role == UserRole.superAdmin || permissions.contains(perm);

  bool get canManagePaintPlan => hasPermission('PAINT_PLAN_MANAGE');
  bool get canManagePreparation => hasPermission('PREPARATION_MANAGE');
  bool get canPrintWheelQr => hasPermission('WHEEL_QR_PRINT');
  bool get canPackPallet => hasPermission('PALLET_PACK');
  bool get canClosePallet => hasPermission('PALLET_CLOSE');
  bool get canExecutePutaway => hasPermission('PUTAWAY_EXECUTE');
  bool get canCreateIndent => hasPermission('INDENT_CREATE');
  bool get canExecutePicking => hasPermission('PICKING_EXECUTE');
  bool get canExecuteLoading => hasPermission('LOADING_EXECUTE');
  bool get canManageGatePass => hasPermission('GATEPASS_MANAGE');
  bool get canVerifyGateOut => hasPermission('GATE_OUT_VERIFY');
  bool get canManageReturnables => hasPermission('RETURNABLES_MANAGE');
  bool get canViewTraceability => hasPermission('TRACEABILITY_VIEW');
  bool get canViewReports => hasPermission('REPORTS_VIEW');
  bool get canManageHold => hasPermission('QUALITY_HOLD_MANAGE');
}
