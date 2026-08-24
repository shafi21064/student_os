import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/app/router.dart';
import 'package:studentos/core/notifications/notification_service.dart';
import 'package:studentos/core/theme/app_theme.dart';
import 'package:studentos/state/settings_controller.dart';

class StudentOsApp extends ConsumerStatefulWidget {
  const StudentOsApp({super.key});

  @override
  ConsumerState<StudentOsApp> createState() => _StudentOsAppState();
}

class _StudentOsAppState extends ConsumerState<StudentOsApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.instance.init());
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'StudentOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
