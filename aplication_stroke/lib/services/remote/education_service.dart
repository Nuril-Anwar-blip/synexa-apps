import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/education_model.dart';

class EducationService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
}
