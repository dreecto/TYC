import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessors for values loaded from the gitignored `.env` file.
///
/// Call [Env.load] once at startup (before reading any value) — see main.dart.
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');

  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing "$key" in .env. Copy .env.example to .env and fill it in.',
      );
    }
    return value;
  }
}
