import 'package:aplication_stroke/modules/consultation/consultation_screen.dart';
import 'package:aplication_stroke/utils/app_route_transitions.dart';
import 'package:aplication_stroke/utils/user_profile_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatHelper {
  static Future<void> openChatWithPharmacist({
    required BuildContext context,
    required String pharmacistId,
    required String pharmacistName,
  }) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    try {
      final patientId = await UserProfileHelper.patientProfileId();
      if (patientId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil pasien tidak ditemukan')),
          );
        }
        return;
      }

      final existing = await supabase
          .from('chat_rooms')
          .select('id')
          .eq('patient_id', patientId)
          .eq('pharmacist_id', pharmacistId)
          .maybeSingle();

      String roomId;
      if (existing != null) {
        roomId = existing['id'].toString();
      } else {
        // Buat room baru
        final newRoom = await supabase
            .from('chat_rooms')
            .insert({
              'patient_id': patientId,
              'pharmacist_id': pharmacistId,
            })
            .select('id')
            .single();
        roomId = newRoom['id'].toString();
      }

      // Navigate ke chat room
      if (context.mounted) {
        Navigator.push(
          context,
          AppRouteTransitions.fadeSlide(
            ConsultationScreen(
              roomId: roomId,
              recipientId: pharmacistId,
              recipientName: pharmacistName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka chat: $e')));
      }
    }
  }
}
