// /// ====================================================================
// /// File: patient_chat_dashboard_screen.dart
// /// --------------------------------------------------------------------
// /// Layar Chat Konsultasi Pasien dengan Apoteker
// ///
// /// Dokumen ini berisi halaman chat untuk berkonsultasi dengan apoteker
// /// atau dokter secara realtime.
// ///
// /// Fitur:
// /// - Daftar percakapan dengan profesional kesehatan
// /// - Chat real-time menggunakan Supabase Realtime
// /// - Indicator online/offline
// /// - Notifikasi pesan baru
// /// - Kirim gambar (jika diperlukan)
// ///
// /// Author: Tim Developer Synexa
// /// ====================================================================

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../widgets/quick_settings_sheet.dart';
// import 'consultation_screen.dart';

// class ChatRoomInfo {
//   const ChatRoomInfo({
//     required this.roomId,
//     required this.pharmacistId,
//     required this.pharmacistName,
//     required this.pharmacistAvatarUrl,
//     this.lastMessage,
//     this.lastMessageTimestamp,
//   });

//   factory ChatRoomInfo.fromMap(Map<String, dynamic> map) {
//     return ChatRoomInfo(
//       roomId: map['id']?.toString() ?? '',
//       pharmacistId: map['pharmacist_id']?.toString() ?? '',
//       pharmacistName: map['pharmacist_name'] ?? 'Apoteker',
//       pharmacistAvatarUrl: map['pharmacist_photo_url'] ?? '',
//       lastMessage: map['last_message_content'],
//       lastMessageTimestamp: map['last_message_created_at'] != null
//           ? DateTime.parse(map['last_message_created_at'])
//           : null,
//     );
//   }

//   final String roomId;
//   final String pharmacistId;
//   final String pharmacistName;
//   final String pharmacistAvatarUrl;
//   final String? lastMessage;
//   final DateTime? lastMessageTimestamp;
// }

// /// Halaman Dasbor Chat Pasien
// ///
// /// Halaman ini menampilkan daftar chat pasien dengan dokter.
// /// Pengguna dapat melihat riwayat chat dan mengirim pesan baru.
// class PatientChatDashboardScreen extends StatefulWidget {
//   const PatientChatDashboardScreen({super.key});

//   @override
//   State<PatientChatDashboardScreen> createState() =>
//       _PatientChatDashboardScreenState();
// }

// class _PatientChatDashboardScreenState
//     extends State<PatientChatDashboardScreen> {
//   final _supabase = Supabase.instance.client;
//   final _searchController = TextEditingController();
//   final List<ChatRoomInfo> _rooms = [];

//   bool _isLoading = true;
//   bool _isRefreshing = false;
//   String? _errorMessage;
//   RealtimeChannel? _realtimeChannel;
//   Timer? _refreshDebounce;
//   bool _isStartingChat = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadRooms();
//     _setupRealtime();
//     _searchController.addListener(() => setState(() {}));
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _refreshDebounce?.cancel();
//     if (_realtimeChannel != null) {
//       _supabase.removeChannel(_realtimeChannel!);
//     }
//     super.dispose();
//   }

//   Future<void> _loadRooms({bool showSpinner = true}) async {
//     final currentUser = _supabase.auth.currentUser;
//     if (currentUser == null) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'Sesi Anda sudah berakhir. Silakan login ulang.';
//       });
//       return;
//     }
//     if (showSpinner) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });
//     } else {
//       setState(() => _isRefreshing = true);
//     }

//     try {
//       final mapped = await _fetchPatientRooms(currentUser.id);
//       if (!mounted) return;
//       setState(() {
//         _rooms
//           ..clear()
//           ..addAll(mapped);
//         _errorMessage = null;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage =
//             'Gagal memuat percakapan. Tarik ke bawah untuk refresh.';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Tidak bisa memuat daftar chat: $e')),
//       );
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _isRefreshing = false;
//       });
//     }
//   }

//   Future<List<ChatRoomInfo>> _fetchPatientRooms(String userId) async {
//     try {
//       final List<dynamic> rows = await _supabase
//           .from('chat_rooms')
//           .select('id, pharmacist_id, created_at')
//           .eq('patient_id', userId)
//           .order('created_at', ascending: false);

//       final roomIds = rows
//           .map((e) => e['id']?.toString())
//           .whereType<String>()
//           .toList();
//       final pharmacistIds = rows
//           .map((e) => e['pharmacist_id']?.toString())
//           .whereType<String>()
//           .toSet()
//           .toList();

//       final pharmacistProfiles = <String, Map<String, dynamic>>{};
//       if (pharmacistIds.isNotEmpty) {
//         final List<dynamic> workers = await _supabase
//             .from('users')
//             .select('id, full_name, photo_url')
//             .filter('id', 'in', pharmacistIds);
//         for (final raw in workers) {
//           final map = Map<String, dynamic>.from(raw as Map);
//           final id = map['id']?.toString();
//           if (id != null) pharmacistProfiles[id] = map;
//         }
//       }

//       final latestMessages = await _fetchLatestMessages(roomIds);

//       final mapped = rows.map((raw) {
//         final row = Map<String, dynamic>.from(raw as Map);
//         final roomId = row['id']?.toString() ?? '';
//         final pharmacistId = row['pharmacist_id']?.toString() ?? '';
//         final pharmacist = pharmacistProfiles[pharmacistId] ?? {};
//         final latestMessage = latestMessages[roomId];
//         return ChatRoomInfo(
//           roomId: roomId,
//           pharmacistId: pharmacistId,
//           pharmacistName: pharmacist['full_name']?.toString() ?? 'Apoteker',
//           pharmacistAvatarUrl: pharmacist['photo_url']?.toString() ?? '',
//           lastMessage: latestMessage?['content']?.toString(),
//           lastMessageTimestamp: latestMessage?['created_at'] != null
//               ? DateTime.parse(latestMessage!['created_at'] as String)
//               : null,
//         );
//       }).toList();

//       mapped.sort((a, b) {
//         final aTime =
//             a.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
//         final bTime =
//             b.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
//         return bTime.compareTo(aTime);
//       });
//       return mapped;
//     } on PostgrestException catch (e) {
//       throw Exception('Tidak bisa memuat daftar chat: ${e.message}');
//     }
//   }

//   Future<Map<String, Map<String, dynamic>>> _fetchLatestMessages(
//     List<String> roomIds,
//   ) async {
//     if (roomIds.isEmpty) return {};
//     final List<dynamic> rows = await _supabase
//         .from('messages')
//         .select('room_id, content, created_at')
//         .filter('room_id', 'in', roomIds)
//         .order('created_at', ascending: false);

//     final latest = <String, Map<String, dynamic>>{};
//     for (final raw in rows) {
//       final map = Map<String, dynamic>.from(raw as Map);
//       final roomId = map['room_id']?.toString();
//       if (roomId == null || latest.containsKey(roomId)) continue;
//       latest[roomId] = map;
//     }
//     return latest;
//   }

//   void _setupRealtime() {
//     _realtimeChannel = _supabase.channel('patient_chat_dashboard_channel')
//       ..onPostgresChanges(
//         event: PostgresChangeEvent.all,
//         schema: 'public',
//         table: 'chat_rooms',
//         callback: (_) => _scheduleRefresh(),
//       )
//       ..onPostgresChanges(
//         event: PostgresChangeEvent.all,
//         schema: 'public',
//         table: 'messages',
//         callback: (_) => _scheduleRefresh(),
//       )
//       ..subscribe();
//   }

//   void _scheduleRefresh() {
//     _refreshDebounce?.cancel();
//     _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
//       if (mounted) _loadRooms(showSpinner: false);
//     });
//   }

//   List<ChatRoomInfo> get _filteredRooms {
//     final query = _searchController.text.toLowerCase().trim();
//     if (query.isEmpty) return _rooms;
//     return _rooms
//         .where((room) => room.pharmacistName.toLowerCase().contains(query))
//         .toList();
//   }

//   String _formatTimestamp(DateTime? time) {
//     if (time == null) return '';
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final messageDate = DateTime(time.year, time.month, time.day);

//     if (today == messageDate) {
//       return DateFormat.Hm().format(time.toLocal());
//     }
//     return DateFormat('dd MMM', 'id_ID').format(time.toLocal());
//   }

//   Future<void> _openRoom(ChatRoomInfo room) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ConsultationScreen(
//           roomId: room.roomId,
//           recipientId: room.pharmacistId,
//           recipientName: room.pharmacistName,
//         ),
//       ),
//     );
//     if (mounted) _loadRooms(showSpinner: false);
//   }

//   Future<List<_PharmacistSummary>> _fetchPharmacists() async {
//     final roles = ['apoteker', 'Apoteker', 'pharmacist', 'Pharmacist'];
//     final rows = await _supabase
//         .from('users')
//         .select('id, full_name, photo_url')
//         .filter('role', 'in', roles)
//         .order('full_name');
//     return rows
//         .map<_PharmacistSummary>(
//           (row) => _PharmacistSummary(
//             id: row['id']?.toString() ?? '',
//             name: row['full_name']?.toString() ?? 'Apoteker',
//             avatarUrl: row['photo_url']?.toString() ?? '',
//           ),
//         )
//         .where((summary) => summary.id.isNotEmpty)
//         .toList();
//   }

//   Future<void> _showPharmacistPicker() async {
//     if (_isStartingChat) return;
//     setState(() => _isStartingChat = true);
//     try {
//       final pharmacists = await _fetchPharmacists();
//       if (!mounted) return;
//       if (pharmacists.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Belum ada apoteker yang tersedia.')),
//         );
//         return;
//       }
//       final selected = await showModalBottomSheet<_PharmacistSummary>(
//         context: context,
//         isScrollControlled: true,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//         ),
//         builder: (_) => _PharmacistPickerSheet(pharmacists: pharmacists),
//       );
//       if (selected != null) {
//         await _startChatWithPharmacist(selected);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Gagal memuat daftar apoteker: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _isStartingChat = false);
//     }
//   }

//   Future<void> _startChatWithPharmacist(_PharmacistSummary pharmacist) async {
//     try {
//       final currentUser = _supabase.auth.currentUser;
//       if (currentUser == null) {
//         throw Exception('Sesi berakhir, silakan login ulang.');
//       }

//       final existing = await _supabase
//           .from('chat_rooms')
//           .select('id')
//           .eq('patient_id', currentUser.id)
//           .eq('pharmacist_id', pharmacist.id)
//           .maybeSingle();

//       final roomId = existing != null
//           ? (existing['id']?.toString() ?? '')
//           : ((await _supabase
//                     .from('chat_rooms')
//                     .insert({
//                       'patient_id': currentUser.id,
//                       'pharmacist_id': pharmacist.id,
//                     })
//                     .select('id')
//                     .single())['id'])
//                 .toString();

//       if (!mounted) return;
//       await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ConsultationScreen(
//             roomId: roomId,
//             recipientId: pharmacist.id,
//             recipientName: pharmacist.name,
//           ),
//         ),
//       );
//       if (mounted) _loadRooms(showSpinner: false);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Gagal memulai konsultasi: $e')));
//     }
//   }

//   // Logout dihapus sesuai permintaan

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Konsultasi'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.tune_rounded),
//             tooltip: 'Quick Settings',
//             onPressed: () => QuickSettingsSheet.show(context),
//           ),
//           if (_isRefreshing)
//             const Padding(
//               padding: EdgeInsets.only(right: 12),
//               child: SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//           IconButton(
//             tooltip: 'Segarkan',
//             onPressed: _isRefreshing
//                 ? null
//                 : () => _loadRooms(showSpinner: false),
//             icon: const Icon(Icons.refresh_rounded),
//           ),
//         ],
//       ),
//       floatingActionButton: Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).padding.bottom + 74,
//         ),
//         child: FloatingActionButton.extended(
//           onPressed: _isStartingChat ? null : _showPharmacistPicker,
//           backgroundColor: Colors.teal.shade600,
//           icon: Icon(
//             _isStartingChat ? Icons.hourglass_top : Icons.add_comment_rounded,
//           ),
//           label: Text(_isStartingChat ? 'Menghubungkan...' : 'Cari Apoteker'),
//         ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: () => _loadRooms(showSpinner: false),
//               child: ListView(
//                 padding: EdgeInsets.fromLTRB(
//                   16,
//                   16,
//                   16,
//                   MediaQuery.of(context).padding.bottom + 80,
//                 ),
//                 children: [
//                   _PatientHeroCard(totalRooms: _rooms.length),
//                   const SizedBox(height: 16),
//                   _SearchField(controller: _searchController),
//                   if (_errorMessage != null) ...[
//                     const SizedBox(height: 12),
//                     _ErrorBanner(
//                       message: _errorMessage!,
//                       onRetry: () => _loadRooms(),
//                     ),
//                   ],
//                   const SizedBox(height: 16),
//                   if (_filteredRooms.isEmpty)
//                     _EmptyState(onCreateTap: _showPharmacistPicker)
//                   else
//                     ..._filteredRooms.map(
//                       (room) => Padding(
//                         padding: const EdgeInsets.only(bottom: 12),
//                         child: _ChatRoomCard(
//                           info: room,
//                           subtitle: room.lastMessage ?? 'Belum ada pesan',
//                           timeLabel: _formatTimestamp(
//                             room.lastMessageTimestamp,
//                           ),
//                           onTap: () => _openRoom(room),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class _PatientHeroCard extends StatelessWidget {
//   const _PatientHeroCard({required this.totalRooms});
//   final int totalRooms;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: LinearGradient(
//           colors: [Colors.teal.shade500, Colors.teal.shade300],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.teal.shade100,
//             blurRadius: 24,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Terhubung dengan Apoteker',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             totalRooms == 0
//                 ? 'Belum ada sesi. Mulai konsultasi sekarang.'
//                 : '$totalRooms sesi aktif siap membantu Anda.',
//             style: const TextStyle(color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SearchField extends StatelessWidget {
//   const _SearchField({required this.controller});
//   final TextEditingController controller;

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         hintText: 'Cari nama apoteker',
//         prefixIcon: const Icon(Icons.search),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(24),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
// }

// class _ChatRoomCard extends StatelessWidget {
//   const _ChatRoomCard({
//     required this.info,
//     required this.subtitle,
//     required this.timeLabel,
//     required this.onTap,
//   });

//   final ChatRoomInfo info;
//   final String subtitle;
//   final String timeLabel;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//       child: ListTile(
//         onTap: onTap,
//         leading: CircleAvatar(
//           radius: 28,
//           backgroundImage: info.pharmacistAvatarUrl.isNotEmpty
//               ? NetworkImage(info.pharmacistAvatarUrl)
//               : null,
//           child: info.pharmacistAvatarUrl.isEmpty
//               ? const Icon(Icons.person_outline)
//               : null,
//         ),
//         title: Text(
//           info.pharmacistName,
//           style: const TextStyle(fontWeight: FontWeight.w700),
//         ),
//         subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
//         trailing: Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               timeLabel,
//               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//             ),
//             const SizedBox(height: 4),
//             const Icon(Icons.chevron_right_rounded),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   const _EmptyState({required this.onCreateTap});
//   final VoidCallback onCreateTap;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         children: [
//           Icon(Icons.chat_outlined, size: 48, color: Colors.teal.shade400),
//           const SizedBox(height: 12),
//           const Text(
//             'Belum ada percakapan',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Mulai konsultasi pertama Anda dan dapatkan jawaban langsung dari apoteker.',
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: onCreateTap,
//             child: const Text('Mulai Konsultasi'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ErrorBanner extends StatelessWidget {
//   const _ErrorBanner({required this.message, required this.onRetry});

//   final String message;
//   final VoidCallback onRetry;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.red.shade50,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(message, style: const TextStyle(color: Colors.red)),
//           ),
//           TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
//         ],
//       ),
//     );
//   }
// }

// class _PharmacistSummary {
//   const _PharmacistSummary({
//     required this.id,
//     required this.name,
//     required this.avatarUrl,
//   });

//   final String id;
//   final String name;
//   final String avatarUrl;
// }

// class _PharmacistPickerSheet extends StatefulWidget {
//   const _PharmacistPickerSheet({required this.pharmacists});

//   final List<_PharmacistSummary> pharmacists;

//   @override
//   State<_PharmacistPickerSheet> createState() => _PharmacistPickerSheetState();
// }

// class _PharmacistPickerSheetState extends State<_PharmacistPickerSheet> {
//   String _query = '';

//   @override
//   Widget build(BuildContext context) {
//     final filtered = widget.pharmacists
//         .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
//         .toList();

//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
//         child: SizedBox(
//           height: MediaQuery.of(context).size.height * 0.7,
//           child: Column(
//             children: [
//               Container(
//                 width: 40,
//                 height: 4,
//                 margin: const EdgeInsets.only(bottom: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(100),
//                 ),
//               ),
//               const Text(
//                 'Pilih Apoteker',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 decoration: const InputDecoration(
//                   prefixIcon: Icon(Icons.search),
//                   hintText: 'Cari nama apoteker',
//                 ),
//                 onChanged: (value) => setState(() => _query = value),
//               ),
//               const SizedBox(height: 16),
//               if (filtered.isEmpty)
//                 const Expanded(
//                   child: Center(
//                     child: Text(
//                       'Tidak ada apoteker dengan nama tersebut.',
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                   ),
//                 )
//               else
//                 Expanded(
//                   child: ListView.separated(
//                     shrinkWrap: true,
//                     itemBuilder: (context, index) {
//                       final pharmacist = filtered[index];
//                       return ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: pharmacist.avatarUrl.isNotEmpty
//                               ? NetworkImage(pharmacist.avatarUrl)
//                               : null,
//                           child: pharmacist.avatarUrl.isEmpty
//                               ? const Icon(Icons.person_outline)
//                               : null,
//                         ),
//                         title: Text(pharmacist.name),
//                         subtitle: const Text('Siap membantu'),
//                         trailing: const Icon(
//                           Icons.arrow_forward_ios_rounded,
//                           size: 14,
//                         ),
//                         onTap: () => Navigator.pop(context, pharmacist),
//                       );
//                     },
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemCount: filtered.length,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ====================================================================
// File: patient_chat_dashboard_screen.dart — Full Redesign v3
// ✅ ThemeProvider + LanguageProvider di semua widget
// ✅ Premium card design dengan avatar gradient
// ✅ Online indicator, unread badge, last message preview
// ====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../widgets/quick_settings_sheet.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import 'consultation_screen.dart';

class ChatRoomInfo {
  const ChatRoomInfo({
    required this.roomId,
    required this.pharmacistId,
    required this.pharmacistName,
    required this.pharmacistAvatarUrl,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory ChatRoomInfo.fromMap(Map<String, dynamic> map) => ChatRoomInfo(
    roomId: map['id']?.toString() ?? '',
    pharmacistId: map['pharmacist_id']?.toString() ?? '',
    pharmacistName: map['pharmacist_name'] ?? 'Apoteker',
    pharmacistAvatarUrl: map['pharmacist_photo_url'] ?? '',
    lastMessage: map['last_message_content'],
    lastMessageTimestamp: map['last_message_created_at'] != null
        ? DateTime.parse(map['last_message_created_at'])
        : null,
  );

  final String roomId, pharmacistId, pharmacistName, pharmacistAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
}

class PatientChatDashboardScreen extends StatefulWidget {
  const PatientChatDashboardScreen({super.key});
  @override
  State<PatientChatDashboardScreen> createState() =>
      _PatientChatDashboardScreenState();
}

class _PatientChatDashboardScreenState extends State<PatientChatDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final List<ChatRoomInfo> _rooms = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshDebounce;
  bool _isStartingChat = false;

  late AnimationController _listAnim;
  late Animation<double> _listFade;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _listFade = CurvedAnimation(parent: _listAnim, curve: Curves.easeOut);
    _loadRooms();
    _setupRealtime();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _searchController.dispose();
    _refreshDebounce?.cancel();
    if (_realtimeChannel != null) _supabase.removeChannel(_realtimeChannel!);
    super.dispose();
  }

  Future<void> _loadRooms({bool showSpinner = true}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi berakhir.';
      });
      return;
    }
    if (showSpinner)
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    else
      setState(() => _isRefreshing = true);
    try {
      final mapped = await _fetchPatientRooms(currentUser.id);
      if (!mounted) return;
      setState(() {
        _rooms
          ..clear()
          ..addAll(mapped);
        _errorMessage = null;
      });
      _listAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat percakapan.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<List<ChatRoomInfo>> _fetchPatientRooms(String userId) async {
    try {
      final List<dynamic> rows = await _supabase
          .from('chat_rooms')
          .select('id, pharmacist_id, created_at')
          .eq('patient_id', userId)
          .order('created_at', ascending: false);
      final roomIds = rows
          .map((e) => e['id']?.toString())
          .whereType<String>()
          .toList();
      final pharmacistIds = rows
          .map((e) => e['pharmacist_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final pharmacistProfiles = <String, Map<String, dynamic>>{};
      if (pharmacistIds.isNotEmpty) {
        final List<dynamic> workers = await _supabase
            .from('users')
            .select('id, full_name, photo_url')
            .filter('id', 'in', pharmacistIds);
        for (final raw in workers) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = m['id']?.toString();
          if (id != null) pharmacistProfiles[id] = m;
        }
      }
      final latestMessages = await _fetchLatestMessages(roomIds);
      final mapped = rows.map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final roomId = row['id']?.toString() ?? '';
        final pharmacistId = row['pharmacist_id']?.toString() ?? '';
        final pharmacist = pharmacistProfiles[pharmacistId] ?? {};
        final latestMessage = latestMessages[roomId];
        return ChatRoomInfo(
          roomId: roomId,
          pharmacistId: pharmacistId,
          pharmacistName: pharmacist['full_name']?.toString() ?? 'Apoteker',
          pharmacistAvatarUrl: pharmacist['photo_url']?.toString() ?? '',
          lastMessage: latestMessage?['content']?.toString(),
          lastMessageTimestamp: latestMessage?['created_at'] != null
              ? DateTime.parse(latestMessage!['created_at'] as String)
              : null,
        );
      }).toList();
      mapped.sort((a, b) {
        final aTime =
            a.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.lastMessageTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return mapped;
    } on PostgrestException catch (e) {
      throw Exception('Tidak bisa memuat daftar chat: ${e.message}');
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchLatestMessages(
    List<String> roomIds,
  ) async {
    if (roomIds.isEmpty) return {};
    final List<dynamic> rows = await _supabase
        .from('messages')
        .select('room_id, content, created_at')
        .filter('room_id', 'in', roomIds)
        .order('created_at', ascending: false);
    final latest = <String, Map<String, dynamic>>{};
    for (final raw in rows) {
      final m = Map<String, dynamic>.from(raw as Map);
      final roomId = m['room_id']?.toString();
      if (roomId == null || latest.containsKey(roomId)) continue;
      latest[roomId] = m;
    }
    return latest;
  }

  void _setupRealtime() {
    _realtimeChannel = _supabase.channel('patient_chat_dashboard_channel')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_rooms',
        callback: (_) => _scheduleRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (_) => _scheduleRefresh(),
      )
      ..subscribe();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadRooms(showSpinner: false);
    });
  }

  List<ChatRoomInfo> get _filteredRooms {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _rooms;
    return _rooms
        .where((room) => room.pharmacistName.toLowerCase().contains(query))
        .toList();
  }

  String _formatTimestamp(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    if (today == messageDate) return DateFormat.Hm().format(time.toLocal());
    return DateFormat('dd MMM', 'id_ID').format(time.toLocal());
  }

  Future<void> _openRoom(ChatRoomInfo room) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(
          roomId: room.roomId,
          recipientId: room.pharmacistId,
          recipientName: room.pharmacistName,
        ),
      ),
    );
    if (mounted) _loadRooms(showSpinner: false);
  }

  Future<List<_PharmacistSummary>> _fetchPharmacists() async {
    final roles = ['apoteker', 'Apoteker', 'pharmacist', 'Pharmacist'];
    final rows = await _supabase
        .from('users')
        .select('id, full_name, photo_url')
        .filter('role', 'in', roles)
        .order('full_name');
    return rows
        .map<_PharmacistSummary>(
          (row) => _PharmacistSummary(
            id: row['id']?.toString() ?? '',
            name: row['full_name']?.toString() ?? 'Apoteker',
            avatarUrl: row['photo_url']?.toString() ?? '',
          ),
        )
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  Future<void> _showPharmacistPicker() async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    HapticFeedback.mediumImpact();
    try {
      final pharmacists = await _fetchPharmacists();
      if (!mounted) return;
      if (pharmacists.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Belum ada apoteker.')));
        return;
      }
      final selected = await showModalBottomSheet<_PharmacistSummary>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PharmacistPickerSheet(pharmacists: pharmacists),
      );
      if (selected != null) await _startChatWithPharmacist(selected);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  Future<void> _startChatWithPharmacist(_PharmacistSummary pharmacist) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Sesi berakhir.');
      final existing = await _supabase
          .from('chat_rooms')
          .select('id')
          .eq('patient_id', currentUser.id)
          .eq('pharmacist_id', pharmacist.id)
          .maybeSingle();
      final roomId = existing != null
          ? (existing['id']?.toString() ?? '')
          : ((await _supabase
                    .from('chat_rooms')
                    .insert({
                      'patient_id': currentUser.id,
                      'pharmacist_id': pharmacist.id,
                    })
                    .select('id')
                    .single())['id'])
                .toString();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationScreen(
            roomId: roomId,
            recipientId: pharmacist.id,
            recipientName: pharmacist.name,
          ),
        ),
      );
      if (mounted) _loadRooms(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeP.isDarkMode;
    final fs = themeP.fontSize;
    String t(Map<String, String> m) => lang.translate(m);

    final bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _ChatHeader(
            isDark: isDark,
            fs: fs,
            t: t,
            totalRooms: _rooms.length,
            isRefreshing: _isRefreshing,
            onSettings: () => QuickSettingsSheet.show(context),
            onRefresh: () => _loadRooms(showSpinner: false),
          ),

          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchBar(
              controller: _searchController,
              isDark: isDark,
              fs: fs,
              hint: t({
                'id': 'Cari nama apoteker...',
                'en': 'Search pharmacist...',
                'ms': 'Cari nama ahli farmasi...',
              }),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _LoadingShimmer(isDark: isDark)
                : RefreshIndicator(
                    onRefresh: () => _loadRooms(showSpinner: false),
                    color: Colors.teal,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        MediaQuery.of(context).padding.bottom + 80,
                      ),
                      children: [
                        if (_errorMessage != null)
                          _ErrorBanner(
                            message: _errorMessage!,
                            onRetry: _loadRooms,
                            isDark: isDark,
                            fs: fs,
                          ),
                        if (_filteredRooms.isEmpty)
                          _EmptyState(
                            isDark: isDark,
                            fs: fs,
                            t: t,
                            onTap: _showPharmacistPicker,
                          )
                        else
                          ..._filteredRooms.asMap().entries.map(
                            (e) => FadeTransition(
                              opacity: Tween<double>(begin: 0, end: 1).animate(
                                CurvedAnimation(
                                  parent: _listAnim,
                                  curve: Interval(
                                    e.key * 0.1,
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 0.15),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _listAnim,
                                        curve: Interval(
                                          e.key * 0.1,
                                          1.0,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                    ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ChatRoomCard(
                                    info: e.value,
                                    timeLabel: _formatTimestamp(
                                      e.value.lastMessageTimestamp,
                                    ),
                                    onTap: () => _openRoom(e.value),
                                    isDark: isDark,
                                    fs: fs,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 74,
        ),
        child: _StartChatFAB(
          isLoading: _isStartingChat,
          fs: fs,
          t: t,
          onTap: _showPharmacistPicker,
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.isDark,
    required this.fs,
    required this.t,
    required this.totalRooms,
    required this.isRefreshing,
    required this.onSettings,
    required this.onRefresh,
  });
  final bool isDark, isRefreshing;
  final double fs;
  final String Function(Map<String, String>) t;
  final int totalRooms;
  final VoidCallback onSettings, onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D3B35), const Color(0xFF0A0F1E)]
              : [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t({
                            'id': 'Konsultasi',
                            'en': 'Consultation',
                            'ms': 'Perundingan',
                          }),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24 * fs,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          t({
                            'id': 'Chat dengan apoteker Anda',
                            'en': 'Chat with your pharmacist',
                            'ms': 'Chat dengan ahli farmasi anda',
                          }),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13 * fs,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (isRefreshing)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white.withOpacity(0.7),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      _HeaderBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
                      const SizedBox(width: 8),
                      _HeaderBtn(icon: Icons.tune_rounded, onTap: onSettings),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    _StatItem(
                      icon: Icons.chat_bubble_rounded,
                      value: '$totalRooms',
                      label: t({
                        'id': 'Sesi Aktif',
                        'en': 'Active Sessions',
                        'ms': 'Sesi Aktif',
                      }),
                      fs: fs,
                    ),
                    _Divider(),
                    _StatItem(
                      icon: Icons.local_pharmacy_rounded,
                      value: '24/7',
                      label: t({
                        'id': 'Siap Membantu',
                        'en': 'Ready to Help',
                        'ms': 'Sedia Membantu',
                      }),
                      fs: fs,
                    ),
                    _Divider(),
                    _StatItem(
                      icon: Icons.timer_rounded,
                      value: '<1j',
                      label: t({
                        'id': 'Respons Cepat',
                        'en': 'Fast Response',
                        'ms': 'Respons Pantas',
                      }),
                      fs: fs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.fs,
  });
  final IconData icon;
  final String value, label;
  final double fs;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * fs,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10 * fs,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: Colors.white.withOpacity(0.2),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

// ── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.fs,
    required this.hint,
  });
  final TextEditingController controller;
  final bool isDark;
  final double fs;
  final String hint;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF131D2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 14 * fs,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14 * fs),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.teal.shade400),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                color: Colors.grey.shade400,
                onPressed: () => controller.clear(),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

// ── Chat Room Card ────────────────────────────────────────────────────────────
class _ChatRoomCard extends StatelessWidget {
  const _ChatRoomCard({
    required this.info,
    required this.timeLabel,
    required this.onTap,
    required this.isDark,
    required this.fs,
  });
  final ChatRoomInfo info;
  final String timeLabel;
  final VoidCallback onTap;
  final bool isDark;
  final double fs;

  // Gradient colors based on name initial
  static const _gradients = [
    [Color(0xFF00897B), Color(0xFF00ACC1)],
    [Color(0xFF7B1FA2), Color(0xFF5C6BC0)],
    [Color(0xFFE53935), Color(0xFFFF7043)],
    [Color(0xFF2E7D32), Color(0xFF00897B)],
    [Color(0xFF1565C0), Color(0xFF0288D1)],
  ];

  @override
  Widget build(BuildContext context) {
    final initial = info.pharmacistName.isNotEmpty
        ? info.pharmacistName[0].toUpperCase()
        : '?';
    final gradIdx = info.pharmacistName.isNotEmpty
        ? info.pharmacistName.codeUnitAt(0) % _gradients.length
        : 0;
    final grad = _gradients[gradIdx];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with gradient
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(grad[0].value), Color(grad[1].value)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: info.pharmacistAvatarUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            info.pharmacistAvatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                // Online indicator
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF131D2E) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          info.pharmacistName,
                          style: TextStyle(
                            fontSize: 15 * fs,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 11 * fs,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Apoteker',
                          style: TextStyle(
                            fontSize: 9 * fs,
                            color: Colors.teal.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          info.lastMessage ?? 'Mulai percakapan...',
                          style: TextStyle(
                            fontSize: 12 * fs,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(grad[0].value).withOpacity(0.15),
                    Color(grad[1].value).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Color(grad[0].value),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Start Chat FAB ────────────────────────────────────────────────────────────
class _StartChatFAB extends StatelessWidget {
  const _StartChatFAB({
    required this.isLoading,
    required this.fs,
    required this.t,
    required this.onTap,
  });
  final bool isLoading;
  final double fs;
  final String Function(Map<String, String>) t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.add_comment_rounded,
                  color: Colors.white,
                  size: 20,
                ),
          const SizedBox(width: 8),
          Text(
            isLoading
                ? t({
                    'id': 'Menghubungkan...',
                    'en': 'Connecting...',
                    'ms': 'Menyambungkan...',
                  })
                : t({
                    'id': 'Cari Apoteker',
                    'en': 'Find Pharmacist',
                    'ms': 'Cari Ahli Farmasi',
                  }),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * fs,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Loading Shimmer ───────────────────────────────────────────────────────────
class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer({required this.isDark});
  final bool isDark;
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 76,
        decoration: BoxDecoration(
          color: (widget.isDark ? Colors.white : Colors.black).withOpacity(
            _anim.value * 0.1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  );
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isDark,
    required this.fs,
    required this.t,
    required this.onTap,
  });
  final bool isDark;
  final double fs;
  final String Function(Map<String, String>) t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 40),
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF131D2E) : Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2F1), Color(0xFFB2EBF2)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Colors.teal.shade600,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t({
            'id': 'Belum ada percakapan',
            'en': 'No conversations yet',
            'ms': 'Tiada perbualan lagi',
          }),
          style: TextStyle(
            fontSize: 18 * fs,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t({
            'id':
                'Mulai konsultasi dengan apoteker untuk mendapatkan saran medis yang tepat.',
            'en':
                'Start a consultation with a pharmacist for proper medical advice.',
            'ms': 'Mulakan perundingan dengan ahli farmasi.',
          }),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13 * fs,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_comment_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  t({
                    'id': 'Mulai Konsultasi',
                    'en': 'Start Consultation',
                    'ms': 'Mula Perundingan',
                  }),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * fs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.isDark,
    required this.fs,
  });
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  final double fs;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red.shade100),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13 * fs),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

// ── Pharmacist Picker Sheet ──────────────────────────────────────────────────
class _PharmacistSummary {
  const _PharmacistSummary({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
  final String id, name, avatarUrl;
}

class _PharmacistPickerSheet extends StatefulWidget {
  const _PharmacistPickerSheet({required this.pharmacists});
  final List<_PharmacistSummary> pharmacists;
  @override
  State<_PharmacistPickerSheet> createState() => _PharmacistPickerSheetState();
}

class _PharmacistPickerSheetState extends State<_PharmacistPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeP = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final fs = themeP.fontSize;
    String t(Map<String, String> m) => lang.translate(m);

    final filtered = widget.pharmacists
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final bg = isDark ? const Color(0xFF131D2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00897B), Color(0xFF00ACC1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t({
                                  'id': 'Pilih Apoteker',
                                  'en': 'Choose Pharmacist',
                                  'ms': 'Pilih Ahli Farmasi',
                                }),
                                style: TextStyle(
                                  fontSize: 18 * fs,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                t({
                                  'id':
                                      '${widget.pharmacists.length} apoteker tersedia',
                                  'en':
                                      '${widget.pharmacists.length} pharmacists available',
                                  'ms':
                                      '${widget.pharmacists.length} ahli farmasi tersedia',
                                }),
                                style: TextStyle(
                                  fontSize: 12 * fs,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SearchBar(
                      controller: TextEditingController(text: _query)
                        ..addListener(() {}),
                      isDark: isDark,
                      fs: fs,
                      hint: t({
                        'id': 'Cari apoteker...',
                        'en': 'Search pharmacist...',
                        'ms': 'Cari ahli farmasi...',
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          t({
                            'id': 'Tidak ada apoteker ditemukan.',
                            'en': 'No pharmacist found.',
                            'ms': 'Tiada ahli farmasi ditemui.',
                          }),
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final grad =
                              _ChatRoomCard._gradients[p.name.isNotEmpty
                                  ? p.name.codeUnitAt(0) %
                                        _ChatRoomCard._gradients.length
                                  : 0];
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, p),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A2636)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(grad[0].value),
                                          Color(grad[1].value),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: p.avatarUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              p.avatarUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              p.name.isNotEmpty
                                                  ? p.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: TextStyle(
                                            fontSize: 14 * fs,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          t({
                                            'id': 'Siap membantu Anda',
                                            'en': 'Ready to help you',
                                            'ms': 'Sedia membantu anda',
                                          }),
                                          style: TextStyle(
                                            fontSize: 12 * fs,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      t({
                                        'id': 'Chat',
                                        'en': 'Chat',
                                        'ms': 'Chat',
                                      }),
                                      style: TextStyle(
                                        fontSize: 12 * fs,
                                        color: Colors.teal.shade600,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
