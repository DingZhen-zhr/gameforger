import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

enum ForgeThemeMode {
  dark,
  light;

  ThemeMode get materialMode {
    return switch (this) {
      ForgeThemeMode.dark => ThemeMode.dark,
      ForgeThemeMode.light => ThemeMode.light,
    };
  }

  bool get isLight => this == ForgeThemeMode.light;

  String get label => isLight ? '浅色模式' : '深色模式';

  String get nextLabel => isLight ? '切换到深色模式' : '切换到浅色模式';
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ForgeThemeMode>((ref) {
      final controller = ThemeController();
      controller.load();
      return controller;
    });

class ThemeController extends StateNotifier<ForgeThemeMode> {
  ThemeController() : super(ForgeThemeMode.dark) {
    AppTheme.setLightMode(false);
  }

  static const _storageKey = 'gameforger_theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    final mode = stored == ForgeThemeMode.light.name
        ? ForgeThemeMode.light
        : ForgeThemeMode.dark;
    _apply(mode);
  }

  Future<void> toggle() {
    return setMode(state.isLight ? ForgeThemeMode.dark : ForgeThemeMode.light);
  }

  Future<void> setMode(ForgeThemeMode mode) async {
    _apply(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }

  void _apply(ForgeThemeMode mode) {
    AppTheme.setLightMode(mode.isLight);
    state = mode;
  }
}
