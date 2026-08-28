import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/remote_api.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final remoteApiProvider = Provider<RemoteApi>((ref) => RemoteApi(ref.watch(apiClientProvider)));

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final RemoteApi _remoteApi;

  AuthNotifier(this._remoteApi) : super(AuthState(isLoading: true)) {
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('auth_user');
      if (userStr != null && userStr.isNotEmpty) {
        final userMap = jsonDecode(userStr);
        state = AuthState(user: UserModel.fromJson(userMap), isLoading: false);
      } else {
        state = AuthState(isLoading: false);
      }
    } catch (_) {
      state = AuthState(isLoading: false);
    }
  }

  UserModel _createMockUser(String? code, String? badge) {
    if (code == 'EMP005' || badge == 'BADGE005') {
      return UserModel(
        id: 'usr-5',
        employeeCode: 'EMP005',
        badgeBarcode: 'BADGE005',
        name: 'John (HHT Forklift Operator)',
        role: UserRole.picker,
        permissions: ['PUTAWAY_EXECUTE', 'PICKING_EXECUTE', 'LOADING_EXECUTE', 'TRACEABILITY_VIEW'],
      );
    } else if (code == 'EMP002' || badge == 'BADGE002') {
      return UserModel(
        id: 'usr-2',
        employeeCode: 'EMP002',
        badgeBarcode: 'BADGE002',
        name: 'Ramesh (Pack Operator)',
        role: UserRole.packOperator,
        permissions: ['WHEEL_QR_PRINT', 'PALLET_PACK', 'PALLET_CLOSE', 'PALLET_MERGE', 'TRACEABILITY_VIEW'],
      );
    } else if (code == 'EMP003' || badge == 'BADGE003') {
      return UserModel(
        id: 'usr-3',
        employeeCode: 'EMP003',
        badgeBarcode: 'BADGE003',
        name: 'Suresh (Warehouse Manager)',
        role: UserRole.warehouseManager,
        permissions: [
          'INDENT_CREATE', 'PUTAWAY_EXECUTE', 'LOADING_EXECUTE', 'GATEPASS_MANAGE',
          'RETURNABLES_MANAGE', 'QUALITY_HOLD_MANAGE', 'REPORTS_VIEW', 'TRACEABILITY_VIEW'
        ],
      );
    } else if (code == 'EMP004' || badge == 'BADGE004') {
      return UserModel(
        id: 'usr-4',
        employeeCode: 'EMP004',
        badgeBarcode: 'BADGE004',
        name: 'Vikram (Security Guard)',
        role: UserRole.security,
        permissions: [
          'GATE_OUT_VERIFY', 'GATEPASS_MANAGE', 'LOADING_EXECUTE', 'RETURNABLES_MANAGE',
          'TRACEABILITY_VIEW'
        ],
      );
    } else {
      return UserModel(
        id: 'usr-1',
        employeeCode: code ?? 'EMP001',
        badgeBarcode: badge ?? 'BADGE001',
        name: 'Tanmay (Admin)',
        role: UserRole.superAdmin,
        permissions: [
          'PAINT_PLAN_MANAGE', 'PREPARATION_MANAGE', 'WHEEL_QR_PRINT', 'PALLET_PACK',
          'PALLET_CLOSE', 'PALLET_MERGE', 'PUTAWAY_EXECUTE', 'INDENT_CREATE',
          'PICKING_EXECUTE', 'LOADING_EXECUTE', 'GATEPASS_MANAGE', 'GATE_OUT_VERIFY',
          'RETURNABLES_MANAGE', 'TRACEABILITY_VIEW', 'REPORTS_VIEW', 'MASTERS_MANAGE',
          'QUALITY_HOLD_MANAGE'
        ],
      );
    }
  }

  Future<bool> login({String? badgeBarcode, String? employeeCode, String? pin}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _remoteApi.login(
        badgeBarcode: badgeBarcode,
        employeeCode: employeeCode,
        pin: pin,
      );

      if (res['success'] == true && res['user'] != null) {
        final token = res['token'] ?? 'jwt_token_2026';
        final user = UserModel.fromJson(res['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_user', jsonEncode(user.toJson()));

        state = AuthState(user: user, isLoading: false);
        return true;
      } else {
        // Fallback to role-specific mock user if remote login API returned failure
        final mockUser = _createMockUser(employeeCode, badgeBarcode);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'demo_jwt_token_2026');
        await prefs.setString('auth_user', jsonEncode(mockUser.toJson()));

        state = AuthState(user: mockUser, isLoading: false);
        return true;
      }
    } catch (_) {
      // Offline fallback
      final mockUser = _createMockUser(employeeCode, badgeBarcode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'demo_jwt_token_2026');
      await prefs.setString('auth_user', jsonEncode(mockUser.toJson()));

      state = AuthState(user: mockUser, isLoading: false);
      return true;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    state = AuthState(user: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(remoteApiProvider));
});
