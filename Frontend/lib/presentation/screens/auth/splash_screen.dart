import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tokens.dart';
import '../../../core/theme/vistar_backdrop.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/orbit_loader.dart';
import '../../widgets/vistar_logo.dart';

/// Splash: orbit S loader, wordmark, uppercase tagline, ribbon progress bar.
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
    context.go(ref.read(authProvider).isAuthenticated ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vistar;

    return Scaffold(
      backgroundColor: p.bg,
      body: VistarBackdrop(
        showWatermark: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const OrbitLoader(size: 200),
                const SizedBox(height: 36),
                const VistarWordmark(height: 52),
                const SizedBox(height: 14),
                Text(
                  'DISPATCH OPERATIONS DIGITALIZATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.txt3,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 40),
                const RibbonProgressBar(),
                const SizedBox(height: 18),
                Text(
                  'Powered by ${AppTokens.appName}',
                  style: TextStyle(
                    color: p.txt3.withValues(alpha: 0.7),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
