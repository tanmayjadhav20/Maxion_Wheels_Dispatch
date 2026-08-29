import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/orbit_loader.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndProceed();
  }

  Future<void> _checkAuthAndProceed() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OrbitLoader(size: 160),
              const SizedBox(height: 32),
              Text(
                AppTokens.appName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'DISPATCH OPERATIONS DIGITALIZATION',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 40),
              // Ribbon Animated Bar
              _SplashRibbonBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashRibbonBar extends StatefulWidget {
  const _SplashRibbonBar();

  @override
  State<_SplashRibbonBar> createState() => _SplashRibbonBarState();
}

class _SplashRibbonBarState extends State<_SplashRibbonBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(-1.1 + _controller.value * 4.7, 0),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                gradient: AppColors.ribbonGradient,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }
}
