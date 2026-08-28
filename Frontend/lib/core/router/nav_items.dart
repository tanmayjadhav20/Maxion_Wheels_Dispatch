import 'package:flutter/material.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';

class NavItem {
  final String path;
  final String title;
  final IconData icon;
  final String group;
  final String? badge;
  final bool Function(AppUser user) canAccess;

  const NavItem({
    required this.path,
    required this.title,
    required this.icon,
    required this.group,
    this.badge,
    required this.canAccess,
  });
}

final List<NavItem> navItems = [
  // Group: OPERATIONS
  NavItem(
    path: '/dashboard',
    title: 'Dashboard',
    icon: Icons.dashboard_outlined,
    group: 'OPERATIONS',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager,
  ),
  NavItem(
    path: '/paint-plan',
    title: 'Paint Plan (Mod 1)',
    icon: Icons.edit_calendar_outlined,
    group: 'OPERATIONS',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.dispatchPlanner,
  ),
  NavItem(
    path: '/wheel-qr-print',
    title: 'Wheel QR Print (Mod 2)',
    icon: Icons.qr_code_2_outlined,
    group: 'OPERATIONS',
    badge: 'PRINT',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.packOperator || user.role == UserRole.prepOperator,
  ),
  NavItem(
    path: '/preparation',
    title: 'Preparation & Half Pallets',
    icon: Icons.checklist_rtl_outlined,
    group: 'OPERATIONS',
    badge: 'HALF',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.prepOperator || user.role == UserRole.packOperator,
  ),
  NavItem(
    path: '/pack-point',
    title: 'Pack Point (Mod 3-5)',
    icon: Icons.qr_code_scanner_outlined,
    group: 'OPERATIONS',
    badge: 'LIVE',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.packOperator,
  ),
  NavItem(
    path: '/warehouse',
    title: 'Warehouse & Putaway (Mod 6)',
    icon: Icons.warehouse_outlined,
    group: 'OPERATIONS',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager || user.role == UserRole.putawayOperator || user.role == UserRole.picker,
  ),
  NavItem(
    path: '/picking',
    title: 'Indent Entry (Manager)',
    icon: Icons.local_shipping_outlined,
    group: 'OPERATIONS',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager,
  ),
  NavItem(
    path: '/hht-picking',
    title: 'HHT Directed Picking',
    icon: Icons.qr_code_scanner_outlined,
    group: 'OPERATIONS',
    badge: 'HHT',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.picker,
  ),
  NavItem(
    path: '/dispatch',
    title: 'Gate Pass & Loading',
    icon: Icons.gavel_outlined,
    group: 'OPERATIONS',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager || user.role == UserRole.security || user.role == UserRole.loadingSupervisor,
  ),

  // Group: ASSETS & QUALITY
  NavItem(
    path: '/returnables',
    title: 'Returnables (Mod 9)',
    icon: Icons.inventory_2_outlined,
    group: 'ASSETS & QUALITY',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager || user.role == UserRole.security || user.role == UserRole.stores,
  ),
  NavItem(
    path: '/quality-inspection',
    title: 'QA Inspection (IOC)',
    icon: Icons.verified_outlined,
    group: 'ASSETS & QUALITY',
    badge: 'HOLD',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.supervisor,
  ),
  NavItem(
    path: '/oem-spd-conversion',
    title: 'OEM / SPD Conversion',
    icon: Icons.sync_alt_outlined,
    group: 'ASSETS & QUALITY',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager,
  ),

  // Group: REPORTS & ADMIN
  NavItem(
    path: '/traceability',
    title: 'Traceability (Mod 10)',
    icon: Icons.search_outlined,
    group: 'REPORTS & ADMIN',
    canAccess: (user) => true,
  ),
  NavItem(
    path: '/job-card-report',
    title: 'Job Card Report',
    icon: Icons.assignment_outlined,
    group: 'REPORTS & ADMIN',
    canAccess: (user) => user.role == UserRole.superAdmin || user.role == UserRole.warehouseManager,
  ),
  NavItem(
    path: '/hht-management',
    title: 'HHT Guns (4 Active)',
    icon: Icons.qr_code_scanner_outlined,
    group: 'REPORTS & ADMIN',
    canAccess: (user) => user.role == UserRole.superAdmin,
  ),
  NavItem(
    path: '/sync-monitor',
    title: 'Sync Monitor (Sec 7)',
    icon: Icons.sync_outlined,
    group: 'REPORTS & ADMIN',
    canAccess: (user) => user.role == UserRole.superAdmin,
  ),
];
