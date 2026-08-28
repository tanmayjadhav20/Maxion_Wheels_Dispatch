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

  void _onLogin() async {
    final empCode = _codeController.text.trim();
    final pinCode = _pinController.text.trim();

    if (empCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan Employee Code'), backgroundColor: AppColors.warn),
      );
      return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? const Color(0x33000000) : const Color(0x1A000000),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
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
                      decoration: InputDecoration(
                        labelText: 'EMPLOYEE CODE / BADGE BARCODE',
                        labelStyle: TextStyle(color: context.textMuted),
                        prefixIcon: Icon(Icons.badge_outlined, color: context.textMuted),
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'SECURITY PIN (OPTIONAL FOR OPERATORS)',
                        labelStyle: TextStyle(color: context.textMuted),
                        prefixIcon: Icon(Icons.lock_outline, color: context.textMuted),
                        filled: true,
                        fillColor: context.bgSurfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      children: _users.map((u) {
                        final empCode = u['employeeCode'] ?? '';
                        final isSelected = _selectedEmpCode == empCode;
                        return ChoiceChip(
                          label: Text('${u['name'] ?? empCode} ($empCode)'),
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
                                _selectedEmpCode = empCode;
                                _codeController.text = empCode;
                                _pinController.text = u['pin'] ?? '';
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: isDark ? AppColors.bg : Theme.of(context).scaffoldBackgroundColor,
                    border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Stack(
                    children: [
                      // Huge Rotated Faint S Watermark
                      Positioned(
                        right: -100,
                        bottom: -100,
                        child: Opacity(
                          opacity: isDark ? 0.16 : 0.06,
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
              // Right Form Panel
              Expanded(
                flex: 95,
                child: Container(
                  color: isDark ? AppColors.bg2 : Theme.of(context).cardColor,
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
