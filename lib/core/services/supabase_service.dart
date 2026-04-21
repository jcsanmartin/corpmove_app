import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio central de Supabase.
/// Accede al cliente desde cualquier lugar de la app con:
///   SupabaseService.client
class SupabaseService {
  static const String _supabaseUrl = 'https://egljgmaibeiocwzakufl.supabase.co';
  static const String _supabaseAnonKey =
      'sb_publishable_XCcLqQ5qce2ZmDrZ1sr0MQ_GI3yKh_1';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
