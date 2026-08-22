import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';

class UserModel extends AppUser {
  UserModel({
    required super.id,
    required super.employeeCode,
    required super.badgeBarcode,
    required super.name,
    required super.role,
    required super.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      badgeBarcode: json['badgeBarcode'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.fromCode(json['role'] ?? ''),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'badgeBarcode': badgeBarcode,
      'name': name,
      'role': role.name,
      'permissions': permissions,
    };
  }
}
