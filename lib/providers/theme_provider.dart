import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Notifier para gerenciar o modo de tema do app
class ThemeModeNotifier extends StateNotifier<ThemeModeOption> {
  static const String _themeModeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeModeOption.system) {
    _loadThemeMode();
  }

  /// Carrega o modo de tema salvo
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);
    
    if (savedMode != null) {
      state = ThemeModeOption.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => ThemeModeOption.system,
      );
    }
  }

  /// Define o modo de tema
  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Converte ThemeModeOption para ThemeMode do Flutter
  ThemeMode get flutterThemeMode {
    switch (state) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}

/// Provider para o modo de tema
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModeOption>((ref) {
  return ThemeModeNotifier();
});

/// Provider para obter o ThemeMode do Flutter
/// Observa o state do themeModeProvider para reagir a mudanças
final flutterThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeOption = ref.watch(themeModeProvider);
  
  switch (themeOption) {
    case ThemeModeOption.light:
      return ThemeMode.light;
    case ThemeModeOption.dark:
      return ThemeMode.dark;
    case ThemeModeOption.system:
      return ThemeMode.system;
  }
});
