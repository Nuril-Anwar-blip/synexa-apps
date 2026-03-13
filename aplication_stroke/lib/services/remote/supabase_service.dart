import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseService - Service untuk mengambil data dari Supabase
///
/// Cara pakai:
///   final data = await SupabaseService.getEducation();
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ==================== USER ====================

  /// Ambil data profil user saat ini
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  /// Update profil user
  static Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    int? age,
    double? height,
    double? weight,
    String? gender,
  }) async {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['full_name'] = fullName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (age != null) data['age'] = age;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (gender != null) data['gender'] = gender;

    await _client.from('users').update(data).eq('id', userId);
  }

  // ==================== EDUCATION ====================

  /// Ambil semua konten edukasi
  static Future<List<Map<String, dynamic>>> getEducation() async {
    final response = await _client
        .from('education_contents')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ambil edukasi berdasarkan kategori
  static Future<List<Map<String, dynamic>>> getEducationByCategory(
    String category,
  ) async {
    final response = await _client
        .from('education_contents')
        .select()
        .eq('category', category)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== MEDICATION ====================

  /// Ambil semua reminder obat user
  static Future<List<Map<String, dynamic>>> getMedications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('medication_reminders')
        .select()
        .eq('user_id', user.id)
        .order('time', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Tambah reminder obat
  static Future<void> addMedication({
    required String name,
    String? dose,
    String? note,
    required String time,
    required String period,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('medication_reminders').insert({
      'user_id': user.id,
      'name': name,
      'dose': dose,
      'note': note,
      'time': time,
      'period': period,
    });
  }

  /// Update status obat diminum
  static Future<void> updateMedicationStatus(String id, bool taken) async {
    await _client
        .from('medication_reminders')
        .update({
          'taken': taken,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Hapus reminder obat
  static Future<void> deleteMedication(String id) async {
    await _client.from('medication_reminders').delete().eq('id', id);
  }

  // ==================== HEALTH LOGS ====================

  /// Ambil semua log kesehatan user
  static Future<List<Map<String, dynamic>>> getHealthLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('health_logs')
        .select()
        .eq('user_id', user.id)
        .order('recorded_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Tambah log kesehatan
  static Future<void> addHealthLog({
    required String logType,
    int? systolic,
    int? diastolic,
    double? value,
    String? note,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('health_logs').insert({
      'user_id': user.id,
      'log_type': logType,
      'value_systolic': systolic,
      'value_diastolic': diastolic,
      'value_numeric': value,
      'note': note,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== REHAB ====================

  /// Ambil semua fase rehab
  static Future<List<Map<String, dynamic>>> getRehabPhases() async {
    final response = await _client
        .from('rehab_phases')
        .select()
        .order('order_index', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ambil semua latihan rehab
  static Future<List<Map<String, dynamic>>> getRehabExercises() async {
    final response = await _client
        .from('rehab_exercises')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ambil latihan berdasarkan fase
  static Future<List<Map<String, dynamic>>> getExercisesByPhase(
    int phaseId,
  ) async {
    final response = await _client
        .from('rehab_exercises')
        .select()
        .eq('phase_id', phaseId)
        .order('time_category', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ambil progres rehab user
  static Future<Map<String, dynamic>?> getRehabProgress() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('rehab_user_progress')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    return response;
  }

  /// Update progres rehab user
  static Future<void> updateRehabProgress({
    int? currentPhaseId,
    int? streakCount,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final Map<String, dynamic> data = {};
    if (currentPhaseId != null) data['current_phase_id'] = currentPhaseId;
    if (streakCount != null) data['streak_count'] = streakCount;

    await _client
        .from('rehab_user_progress')
        .update(data)
        .eq('user_id', user.id);
  }

  /// Catat selesai latihan
  static Future<void> logExercise({
    required String exerciseId,
    int durationSeconds = 0,
    bool isAborted = false,
    String? abortReason,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('rehab_exercise_logs').insert({
      'user_id': user.id,
      'exercise_id': exerciseId,
      'duration_actual_seconds': durationSeconds,
      'is_aborted': isAborted,
      'abort_reason': abortReason,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  /// Ambil log latihan user
  static Future<List<Map<String, dynamic>>> getExerciseLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('rehab_exercise_logs')
        .select()
        .eq('user_id', user.id)
        .order('completed_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== COMMUNITY / POSTS ====================

  /// Ambil semua post
  static Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await _client
        .from('posts')
        .select('*, users(full_name, photo_url)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Tambah post baru
  static Future<void> createPost({
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('posts').insert({
      'user_id': user.id,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
    });
  }

  /// Like/unlike post
  static Future<void> toggleLike(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Cek sudah like belum
    final existing = await _client
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _client.from('likes').delete().eq('id', existing['id']);

      // Update like count manually
      final post = await _client
          .from('posts')
          .select('like_count')
          .eq('id', postId)
          .maybeSingle();
      if (post != null) {
        await _client
            .from('posts')
            .update({'like_count': (post['like_count'] ?? 1) - 1})
            .eq('id', postId);
      }
    } else {
      // Like
      await _client.from('likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });

      // Update like count manually
      final post = await _client
          .from('posts')
          .select('like_count')
          .eq('id', postId)
          .maybeSingle();
      if (post != null) {
        await _client
            .from('posts')
            .update({'like_count': (post['like_count'] ?? 0) + 1})
            .eq('id', postId);
      }
    }
  }

  /// Ambil komentar post
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await _client
        .from('comments')
        .select('*, users(full_name, photo_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Tambah komentar
  static Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
    });
  }

  // ==================== EMERGENCY ====================

  /// Ambil log emergency user
  static Future<List<Map<String, dynamic>>> getEmergencyLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('emergency_logs')
        .select()
        .eq('user_id', user.id)
        .order('triggered_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Trigger emergency SOS
  static Future<void> triggerEmergency({
    required double lat,
    required double lng,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('emergency_logs').insert({
      'user_id': user.id,
      'location_lat': lat,
      'location_long': lng,
      'status': 'active',
    });
  }

  // ==================== SETTINGS ====================

  /// Ambil pengaturan user
  static Future<Map<String, dynamic>?> getUserSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    return response;
  }

  /// Update pengaturan user
  static Future<void> updateUserSettings({
    String? themeMode,
    String? languageCode,
    bool? enableNotifications,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final Map<String, dynamic> data = {};
    if (themeMode != null) data['theme_mode'] = themeMode;
    if (languageCode != null) data['language_code'] = languageCode;
    if (enableNotifications != null)
      data['enable_notifications'] = enableNotifications;
    data['updated_at'] = DateTime.now().toIso8601String();

    await _client.from('user_settings').update(data).eq('user_id', user.id);
  }

  // ==================== NOTIFICATIONS ====================

  /// Ambil notifikasi user
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Tandai notifikasi sudah dibaca
  static Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // ==================== CHAT ====================

  /// Ambil chat room user
  static Future<List<Map<String, dynamic>>> getChatRooms() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('chat_rooms')
        .select(
          '*, users!chat_rooms_patient_id_fkey(full_name, photo_url), pharmacist:users!chat_rooms_pharmacist_id_fkey(full_name, photo_url)',
        )
        .or('patient_id.eq.${user.id},pharmacist_id.eq.${user.id}')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ambil pesan di room
  static Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    final response = await _client
        .from('messages')
        .select('*, users(full_name, photo_url)')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Kirim pesan
  static Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_id': user.id,
      'content': content,
    });
  }
}
