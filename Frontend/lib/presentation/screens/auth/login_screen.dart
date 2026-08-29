import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vistar_backdrop.dart';
import '../../../domain/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/ribbon_text.dart';
import '../../widgets/vistar_logo.dart';

/// Login: a split art / form layout on desktop, single-column on the shop floor.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedEmpCode;

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final remoteApi = ref.read(remoteApiProvider);
      final res = await remoteApi.get('/auth/users');
      if (res['success'] == true && res['users'] != null) {
        final rawUsers = res['users'] as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _users = rawUsers.map((u) => Map<String, dynamic>.from(u is Map ? u : {})).toList();
          if (_users.isNotEmpty) {
            _selectedEmpCode = _users.first['employeeCode']?.toString();
            _codeController.text = _users.first['employeeCode']?.toString() ?? '';
            _pinController.text = _users.first['pin']?.toString() ?? '';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onLogin() async {
    final empCode = _codeController.text.trim();
    final pinCode = _pinController.text.trim();

    if (empCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or scan Employee Code'),
          backgroundColor: AppColors.warn,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          employeeCode: empCode,
          pin: pinCode,
        );
    if (!success || !mounted) return;

    final user = ref.read(authProvider).user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (user == null) {
        context.go('/dashboard');
        return;
      }
      if (user.role == UserRole.picker) {
        context.go('/hht-picking');
      } else if (user.canViewReports) {
        context.go('/dashboard');
      } else if (user.canPackPallet) {
        context.go('/pack-point');
      } else if (user.canExecutePutaway) {
        context.go('/warehouse');
      } else if (user.canVerifyGateOut) {
        context.go('/dispatch');
      } else {
        context.go('/traceability');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;

    return Scaffold(
      backgroundColor: p.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (!isDesktop) {
            return VistarBackdrop(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                  child: _formPanel(showLogo: true),
                ),
              ),
            );
          }

          return Row(
            children: [
              // Left art panel — 1.05fr
              Expanded(flex: 105, child: _artPanel()),
              // Right form panel — .95fr
              Expanded(
                flex: 95,
                child: Container(
                  color: p.bg2,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: AppTokens.pScreen,
                      child: _formPanel(showLogo: false),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _artPanel() {
    final p = context.vistar;

    return VistarBackdrop(
      showWatermark: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: p.line)),
        ),
        child: Stack(
          children: [
            // Huge rotated faint S, bled off the bottom-right corner
            Positioned(
              right: -140,
              bottom: -140,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: 0.12,
                  child: VistarSMark(size: 560, opacity: p.isDark ? 0.16 : 0.07),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const VistarWordmark(height: 54),
                  const SizedBox(height: 40),
                  RibbonText(
                    'MAXION WHEELS',
                    style: AppTheme.display(p.txt, size: 44, weight: FontWeight.w900, letterSpacing: -1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dispatch Floor Digitalization Platform',
                    style: AppTheme.display(p.txt, size: 26, weight: FontWeight.w800, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      'Digital paint line planning, 100% QR traceability for every wheel '
                      '& pallet, full/half/merged pallet control, directed picking and '
                      'printed gate passes.',
                      style: AppTheme.body(p.txt2, size: 15, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 36,
                    runSpacing: 20,
                    children: [
                      _stat('0%', 'Lost Scans', '100% Offline Mode'),
                      _stat('<1s', 'Scan Response', 'Poka-Yoke Verified'),
                      _stat('<5 min', 'Gate Out Time', 'Automated Pass'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String val, String label, String sub) {
    final p = context.vistar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonText(
          val,
          style: AppTheme.display(p.txt, size: 32, weight: FontWeight.w900, letterSpacing: -0.8),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.body(p.txt, size: 13, weight: FontWeight.w700)),
        Text(sub, style: AppTheme.body(p.txt3, size: 11)),
      ],
    );
  }

  Widget _formPanel({required bool showLogo}) {
    final p = context.vistar;
    final authState = ref.watch(authProvider);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppTokens.rLg),
          border: Border.all(color: p.line),
          boxShadow: [
            BoxShadow(
              color: p.shadowColor,
              blurRadius: 40,
              spreadRadius: -14,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLogo) ...[
              const VistarWordmark(height: 40),
              const SizedBox(height: 22),
            ] else ...[
              const VistarSMark(size: 34),
              const SizedBox(height: 18),
            ],
            Text(
              'Sign In to Dispatch Portal',
              style: AppTheme.display(p.txt, size: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan employee badge or enter employee code to begin shift',
              style: AppTheme.body(p.txt2, size: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              style: TextStyle(color: p.txt),
              decoration: const InputDecoration(
                labelText: 'EMPLOYEE CODE / BADGE BARCODE',
                prefixIcon: Icon(Icons.badge_outlined, size: 19),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pinController,
              obscureText: true,
              style: TextStyle(color: p.txt),
              onSubmitted: (_) => _onLogin(),
              decoration: const InputDecoration(
                labelText: 'SECURITY PIN (OPTIONAL FOR OPERATORS)',
                prefixIcon: Icon(Icons.lock_outline, size: 19),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'SELECT ROLE / WORK POINT',
              style: TextStyle(
                color: p.txt3,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in _users)
                  _RoleChip(
                    label: '${u['name'] ?? u['employeeCode'] ?? ''} (${u['employeeCode'] ?? ''})',
                    selected: _selectedEmpCode == u['employeeCode'],
                    onTap: () => setState(() {
                      _selectedEmpCode = u['employeeCode'];
                      _codeController.text = u['employeeCode'] ?? '';
                      _pinController.text = u['pin'] ?? '';
                    }),
                  ),
              ],
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: p.badTint,
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                  border: Border.all(color: p.bad.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: p.bad),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: TextStyle(color: p.bad, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              text: 'SIGN IN TO DISPATCH',
              icon: Icons.arrow_forward,
              isFullWidth: true,
              isLoading: authState.isLoading,
              onPressed: _onLogin,
            ),
          ],
        ),
      ),
    );
  }
}

/// `.role-chip` — the active chip takes the ribbon.
class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.ribbonGradient : null,
            color: selected ? null : p.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Colors.transparent : p.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : p.txt2,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
