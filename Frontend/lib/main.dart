import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MaxionDispatchApp()));
}

class MaxionDispatchApp extends ConsumerWidget {
  const MaxionDispatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Maxion Wheels Dispatch Operations Digitalization',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      scrollBehavior: const _VistarScrollBehavior(),
      builder: (context, child) {
        // Keep the Android status/nav bars in step with the resolved theme.
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFF070611),
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: const Color(0xFFF6F4FB),
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Drag-to-scroll from any pointer, since the HHT terminals and the desktop
/// dispatch office share these screens.
class _VistarScrollBehavior extends MaterialScrollBehavior {
  const _VistarScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
