import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class GameForgerApp extends ConsumerWidget {
  const GameForgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    AppTheme.setLightMode(themeMode.isLight);

    return MaterialApp.router(
      key: ValueKey(themeMode),
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.materialMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
