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

  /// Melakukan login menggunakan email dan password.
  /// Jika berhasil, menyimpan status login ke lokal.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await AuthLocalService.setLoggedIn(true);
        await _insertPendingProfileIfExists();
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Email atau password salah: ${e.message}');
    } catch (e) {
      throw Exception('Gagal melakukan login: $e');
    }
  }

  /// Mendaftarkan pengguna baru (Pasien atau Apoteker).
  /// Memvalidasi kode apoteker jika role yang dipilih adalah Apoteker.
  Future<AuthResponse> register({
    required UserModel user,
    required String password,
    String? pharmacistCode,
  }) async {
    final role = (pharmacistCode != null && pharmacistCode.isNotEmpty)
        ? 'apoteker'
        : 'pasien';

    try {
      dynamic invitationId;
      final String? trimmedCode = pharmacistCode?.trim();
      if (role == 'apoteker' && trimmedCode != null && trimmedCode.isNotEmpty) {
        Map<String, dynamic>? invitation;
        final candidateColumns = <String>[
          'code',
          'token',
          'invite_code',
          'admin_token',
          'kode',
          'kode_token',
          'registration_code',
        ];

        for (final col in candidateColumns) {
          try {
            final List<dynamic> rows = await _supabase
                .from('pharmacist_invitations')
                .select('id')
                .eq(col, trimmedCode)
                .eq('is_used', false)
                .limit(1);
            if (rows.isNotEmpty) {
              invitation = Map<String, dynamic>.from(rows.first as Map);
              break;
            }
          } catch (_) {}
        }

        if (invitation == null) {
          throw Exception(
            'Kode registrasi apoteker tidak valid atau sudah digunakan.',
          );
        }
        invitationId = invitation['id'];
      }

      final authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (authResponse.user != null) {
        final Map<String, dynamic> profileData = user.copyWith(role: role).toMap();

        if (authResponse.session != null) {
          profileData['id'] = authResponse.user!.id;
          await _supabase.from('users').insert(profileData);
          if (role == 'apoteker' &&
              trimmedCode != null &&
              trimmedCode.isNotEmpty) {
            if (invitationId != null) {
              try {
                await _supabase
                    .from('pharmacist_invitations')
                    .update({'is_used': true})
                    .eq('id', invitationId);
              } catch (_) {}
            } else {
              for (final col in [
                'code',
                'token',
                'invite_code',
                'admin_token',
                'kode',
                'kode_token',
                'registration_code',
              ]) {
                try {
                  final updated = await _supabase
                      .from('pharmacist_invitations')
                      .update({'is_used': true})
                      .eq(col, trimmedCode)
                      .eq('is_used', false)
                      .select();
                  if (updated.isNotEmpty) {
                    break;
                  }
                } catch (_) {}
              }
            }
          }
          await AuthLocalService.setLoggedIn(true);
        } else {
          if (role == 'apoteker' &&
              trimmedCode != null &&
              trimmedCode.isNotEmpty) {
            profileData['pharmacist_code'] = trimmedCode;
          }
          await _savePendingProfile(profileData);
        }
      }

      return authResponse;
    } on AuthException catch (e) {
      throw Exception('Gagal mendaftar: ${e.message}');
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

      final Map<String, dynamic> profileData = Map<String, dynamic>.from(
        jsonDecode(pending),
      );
      profileData['id'] = currentUser.id;

      final existing = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
      if (existing == null) {
        await _supabase.from('users').insert(profileData);

        final role = (profileData['role']?.toString() ?? '').toLowerCase();
        final pendingCode = profileData['pharmacist_code']?.toString();
        if (role == 'apoteker' &&
            pendingCode != null &&
            pendingCode.isNotEmpty) {
          for (final col in [
            'code',
            'token',
            'invite_code',
            'admin_token',
            'kode',
            'kode_token',
            'registration_code',
          ]) {
            try {
              final updated = await _supabase
                  .from('pharmacist_invitations')
                  .update({'is_used': true})
                  .eq(col, pendingCode)
                  .eq('is_used', false)
                  .select();
              if (updated.isNotEmpty) {
                break;
              }
            } catch (_) {}
          }
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

