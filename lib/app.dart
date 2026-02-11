import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propedia/core/router/app_router.dart';
import 'package:propedia/shared/theme/app_theme.dart';

class PropediaApp extends ConsumerWidget {
  const PropediaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Propedia',
      debugShowCheckedModeBanner: false,

      // 테마 설정
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // go_router 설정
      routerConfig: router,
    );
  }
}
