import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../domain/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/vistar_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _codeController = TextEditingController(text: 'EMP001');
  final _pinController = TextEditingController(text: '1234');
  String _selectedRole = 'superAdmin';

  final List<Map<String, String>> _roles = [
    {'code': 'superAdmin', 'label': 'Admin / Super User'},
    {'code': 'packOperator', 'label': 'Pack Point Operator'},
    {'code': 'warehouseManager', 'label': 'Warehouse Manager'},
    {'code': 'picker', 'label': 'HHT Forklift Operator'},
    {'code': 'security', 'label': 'Security Officer'},
  ];

  void _onLogin() async {
    String empCode = _codeController.text.trim();
    String pinCode = _pinController.text.trim();

    if (_selectedRole == 'picker') {
      empCode = 'EMP005';
      pinCode = '4444';
    }

    final success = await ref.read(authProvider.notifier).login(
      employeeCode: empCode,
      pin: pinCode,
    );
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (user != null) {
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
        } else {
          context.go('/dashboard');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          Widget formPanel = Padding(
            padding: AppTokens.pScreen,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: AppTokens.pCard,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppTokens.rLg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show logo inside form card on mobile layout to avoid duplicate logos on desktop
                    if (!isDesktop) ...[
                      const VistarLogo(size: 52),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Sign In to Dispatch Portal',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan employee badge or enter employee code to begin shift',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'EMPLOYEE CODE / BADGE BARCODE',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      style: TextStyle(color: context.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'SECURITY PIN (OPTIONAL FOR OPERATORS)',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SELECT ROLE / WORK POINT',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _roles.map((r) {
                        final isSelected = _selectedRole == r['code'];
                        return ChoiceChip(
                          label: Text(r['label']!),
                          selected: isSelected,
                          selectedColor: AppColors.ribbonPink,
                          backgroundColor: context.bgSurfaceElevated,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : context.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedRole = r['code']!;
                                if (r['code'] == 'superAdmin') {
                                  _codeController.text = 'EMP001';
                                  _pinController.text = '1234';
                                } else if (r['code'] == 'packOperator') {
                                  _codeController.text = 'EMP002';
                                  _pinController.text = '1111';
                                } else if (r['code'] == 'warehouseManager') {
                                  _codeController.text = 'EMP003';
                                  _pinController.text = '2222';
                                } else if (r['code'] == 'picker') {
                                  _codeController.text = 'EMP005';
                                  _pinController.text = '4444';
                                } else if (r['code'] == 'security') {
                                  _codeController.text = 'EMP004';
                                  _pinController.text = '3333';
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        authState.error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
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
            ),
          );

          if (!isDesktop) {
            return Scaffold(
              backgroundColor: AppColors.bg,
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: formPanel,
                ),
              ),
            );
          }

          return Row(
            children: [
              // Left Art/Pitch Panel (1.05fr)
              Expanded(
                flex: 115,
                child: Container(
                  padding: const EdgeInsets.all(56),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border(right: BorderSide(color: AppColors.line)),
                  ),
                  child: Stack(
                    children: [
                      // Huge Rotated Faint S Watermark (Opacity .16)
                      Positioned(
                        right: -100,
                        bottom: -100,
                        child: Opacity(
                          opacity: 0.16,
                          child: Image.asset(
                            'assets/logo.png',
                            width: 520,
                            height: 520,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const VistarLogo(size: 68),
                            const SizedBox(height: 36),
                            ShaderMask(
                              shaderCallback: (bounds) => AppColors.ribbonGradient.createShader(bounds),
                              child: const Text(
                                'MAXION WHEELS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dispatch Floor Digitalization Platform',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Digital paint line planning, 100% QR traceability for every wheel & pallet, full/half/merged pallet control, directed picking & printed gate passes.',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Stats Row with Wrap for responsiveness
                            Wrap(
                              spacing: 32,
                              runSpacing: 16,
                              children: [
                                _buildStat(context, '0%', 'Lost Scans', '100% Offline Mode'),
                                _buildStat(context, '<1s', 'Scan Response', 'Poka-Yoke Verified'),
                                _buildStat(context, '<5 min', 'Gate Out Time', 'Automated Pass'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Form Panel (.95fr - --bg2)
              Expanded(
                flex: 95,
                child: Container(
                  color: AppColors.bg2,
                  child: formPanel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(BuildContext context, String val, String label, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.ribbonGradient.createShader(bounds),
          child: Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
