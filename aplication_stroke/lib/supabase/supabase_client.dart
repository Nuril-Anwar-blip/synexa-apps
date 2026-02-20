import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class untuk mengakses client Supabase dengan mudah.
class SupabaseManager {
  static final client = Supabase.instance.client;
}

