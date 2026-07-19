import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase auth for the partner app.
///
/// Access the shared client via [AuthService.client] anywhere in the app.
class AuthService {
  AuthService._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get _auth => client.auth;

  static Session? get currentSession => _auth.currentSession;

  static User? get currentUser => _auth.currentUser;

  static bool get isSignedIn => currentSession != null;

  /// Emits on sign-in / sign-out / token refresh.
  static Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() => _auth.signOut();
}
