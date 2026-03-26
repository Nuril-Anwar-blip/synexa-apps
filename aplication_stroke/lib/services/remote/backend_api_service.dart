import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BackendApiService — Layanan untuk berkomunikasi dengan backend Express.js
///
/// Cara pakai:
///   final data = await BackendApiService.instance.getMedications(userId);
class BackendApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final BackendApiService instance = BackendApiService._internal();
  BackendApiService._internal();

  // ── URL backend dari .env ─────────────────────────────────────────────────
  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';

  // ── Helper untuk mendapatkan token JWT ────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ── Helper untuk headers ──────────────────────────────────────────────────
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Helper untuk handle response ──────────────────────────────────────────
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== AUTH ====================

  /// Login menggunakan backend
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _handleResponse(response);

    // Simpan token JWT
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
    }

    return data;
  }

  /// Register menggunakan backend
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? role,
    String? pharmacistCode,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': gender,
        'role': role ?? 'pasien',
        'pharmacist_code': pharmacistCode,
      }),
    );
    final data = _handleResponse(response);

    // Simpan token JWT
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
    }

    return data;
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // ==================== MEDICATION ====================

  /// Ambil semua reminder obat user
  Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/medication/user/$userId'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Tambah reminder obat
  Future<Map<String, dynamic>> addMedication({
    required String name,
    String? dose,
    String? note,
    required String time,
    required String period,
    String? frequency,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/medication'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'dose': dose,
        'note': note,
        'time': time,
        'period': period,
        'frequency': frequency,
      }),
    );
    return _handleResponse(response);
  }

  /// Tandai obat sudah diminum
  Future<Map<String, dynamic>> markMedicationTaken(String id) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/medication/$id/take'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // ==================== HEALTH LOGS ====================

  /// Ambil semua log kesehatan user
  Future<List<Map<String, dynamic>>> getHealthLogs(
    String userId, {
    String? type,
  }) async {
    final headers = await _getHeaders();
    final url = type != null
        ? '$_baseUrl/health/user/$userId?type=$type'
        : '$_baseUrl/health/user/$userId';
    final response = await http.get(Uri.parse(url), headers: headers);
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Tambah log kesehatan
  Future<Map<String, dynamic>> addHealthLog({
    required String logType,
    int? systolic,
    int? diastolic,
    double? value,
    String? note,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/health'),
      headers: headers,
      body: jsonEncode({
        'log_type': logType,
        'value_systolic': systolic,
        'value_diastolic': diastolic,
        'value_numeric': value,
        'note': note,
      }),
    );
    return _handleResponse(response);
  }

  // ==================== REHAB ====================

  /// Ambil semua fase rehab
  Future<List<Map<String, dynamic>>> getRehabPhases() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/rehab/phases'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Ambil latihan berdasarkan fase
  Future<List<Map<String, dynamic>>> getExercisesByPhase(int phaseId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/rehab/phases/$phaseId/exercises'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Ambil progres rehab user
  Future<Map<String, dynamic>?> getRehabProgress(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/rehab/progress/$userId'),
      headers: headers,
    );
    final data = _handleResponse(response);
    return data is Map<String, dynamic> ? data : null;
  }

  /// Catat selesai latihan
  Future<Map<String, dynamic>> logExercise({
    required String exerciseId,
    int durationSeconds = 0,
    bool isAborted = false,
    String? abortReason,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/rehab/exercises/log'),
      headers: headers,
      body: jsonEncode({
        'exercise_id': exerciseId,
        'duration_actual_seconds': durationSeconds,
        'is_aborted': isAborted,
        'abort_reason': abortReason,
      }),
    );
    return _handleResponse(response);
  }

  /// Ambil log latihan user
  Future<List<Map<String, dynamic>>> getExerciseLogs(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/rehab/exercises/log/$userId'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Update progres rehab user
  Future<Map<String, dynamic>> updateRehabProgress({
    required String userId,
    int? currentPhaseId,
    int? streakCount,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (currentPhaseId != null) body['current_phase_id'] = currentPhaseId;
    if (streakCount != null) body['streak_count'] = streakCount;

    final response = await http.patch(
      Uri.parse('$_baseUrl/rehab/progress/$userId'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ==================== COMMUNITY / POSTS ====================

  /// Ambil semua post
  Future<List<Map<String, dynamic>>> getPosts() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/community/posts'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Tambah post baru
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/community/posts'),
      headers: headers,
      body: jsonEncode({
        'content': content,
        'media_url': mediaUrl,
        'media_type': mediaType,
      }),
    );
    return _handleResponse(response);
  }

  /// Like post
  Future<Map<String, dynamic>> likePost(String postId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/community/posts/$postId/like'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Tambah komentar
  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String content,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/community/posts/$postId/comments'),
      headers: headers,
      body: jsonEncode({'content': content}),
    );
    return _handleResponse(response);
  }

  // ==================== CHAT ====================

  /// Ambil chat room user
  Future<List<Map<String, dynamic>>> getChatRooms(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/rooms/$userId'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Ambil pesan di room
  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/messages/$roomId'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Buat chat room baru
  Future<Map<String, dynamic>> createChatRoom(String pharmacistId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/rooms'),
      headers: headers,
      body: jsonEncode({'pharmacist_id': pharmacistId}),
    );
    return _handleResponse(response);
  }

  /// Kirim pesan
  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/messages'),
      headers: headers,
      body: jsonEncode({'room_id': roomId, 'content': content}),
    );
    return _handleResponse(response);
  }

  // ==================== NOTIFICATIONS ====================

  /// Ambil notifikasi user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/user/$userId'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Tandai notifikasi sudah dibaca
  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // ==================== USERS ====================

  /// Ambil data user
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Update profil user
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    int? age,
    double? height,
    double? weight,
    String? gender,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (age != null) body['age'] = age;
    if (height != null) body['height'] = height;
    if (weight != null) body['weight'] = weight;
    if (gender != null) body['gender'] = gender;

    final response = await http.patch(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ==================== EDUCATION ====================

  /// Ambil semua konten edukasi
  Future<List<Map<String, dynamic>>> getEducation() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/education'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  /// Ambil edukasi berdasarkan kategori
  Future<List<Map<String, dynamic>>> getEducationByCategory(
    String category,
  ) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/education?category=$category'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  // ==================== EMERGENCY ====================

  /// Trigger emergency SOS
  Future<Map<String, dynamic>> triggerEmergency({
    required double lat,
    required double lng,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/emergency'),
      headers: headers,
      body: jsonEncode({'location_lat': lat, 'location_long': lng}),
    );
    return _handleResponse(response);
  }

  /// Ambil log emergency user
  Future<List<Map<String, dynamic>>> getEmergencyLogs(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/emergency/user/$userId'),
      headers: headers,
    );
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }

  // ==================== SENSOR DATA ====================

  /// Kirim data sensor dari smartwatch
  Future<Map<String, dynamic>> sendSensorData({
    required String type,
    Map<String, dynamic>? value,
    int? heartRate,
    double? latitude,
    double? longitude,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/sensor'),
      headers: headers,
      body: jsonEncode({
        'type': type,
        'value': value,
        'heart_rate': heartRate,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return _handleResponse(response);
  }

  /// Ambil data sensor user
  Future<List<Map<String, dynamic>>> getSensorData(
    String userId, {
    String? type,
  }) async {
    final headers = await _getHeaders();
    final url = type != null
        ? '$_baseUrl/sensor/user/$userId?type=$type'
        : '$_baseUrl/sensor/user/$userId';
    final response = await http.get(Uri.parse(url), headers: headers);
    return List<Map<String, dynamic>>.from(_handleResponse(response));
  }
}
