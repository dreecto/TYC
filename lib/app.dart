import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

class TycPartnerApp extends StatelessWidget {
  const TycPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TYC Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}
