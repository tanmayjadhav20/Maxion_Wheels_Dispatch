import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/dispatch/gate_pass_screen.dart';
import '../../presentation/screens/pack_point/pallet_build_screen.dart';
import '../../presentation/screens/paint_plan/paint_plan_screen.dart';
import '../../presentation/screens/picking/indent_entry_screen.dart';
import '../../presentation/screens/picking/hht_picking_execution_screen.dart';
import '../../presentation/screens/reports/management_dashboard_screen.dart';
import '../../presentation/screens/reports/sync_monitor_screen.dart';
import '../../presentation/screens/returnables/returnable_asset_register_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/traceability/wheel_traceability_screen.dart';
import '../../presentation/screens/warehouse/half_pallet_register_screen.dart';
import '../../presentation/screens/warehouse/putaway_screen.dart';
import '../../presentation/screens/quality/quality_inspection_screen.dart';
import '../../presentation/screens/conversion/oem_spd_conversion_screen.dart';
import '../../presentation/screens/reports/job_card_report_screen.dart';
import '../../presentation/screens/hht/hht_device_management_screen.dart';
import 'refresh_gate.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Stateful Shell Route for Top-Level Destinations
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(child: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const ManagementDashboardScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/paint-plan',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const PaintPlanScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/preparation',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const HalfPalletRegisterScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pack-point',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const PalletBuildScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/warehouse',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const PutawayScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/picking',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const IndentEntryScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hht-picking',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const HhtPickingExecutionScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dispatch',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const GatePassScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/returnables',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const ReturnableAssetRegisterScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/traceability',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const WheelTraceabilityScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quality-inspection',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const QualityInspectionScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/oem-spd-conversion',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const OemSpdConversionScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/job-card-report',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const JobCardReportScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hht-management',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const HhtDeviceManagementScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sync-monitor',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: RefreshGate(
                    onRefresh: () {},
                    child: const SyncMonitorScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
