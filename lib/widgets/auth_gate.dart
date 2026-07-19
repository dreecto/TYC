import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Decides between the login screen and the main app shell based on the
/// current Supabase session, and reacts to sign-in / sign-out live.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.onAuthStateChange,
      builder: (context, snapshot) {
        // While the stream hasn't emitted yet, fall back to the current
        // session so a warm restart doesn't flash the login screen.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !AuthService.isSignedIn) {
          return const _SplashLoader();
        }

        final session =
            snapshot.data?.session ?? AuthService.currentSession;

        if (session != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ground,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
