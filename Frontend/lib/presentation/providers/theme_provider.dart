import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the operator's appearance choice across shifts.
///
/// Defaults to dark: the dispatch floor and HHT terminals are the primary
/// surface, and the Vistar design system is dark-first. Light mode is a full
/// peer, not a degraded fallback — see `VistarPalette.light`.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const String _key = 'vistar_user_theme_mode';

  static const Map<String, ThemeMode> _fromName = {
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
    'system': ThemeMode.system,
  };

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = _fromName[prefs.getString(_key)];
      if (saved != null) state = saved;
    } catch (_) {
      // A blocked or unavailable store just means we keep the default.
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }

  /// Flips light <-> dark.
  ///
  /// From [ThemeMode.system] this resolves against what the device is actually
  /// showing, so the first tap always visibly inverts rather than appearing to
  /// do nothing.
  void toggleTheme() {
    final effectiveIsDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
    };
    setTheme(effectiveIsDark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
