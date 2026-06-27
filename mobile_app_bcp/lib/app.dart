// app.dart
import 'package:flutter/material.dart';
import 'package:mobile_app_bcp/core/config/app_constants.dart';
import 'package:mobile_app_bcp/core/theme/app_theme.dart';
import 'package:mobile_app_bcp/core/router/app_router.dart';

class BcpApp extends StatelessWidget {
  const BcpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
