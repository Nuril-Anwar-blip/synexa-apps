/// ====================================================================
/// File: supabase_client.dart
/// --------------------------------------------------------------------
/// Klien Supabase - Konfigurasi Backend
///
/// Dokumen ini menyediakan akses cepat ke klien Supabase yang
/// telah diinisialisasi di Global.init().
///
/// Cara Penggunaan:
///   import 'package:aplication_stroke/supabase/supabase_client.dart';
///
///   // Untuk akses tabel
///   final data = await SupabaseClient.client.from('users').select();
///
///   // Untuk auth
///   final user = SupabaseClient.client.auth.getUser();
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class untuk mengakses client Supabase dengan mudah.
class SupabaseManager {
  static final client = Supabase.instance.client;
}
