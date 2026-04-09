class SupabaseConfig {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    if (_url.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL. Run the app with --dart-define=SUPABASE_URL=... or --dart-define-from-file=supabase.env.json.',
      );
    }
    return _url;
  }

  static String get anonKey {
    if (_anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_ANON_KEY. Run the app with --dart-define=SUPABASE_ANON_KEY=... or --dart-define-from-file=supabase.env.json.',
      );
    }
    return _anonKey;
  }

  const SupabaseConfig._();
}