import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../local/auth_local_service.dart';

/**
 * Tujuannya adalah menyediakan palet warna yang konsisten
 * di seluruh aplikasi, sehingga memudahkan pengelolaan tema 
 * dan penyesuaian tampilan aplikasi
 *
 */

/// Layanan otentikasi utama yang berinteraksi dengan Supabase.
/// Menangani Login, Register, dan Pairing jam tangan.
class AuthService {
  final _supabase = Supabase.instance.client;

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  static String _mapAuthError(AuthException e, {required bool isRegister}) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan masuk atau gunakan email lain.';
    }
    if (msg.contains('invalid') && msg.contains('email')) {
      return 'Email ditolak oleh server autentikasi. '
          'Periksa ejaan (contoh: nama@gmail.com), pastikan tidak ada spasi, '
          'dan coba email lain jika akun sudah pernah didaftarkan.';
    }
    if (msg.contains('password')) {
      return isRegister
          ? 'Password tidak memenuhi syarat (minimal 8 karakter).'
          : 'Email atau password salah.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Terlalu banyak percobaan daftar/login. '
          'Tunggu 5–15 menit lalu coba lagi, atau matikan sementara '
          'konfirmasi email di Supabase (mode development).';
    }
    return isRegister ? 'Gagal mendaftar: ${e.message}' : 'Gagal masuk: ${e.message}';
  }

  /// Melakukan login menggunakan email dan password.
  /// Jika berhasil, menyimpan status login ke lokal.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _normalizeEmail(email),
        password: password,
      );

      if (response.session != null) {
        await AuthLocalService.setLoggedIn(true);
        await _insertPendingProfileIfExists();
      }

      return response;
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e, isRegister: false));
    } catch (e) {
      throw Exception('Gagal melakukan login: $e');
    }
  }

  Future<Map<String, dynamic>?> _findPharmacistInvitation(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    final variants = <String>{trimmed, trimmed.toUpperCase()};
    final columns = ['token', 'code', 'invite_code'];

    for (final col in columns) {
      for (final value in variants) {
        try {
          final row = await _supabase
              .from('pharmacist_invitations')
              .select(
                'id, token, email, name, license_number, pharmacy_name, is_used, expires_at',
              )
              .eq(col, value)
              .eq('is_used', false)
              .maybeSingle();
          if (row != null) {
            return Map<String, dynamic>.from(row as Map);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Map<String, dynamic> _pharmacistInsertMap({
    required String authId,
    required UserModel user,
    required String normalizedEmail,
    Map<String, dynamic>? invitation,
  }) {
    return {
      'auth_id': authId,
      'email': normalizedEmail,
      'name': invitation?['name']?.toString().trim().isNotEmpty == true
          ? invitation!['name'].toString()
          : user.fullName,
      'phone': user.phoneNumber,
      if (invitation?['license_number'] != null)
        'license_number': invitation!['license_number'],
      if (invitation?['pharmacy_name'] != null)
        'pharmacy_name': invitation!['pharmacy_name'],
      'is_verified': false,
      'is_active': true,
    };
  }

  Future<void> _markPharmacistInvitationUsed(
    Map<String, dynamic>? invitation,
    String? pharmacistId,
  ) async {
    if (invitation == null) return;
    final id = invitation['id']?.toString();
    if (id == null) return;
    try {
      await _supabase.from('pharmacist_invitations').update({
        'is_used': true,
        if (pharmacistId != null) 'used_by': pharmacistId,
        'used_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (_) {}
  }

  /// Mendaftarkan pengguna baru (Pasien atau Apoteker).
  /// Memvalidasi kode apoteker jika role yang dipilih adalah Apoteker.
  Future<AuthResponse> register({
    required UserModel user,
    required String password,
    String? pharmacistCode,
  }) async {
    final isPharmacist =
        pharmacistCode != null && pharmacistCode.trim().isNotEmpty;
    final role = isPharmacist ? 'apoteker' : 'pasien';

    try {
      Map<String, dynamic>? invitation;
      final String? trimmedCode = pharmacistCode?.trim();

      if (isPharmacist && trimmedCode != null) {
        invitation = await _findPharmacistInvitation(trimmedCode);
        if (invitation == null) {
          throw Exception(
            'Kode registrasi apoteker tidak valid atau sudah digunakan.',
          );
        }
      }

      final normalizedEmail = _normalizeEmail(user.email);

      if (isPharmacist && invitation != null) {
        final inviteEmail = invitation['email']?.toString().trim().toLowerCase();
        if (inviteEmail != null &&
            inviteEmail.isNotEmpty &&
            inviteEmail != normalizedEmail) {
          throw Exception(
            'Email harus sama dengan undangan apoteker ($inviteEmail).',
          );
        }
      }

      final authResponse = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {'full_name': user.fullName},
      );

      if (authResponse.user != null) {
        final authId = authResponse.user!.id;

        if (authResponse.session != null) {
          if (isPharmacist) {
            final pharmData = _pharmacistInsertMap(
              authId: authId,
              user: user,
              normalizedEmail: normalizedEmail,
              invitation: invitation,
            );
            final inserted = await _supabase
                .from('pharmacists')
                .insert(pharmData)
                .select('id')
                .single();
            await _markPharmacistInvitationUsed(
              invitation,
              inserted['id']?.toString(),
            );
          } else {
            final profileData = user
                .copyWith(role: role)
                .toSupabaseInsertMap(authId: authId);
            await _supabase.from('users').insert(profileData);
          }
          await AuthLocalService.setLoggedIn(true);
        } else {
          final pending = isPharmacist
              ? {
                  'profile_table': 'pharmacists',
                  ..._pharmacistInsertMap(
                    authId: authId,
                    user: user,
                    normalizedEmail: normalizedEmail,
                    invitation: invitation,
                  ),
                  if (invitation != null) 'invitation_id': invitation['id'],
                }
              : {
                  'profile_table': 'users',
                  ...user
                      .copyWith(role: role)
                      .toSupabaseInsertMap(authId: authId),
                };
          await _savePendingProfile(pending);
        }
      }

      return authResponse;
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e, isRegister: true));
    } on PostgrestException catch (e) {
      throw Exception(
        'Akun berhasil dibuat tetapi profil gagal disimpan: ${e.message}. '
        'Hubungi admin atau coba masuk kembali.',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Keluar dari aplikasi (Logout) dan menghapus sesi lokal.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await AuthLocalService.clearLogin();
  }

  /// Menyimpan data profil sementara ke SharedPreferences jika registrasi offline/pending.
  Future<void> _savePendingProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_profile', jsonEncode(profileData));
    } catch (e) {
      // Handle error
    }
  }

  /// Mencoba memasukkan profil yang tertunda jika user sudah login.
  Future<void> _insertPendingProfileIfExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('pending_profile');
      if (pending == null) return;

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final Map<String, dynamic> pendingMap = Map<String, dynamic>.from(
        jsonDecode(pending),
      );

      final table = pendingMap['profile_table']?.toString() ?? 'users';
      final data = Map<String, dynamic>.from(pendingMap)
        ..remove('profile_table')
        ..remove('invitation_id')
        ..remove('pharmacist_code');

      if (!data.containsKey('auth_id')) {
        data['auth_id'] = currentUser.id;
      }

      if (table == 'pharmacists') {
        final existing = await _supabase
            .from('pharmacists')
            .select('id')
            .eq('auth_id', currentUser.id)
            .maybeSingle();
        if (existing == null) {
          final inserted = await _supabase
              .from('pharmacists')
              .insert(data)
              .select('id')
              .single();
          final invitationId = pendingMap['invitation_id']?.toString();
          if (invitationId != null) {
            await _markPharmacistInvitationUsed(
              {'id': invitationId},
              inserted['id']?.toString(),
            );
          }
        }
      } else {
        final existing = await _supabase
            .from('users')
            .select('id')
            .eq('auth_id', currentUser.id)
            .maybeSingle();
        if (existing == null) {
          final profileData = data.containsKey('name')
              ? data
              : UserModel.fromMap(data).toSupabaseInsertMap(
                  authId: currentUser.id,
                );
          await _supabase.from('users').insert(profileData);
        }
      }

      await prefs.remove('pending_profile');
    } catch (e) {
      print('Faild to insert pending profile: $e');
    }
  }

  /// Menghubungkan (pairing) akun user dengan jam tangan pintar.
  /// Memvalidasi kode pairing dan memperbarui refresh token.
  Future<dynamic> pairWatch({
    required String pairingCode,
    required String refreshToken,
    required String userId,
  }) async {
    try {
      final existingUser = await _supabase
          .from('pairings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingUser != null) {
        if (existingUser['pairing_code'] != pairingCode) {
          final targetRow = await _supabase
              .from('pairings')
              .select()
              .eq('pairing_code', pairingCode)
              .maybeSingle();

          if (targetRow != null) {
            await _supabase.from('pairings').delete().eq('user_id', userId);

            final response = await _supabase
                .from('pairings')
                .update({'user_id': userId, 'refresh_token': refreshToken})
                .eq('pairing_code', pairingCode)
                .select();
            return response;
          } else {
            final response = await _supabase
                .from('pairings')
                .update({
                  'pairing_code': pairingCode,
                  'refresh_token': refreshToken,
                })
                .eq('user_id', userId)
                .select();
            return response;
          }
        } else {
          final response = await _supabase
              .from('pairings')
              .update({'refresh_token': refreshToken})
              .eq('user_id', userId)
              .select();
          return response;
        }
      } else {
        final response = await _supabase
            .from('pairings')
            .update({'refresh_token': refreshToken, 'user_id': userId})
            .eq('pairing_code', pairingCode)
            .select();
        return response;
      }
    } catch (e) {
      rethrow;
    }
  }
}

