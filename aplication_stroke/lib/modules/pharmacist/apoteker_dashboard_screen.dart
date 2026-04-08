// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../auth/login_screen.dart';
// import 'package:aplication_stroke/modules/consultation/consultation_screen.dart';

// class PharmacistConversation {
//   PharmacistConversation({
//     required this.roomId,
//     required this.patientId,
//     required this.patientName,
//     required this.patientAvatar,
//     this.lastMessage,
//     this.lastMessageAt,
//   });

//   final String roomId;
//   final String patientId;
//   final String patientName;
//   final String patientAvatar;
//   final String? lastMessage;
//   final DateTime? lastMessageAt;

//   factory PharmacistConversation.fromRpc(Map<String, dynamic> map) {
//     return PharmacistConversation(
//       roomId: map['room_id']?.toString() ?? '',
//       patientId: map['patient_id']?.toString() ?? '',
//       patientName: map['patient_full_name']?.toString() ?? 'Pasien',
//       patientAvatar: map['patient_photo_url']?.toString() ?? '',
//       lastMessage: map['last_message_content']?.toString(),
//       lastMessageAt: map['last_message_created_at'] != null
//           ? DateTime.parse(map['last_message_created_at'])
//           : null,
//     );
//   }
// }

// class ApotekerDashboardScreen extends StatefulWidget {
//   const ApotekerDashboardScreen({super.key});

//   @override
//   State<ApotekerDashboardScreen> createState() =>
//       _ApotekerDashboardScreenState();
// }

// class _ApotekerDashboardScreenState extends State<ApotekerDashboardScreen> {
//   final _supabase = Supabase.instance.client;
//   final TextEditingController _searchController = TextEditingController();
//   final List<PharmacistConversation> _rooms = [];

//   bool _isLoading = true;
//   bool _isRefreshing = false;
//   String? _errorMessage;
//   RealtimeChannel? _realtimeChannel;
//   Timer? _debounce;
//   String? _userId;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _supabase.auth.currentUser?.id;
//     _searchController.addListener(() => setState(() {}));
//     _loadRooms();
//     _setupRealtime();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _debounce?.cancel();
//     if (_realtimeChannel != null) {
//       _supabase.removeChannel(_realtimeChannel!);
//     }
//     super.dispose();
//   }

//   Future<void> _loadRooms({bool showSpinner = true}) async {
//     if (_userId == null) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'Sesi berakhir. Silakan login kembali.';
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
//       final conversations = await _fetchConversations();
//       if (!mounted) return;
//       setState(() {
//         _rooms
//           ..clear()
//           ..addAll(conversations);
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage = 'Gagal memuat percakapan. Tarik untuk menyegarkan.';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Tidak bisa memuat percakapan: $e')),
//       );
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _isRefreshing = false;
//       });
//     }
//   }

//   Future<List<PharmacistConversation>> _fetchConversations() async {
//     if (_userId == null) return [];

//     final List<dynamic> rooms = await _supabase
//         .from('chat_rooms')
//         .select(
//           'id, patient_id, created_at, patient:patient_id (id, full_name, photo_url)',
//         )
//         .eq('pharmacist_id', _userId!)
//         .order('created_at', ascending: false);

//     final roomIds = rooms
//         .map((room) => room['id']?.toString())
//         .whereType<String>()
//         .toList();
//     final patientIds = rooms
//         .map((room) => room['patient_id']?.toString())
//         .whereType<String>()
//         .toSet()
//         .toList();

//     final latestMessages = await _fetchLatestMessages(roomIds);
//     final fallbackProfiles = await _fetchPatientProfiles(patientIds);

//     final conversations = rooms.map((raw) {
//       final row = Map<String, dynamic>.from(raw as Map);
//       final roomId = row['id']?.toString() ?? '';
//       final patientId = row['patient_id']?.toString() ?? '';
//       final patient = Map<String, dynamic>.from(
//         (row['patient'] as Map?) ??
//             (fallbackProfiles[patientId] ?? <String, dynamic>{}),
//       );
//       final latestMessage = latestMessages[roomId];
//       return PharmacistConversation(
//         roomId: roomId,
//         patientId: patientId,
//         patientName: patient['full_name']?.toString() ?? 'Pasien',
//         patientAvatar: patient['photo_url']?.toString() ?? '',
//         lastMessage: latestMessage?['content']?.toString(),
//         lastMessageAt: latestMessage?['created_at'] != null
//             ? DateTime.parse(latestMessage!['created_at'] as String)
//             : null,
//       );
//     }).toList();

//     conversations.sort((a, b) {
//       final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
//       final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
//       return bTime.compareTo(aTime);
//     });

//     return conversations;
//   }

//   Future<Map<String, Map<String, dynamic>>> _fetchLatestMessages(
//     List<String> roomIds,
//   ) async {
//     if (roomIds.isEmpty) return {};
//     // Ambil pesan terbaru untuk setiap room menggunakan filter 'in' pada room_id
//     final List<dynamic> rows = await _supabase
//         .from('messages')
//         .select('room_id, content, created_at')
//         .inFilter('room_id', roomIds)
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

//   Future<Map<String, Map<String, dynamic>>> _fetchPatientProfiles(
//     List<String> patientIds,
//   ) async {
//     if (patientIds.isEmpty) return {};
//     final List<dynamic> patients = await _supabase
//         .from('users')
//         .select('id, full_name, photo_url')
//         .inFilter('id', patientIds)
//         .order('full_name');
//     final map = <String, Map<String, dynamic>>{};
//     for (final raw in patients) {
//       final m = Map<String, dynamic>.from(raw as Map);
//       final id = m['id']?.toString();
//       if (id != null) map[id] = m;
//     }
//     return map;
//   }

//   void _setupRealtime() {
//     if (_userId == null) return;
//     _realtimeChannel =
//         _supabase.channel('pharmacist_chat_dashboard_${_userId!}')
//           ..onPostgresChanges(
//             event: PostgresChangeEvent.all,
//             schema: 'public',
//             table: 'chat_rooms',
//             filter: PostgresChangeFilter(
//               type: PostgresChangeFilterType.eq,
//               column: 'pharmacist_id',
//               value: _userId!,
//             ),
//             callback: (_) => _scheduleRefresh(),
//           )
//           ..onPostgresChanges(
//             event: PostgresChangeEvent.all,
//             schema: 'public',
//             table: 'messages',
//             callback: (_) => _scheduleRefresh(),
//           )
//           ..subscribe();
//   }

//   void _scheduleRefresh() {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 350), () {
//       if (mounted) _loadRooms(showSpinner: false);
//     });
//   }

//   List<PharmacistConversation> get _filteredRooms {
//     final query = _searchController.text.toLowerCase().trim();
//     if (query.isEmpty) return _rooms;
//     return _rooms
//         .where((room) => room.patientName.toLowerCase().contains(query))
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

//   Future<void> _openConversation(PharmacistConversation convo) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ConsultationScreen(
//           roomId: convo.roomId,
//           recipientId: convo.patientId,
//           recipientName: convo.patientName,
//         ),
//       ),
//     );
//     if (mounted) _loadRooms(showSpinner: false);
//   }

//   Future<void> _logout() async {
//     await _supabase.auth.signOut();
//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (_) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         title: const Text(
//           'Dashboard Apoteker',
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Logout',
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
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
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: () => _loadRooms(showSpinner: false),
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
//                 children: [
//                   _PharmacistHeroCard(totalRooms: _rooms.length),
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
//                     const _PharmacistEmptyState()
//                   else
//                     ..._filteredRooms.map(
//                       (room) => Padding(
//                         padding: const EdgeInsets.only(bottom: 12),
//                         child: _ConversationTile(
//                           conversation: room,
//                           timeLabel: _formatTimestamp(room.lastMessageAt),
//                           onTap: () => _openConversation(room),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class _PharmacistHeroCard extends StatelessWidget {
//   const _PharmacistHeroCard({required this.totalRooms});

//   final int totalRooms;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: LinearGradient(
//           colors: [Colors.orange.shade500, Colors.deepOrange.shade300],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.deepOrange.shade100,
//             blurRadius: 24,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Pasien membutuhkan Anda',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             totalRooms == 0
//                 ? 'Belum ada sesi aktif.\nTunggu pasien memulai percakapan.'
//                 : '$totalRooms percakapan aktif perlu dipantau.',
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
//         hintText: 'Cari nama pasien',
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

// class _ConversationTile extends StatelessWidget {
//   const _ConversationTile({
//     required this.conversation,
//     required this.timeLabel,
//     required this.onTap,
//   });

//   final PharmacistConversation conversation;
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
//           backgroundImage: conversation.patientAvatar.isNotEmpty
//               ? NetworkImage(conversation.patientAvatar)
//               : null,
//           child: conversation.patientAvatar.isEmpty
//               ? const Icon(Icons.person_outline)
//               : null,
//         ),
//         title: Text(
//           conversation.patientName,
//           style: const TextStyle(fontWeight: FontWeight.w700),
//         ),
//         subtitle: Text(
//           conversation.lastMessage ?? 'Belum ada pesan',
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
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

// class _PharmacistEmptyState extends StatelessWidget {
//   const _PharmacistEmptyState();

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
//           Icon(
//             Icons.chat_outlined,
//             size: 48,
//             color: Colors.deepOrange.shade300,
//           ),
//           const SizedBox(height: 12),
//           const Text(
//             'Belum ada percakapan',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Pasien akan muncul secara otomatis ketika mereka memulai konsultasi.',
//             textAlign: TextAlign.center,
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

// ====================================================================
// File: apoteker_dashboard_screen_v2.dart
// Apoteker Dashboard — Full theme/lang/font support
// Letakkan di: lib/modules/pharmacist/apoteker_dashboard_screen.dart
// ====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Uncomment saat integrasi:
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../auth/login_screen.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'package:aplication_stroke/modules/consultation/consultation_screen.dart';

// ── Mock data ──────────────────────────────────────────────────────────────
class _MockConversation {
  final String id;
  final String patientName;
  final String patientInitial;
  final String lastMessage;
  final DateTime lastTime;
  final bool hasUnread;
  final int unreadCount;

  const _MockConversation({
    required this.id,
    required this.patientName,
    required this.patientInitial,
    required this.lastMessage,
    required this.lastTime,
    this.hasUnread = false,
    this.unreadCount = 0,
  });
}

final _mockConversations = [
  _MockConversation(
    id: '1',
    patientName: 'Budi Santoso',
    patientInitial: 'B',
    lastMessage:
        'Dok, apakah obat Aspirin bisa diminum bersamaan dengan Amlodipine?',
    lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
    hasUnread: true,
    unreadCount: 3,
  ),
  _MockConversation(
    id: '2',
    patientName: 'Sri Rahayu',
    patientInitial: 'S',
    lastMessage: 'Terima kasih atas penjelasannya, apoteker!',
    lastTime: DateTime.now().subtract(const Duration(hours: 2)),
    hasUnread: false,
  ),
  _MockConversation(
    id: '3',
    patientName: 'Hendra Wijaya',
    patientInitial: 'H',
    lastMessage: 'Stok obat saya tinggal 3, perlu beli lagi?',
    lastTime: DateTime.now().subtract(const Duration(hours: 5)),
    hasUnread: true,
    unreadCount: 1,
  ),
  _MockConversation(
    id: '4',
    patientName: 'Dewi Kusuma',
    patientInitial: 'D',
    lastMessage: 'Baik, saya akan minum obat setelah makan',
    lastTime: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// ── Main Screen ────────────────────────────────────────────────────────────
class ApotekerDashboardScreen extends StatefulWidget {
  const ApotekerDashboardScreen({super.key});

  @override
  State<ApotekerDashboardScreen> createState() =>
      _ApotekerDashboardScreenState();
}

class _ApotekerDashboardScreenState extends State<ApotekerDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  List<_MockConversation> _conversations = List.from(_mockConversations);
  late AnimationController _listAnim;
  late Animation<double> _listFade;
  bool _isLoading = false;
  int _selectedFilter = 0; // 0=Semua, 1=Belum dibaca

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listFade = CurvedAnimation(parent: _listAnim, curve: Curves.easeOut);
    _searchCtrl.addListener(() => setState(() {}));
    _listAnim.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  double get _fs => 1.0;
  String _t(Map<String, String> m) => m['id'] ?? '';

  List<_MockConversation> get _filtered {
    var list = _conversations;
    if (_selectedFilter == 1) list = list.where((c) => c.hasUnread).toList();
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return list;
    return list.where((c) => c.patientName.toLowerCase().contains(q)).toList();
  }

  int get _unreadTotal => _conversations
      .where((c) => c.hasUnread)
      .fold(0, (s, c) => s + c.unreadCount);

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
    if (diff.inHours < 24) return '${diff.inHours} jam';
    return '${diff.inDays} hari';
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    _listAnim.forward(from: 0);
  }

  void _openChat(_MockConversation conv) {
    // Di app nyata: navigate ke ConsultationScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka chat dengan ${conv.patientName}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    // Mark as read
    setState(() {
      final idx = _conversations.indexWhere((c) => c.id == conv.id);
      if (idx != -1) {
        _conversations[idx] = _MockConversation(
          id: conv.id,
          patientName: conv.patientName,
          patientInitial: conv.patientInitial,
          lastMessage: conv.lastMessage,
          lastTime: conv.lastTime,
          hasUnread: false,
        );
      }
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t({
            'id': 'Konfirmasi Logout',
            'en': 'Confirm Logout',
            'my': 'Konfirmasi Logout',
          }),
        ),
        content: Text(
          _t({
            'id': 'Yakin ingin keluar?',
            'en': 'Are you sure to sign out?',
            'my': 'Pasti anda mahu keluar?',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _t({'id': 'Batal', 'en': 'Cancel', 'my': 'Dibatalkan'}),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(_t({'id': 'Logout', 'en': 'Logout', 'my': 'Keluar'})),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF060B1A) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.orange,
              child: _isLoading
                  ? _buildSkeleton()
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _listAnim,
                            curve: Interval(
                              i * 0.1,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _listAnim,
                                  curve: Interval(
                                    i * 0.1,
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ConversationCard(
                              conv: _filtered[i],
                              isDark: _isDark,
                              fs: _fs,
                              formatTime: _formatTime,
                              onTap: () => _openChat(_filtered[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF3E1F00), const Color(0xFF060B1A)]
              : [Colors.orange.shade600, Colors.deepOrange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                          _t({
                            'id': 'Dashboard Apoteker',
                            'en': 'Pharmacist Dashboard',
                            'my': 'Papan Pemuka Ahli Farmasi',
                          }),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22 * _fs,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          _t({
                            'id': 'Selamat datang, Apoteker',
                            'en': 'Welcome, Pharmacist',
                            'my': 'Selamat datang, Ahli Farmasi',
                          }),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13 * _fs,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh & logout
                  GestureDetector(
                    onTap: _refresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.chat_bubble_rounded,
                      value: '${_conversations.length}',
                      label: _t({
                        'id': 'Sesi Aktif',
                        'en': 'Active Sessions',
                        'my': 'Sesi Aktif',
                      }),
                      fs: _fs,
                    ),
                    _VertDiv(),
                    _StatChip(
                      icon: Icons.mark_chat_unread_rounded,
                      value: '$_unreadTotal',
                      label: _t({
                        'id': 'Belum Dibaca',
                        'en': 'Unread',
                        'my': 'Belum baca lagi',
                      }),
                      fs: _fs,
                    ),
                    _VertDiv(),
                    _StatChip(
                      icon: Icons.people_rounded,
                      value: '${_conversations.length}',
                      label: _t({
                        'id': 'Pasien',
                        'en': 'Patients',
                        'my': 'Sabar',
                      }),
                      fs: _fs,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _t({
                      'id': 'Cari nama pasien...',
                      'en': 'Search patient...',
                      'my': 'Cari nama pesakit...',
                    }),
                    hintStyle: TextStyle(
                      color: Colors.white54,
                      fontSize: 14 * _fs,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      _t({'id': 'Semua', 'en': 'All', 'my': 'Semua'}),
      _t({'id': 'Belum Dibaca', 'en': 'Unread', 'my': 'Belum dibaca'}),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: filters.asMap().entries.map((e) {
          final sel = _selectedFilter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = e.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? Colors.orange
                      : (_isDark ? Colors.white12 : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? Colors.orange
                        : (_isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13 * _fs,
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? Colors.white
                            : (_isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ),
                    if (e.key == 1 && _unreadTotal > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white.withOpacity(0.3)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadTotal',
                          style: TextStyle(
                            fontSize: 10 * _fs,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 80,
        decoration: BoxDecoration(
          color: _isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.deepOrange.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 48,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _t({
              'id': 'Belum ada percakapan',
              'en': 'No conversations yet',
              'my': 'Tiada perbualan lagi',
            }),
            style: TextStyle(
              fontSize: 18 * _fs,
              fontWeight: FontWeight.w800,
              color: _isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t({
              'id': 'Pasien akan muncul saat memulai konsultasi',
              'en': 'Patients will appear when they start a consultation',
              'my': 'Kesabaran akan muncul apabila memulakan perundingan',
            }),
            style: TextStyle(fontSize: 13 * _fs, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.fs,
  });
  final IconData icon;
  final String value, label;
  final double fs;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * fs,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white60, fontSize: 10 * fs),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: Colors.white.withOpacity(0.2),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );
}

// ── Conversation Card ──────────────────────────────────────────────────────
class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conv,
    required this.isDark,
    required this.fs,
    required this.formatTime,
    required this.onTap,
  });
  final _MockConversation conv;
  final bool isDark;
  final double fs;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;

  static const _gradients = [
    [Color(0xFFE53935), Color(0xFFFF7043)],
    [Color(0xFF7B1FA2), Color(0xFF5C6BC0)],
    [Color(0xFF2E7D32), Color(0xFF00897B)],
    [Color(0xFF1565C0), Color(0xFF0288D1)],
    [Color(0xFFFF6F00), Color(0xFFFFB300)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradIdx = conv.patientInitial.codeUnitAt(0) % _gradients.length;
    final grad = _gradients[gradIdx];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: conv.hasUnread
              ? Border.all(color: Colors.orange.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
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
                  child: Center(
                    child: Text(
                      conv.patientInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                // Online dot
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.patientName,
                          style: TextStyle(
                            fontSize: 15 * fs,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        formatTime(conv.lastTime),
                        style: TextStyle(
                          fontSize: 11 * fs,
                          color: conv.hasUnread
                              ? Colors.orange
                              : Colors.grey.shade400,
                          fontWeight: conv.hasUnread
                              ? FontWeight.w700
                              : FontWeight.normal,
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
                          'Pasien',
                          style: TextStyle(
                            fontSize: 9 * fs,
                            color: Colors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.lastMessage,
                    style: TextStyle(
                      fontSize: 12 * fs,
                      color: conv.hasUnread
                          ? (isDark ? Colors.white70 : Colors.black54)
                          : Colors.grey.shade500,
                      fontWeight: conv.hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread badge
            if (conv.hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${conv.unreadCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11 * fs,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ] else
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
