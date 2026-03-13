import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/education_model.dart';

class EducationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── One-shot Fetches ──────────────────────────────────────────────────────

  /// Mengambil semua konten edukasi.
  Future<List<EducationContent>> getAllEducation() async {
    final response = await _supabase
        .from('education_contents')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((e) => EducationContent.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Mengambil konten edukasi berdasarkan kategori.
  Future<List<EducationContent>> getEducationByCategory(String category) async {
    final response = await _supabase
        .from('education_contents')
        .select()
        .eq('category', category)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((e) => EducationContent.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Realtime Streams ──────────────────────────────────────────────────────

  /// Stream semua konten edukasi — UI otomatis update saat admin menambah artikel.
  ///
  /// Contoh pemakaian:
  /// ```dart
  /// StreamBuilder<List<Map<String, dynamic>>>(
  ///   stream: EducationService().streamEducation(),
  ///   builder: (context, snapshot) {
  ///     if (!snapshot.hasData) return CircularProgressIndicator();
  ///     return ListView.builder(
  ///       itemCount: snapshot.data!.length,
  ///       itemBuilder: (ctx, i) => Text(snapshot.data![i]['title']),
  ///     );
  ///   },
  /// );
  /// ```
  Stream<List<Map<String, dynamic>>> streamEducation() {
    return _supabase
        .from('education_contents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}

