// // import 'dart:async';

// // import 'package:flutter/material.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import '../../services/local/notification_service.dart';

// // import '../../providers/theme_provider.dart';
// // import 'medication_history_screen.dart';
// // import 'models/medication_reminder.dart';
// // import 'widgets/add_medication_dialog_v2.dart';
// // import '../settings/settings_screen.dart';

// // class MedicationReminderScreen extends StatefulWidget {
// //   const MedicationReminderScreen({super.key});

// //   @override
// //   State<MedicationReminderScreen> createState() =>
// //       _MedicationReminderScreenState();
// // }

// // class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
// //   final SupabaseClient _supabase = Supabase.instance.client;
// //   late final Stream<List<MedicationReminder>> _remindersStream;
// //   final List<String> _periodFilters = const [
// //     'Semua',
// //     'Pagi',
// //     'Siang',
// //     'Sore',
// //     'Malam',
// //   ];
// //   String _selectedPeriod = 'Semua';
// //   int _notificationIdCounter = 0;
// //   String? _userId;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _userId = _supabase.auth.currentUser?.id;
// //     if (_userId == null) {
// //       _remindersStream = Stream.value(const []);
// //     } else {
// //       _remindersStream = _supabase
// //           .from('medication_reminders')
// //           .stream(primaryKey: ['id'])
// //           .eq('user_id', _userId!)
// //           .order('time', ascending: true)
// //           .map(
// //             (rows) =>
// //                 rows.map((row) => MedicationReminder.fromMap(row)).toList(),
// //           );
// //     }
// //   }

// //   Future<void> _addMedication() async {
// //     if (_userId == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Masuk terlebih dahulu untuk menambah pengingat.'),
// //         ),
// //       );
// //       return;
// //     }

// //     final result = await showDialog<Map<String, dynamic>>(
// //       context: context,
// //       builder: (_) => const AddMedicationDialogV2(),
// //     );
// //     if (result == null) return;

// //     final List<TimeOfDay> times = result['times'] as List<TimeOfDay>;
// //     final String name = result['name'] as String;
// //     final String dose = result['dose'] as String? ?? '';
// //     final String note = result['note'] as String? ?? '';

// //     try {
// //       // Insert multiple reminders for each time
// //       for (final time in times) {
// //         final payload = {
// //           'user_id': _userId,
// //           'name': name,
// //           'time': _toDbTime(time),
// //           'taken': false,
// //           'total_stock': result['total_stock'] ?? 0,
// //           'current_stock': result['current_stock'] ?? 0,
// //         };

// //         final inserted = await _supabase
// //             .from('medication_reminders')
// //             .insert(payload)
// //             .select()
// //             .single();

// //         await NotificationService().scheduleMedicationNotification(
// //           inserted['id'].toString(),
// //           inserted['name'] as String,
// //           time,
// //         );
// //       }

// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Pengingat $name disetel untuk ${times.length} waktu'),
// //         ),
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Gagal menambah pengingat: $e')));
// //     }
// //   }

// //   Future<void> _toggleTaken(MedicationReminder reminder) async {
// //     try {
// //       await _supabase
// //           .from('medication_reminders')
// //           .update({'taken': !reminder.taken})
// //           .eq('id', reminder.id);

// //       if (!reminder.taken) {
// //         await NotificationService().cancelMedicationNotifications(reminder.id.toString());
// //       }
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
// //     }
// //   }

// //   void _openHistory() {
// //     if (_userId == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Masuk terlebih dahulu untuk melihat riwayat.'),
// //         ),
// //       );
// //       return;
// //     }
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (_) => MedicationHistoryScreen(userId: _userId!),
// //       ),
// //     );
// //   }

// //   List<MedicationReminder> _filterReminders(
// //     List<MedicationReminder> reminders,
// //   ) {
// //     if (_selectedPeriod == 'Semua') return reminders;
// //     return reminders.where((r) => r.period == _selectedPeriod).toList();
// //   }

// //   MedicationReminder? _upcomingReminder(List<MedicationReminder> reminders) {
// //     if (reminders.isEmpty) return null;
// //     final nowMinutes = _timeToMinutes(TimeOfDay.now());
// //     try {
// //       return reminders.firstWhere(
// //         (r) => !r.taken && _timeToMinutes(r.time) >= nowMinutes,
// //       );
// //     } catch (_) {
// //       final fallback = reminders.where((r) => !r.taken).toList();
// //       return fallback.isNotEmpty ? fallback.first : null;
// //     }
// //   }

// //   int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

// //   String _timeUntil(TimeOfDay time) {
// //     final now = TimeOfDay.now();
// //     var diff = _timeToMinutes(time) - _timeToMinutes(now);
// //     if (diff < 0) diff += 24 * 60;
// //     final hours = diff ~/ 60;
// //     final minutes = diff % 60;
// //     if (hours == 0) return '$minutes mnt lagi';
// //     if (minutes == 0) return '$hours jam lagi';
// //     return '$hours j $minutes m lagi';
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       appBar: AppBar(
// //         elevation: 0,
// //         backgroundColor: Colors.transparent,
// //         foregroundColor: Colors.white,
// //         flexibleSpace: Container(
// //           decoration: BoxDecoration(
// //             gradient: LinearGradient(
// //               colors: [Colors.teal.shade400, Colors.teal.shade200],
// //               begin: Alignment.topLeft,
// //               end: Alignment.bottomRight,
// //             ),
// //           ),
// //         ),
// //         title: const Text('Pengingat Obat'),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.settings_rounded, color: Colors.white),
// //             tooltip: 'Pengaturan',
// //             onPressed: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => const SettingsScreen()),
// //               );
// //             },
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.history_rounded, color: Colors.white),
// //             tooltip: 'Riwayat Pengingat',
// //             onPressed: _openHistory,
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
// //             tooltip: 'Coba bunyi alarm',
// //             onPressed: () => NotificationService().testAlarmNow(),
// //           ),
// //         ],
// //       ),
// //       floatingActionButton: Padding(
// //         padding: EdgeInsets.only(
// //           bottom: MediaQuery.of(context).padding.bottom + 80,
// //         ),
// //         child: FloatingActionButton.extended(
// //           onPressed: _addMedication,
// //           backgroundColor: Colors.teal.shade500,
// //           icon: const Icon(Icons.add),
// //           label: const Text('Tambah Obat'),
// //         ),
// //       ),
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Colors.teal.shade50, Colors.white],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: StreamBuilder<List<MedicationReminder>>(
// //           stream: _remindersStream,
// //           builder: (context, snapshot) {
// //             if (snapshot.connectionState == ConnectionState.waiting) {
// //               return const Center(child: CircularProgressIndicator());
// //             }
// //             final reminders = snapshot.data ?? const [];
// //             final filtered = _filterReminders(reminders);
// //             final upcoming = _upcomingReminder(filtered);
// //             final total = reminders.length;
// //             final completed = reminders.where((r) => r.taken).length;

// //             return ListView(
// //               padding: EdgeInsets.fromLTRB(
// //                 16,
// //                 18,
// //                 16,
// //                 MediaQuery.of(context).padding.bottom + 100,
// //               ),
// //               children: [
// //                 _SummaryCard(completed: completed, total: total),
// //                 const SizedBox(height: 14),
// //                 _PeriodSelector(
// //                   periods: _periodFilters,
// //                   selected: _selectedPeriod,
// //                   onSelected: (value) =>
// //                       setState(() => _selectedPeriod = value),
// //                 ),
// //                 const SizedBox(height: 14),
// //                 if (upcoming != null)
// //                   _UpcomingCard(
// //                     name: upcoming.name,
// //                     dose: upcoming.dose?.isEmpty ?? true
// //                         ? 'Tanpa dosis'
// //                         : upcoming.dose!,
// //                     timeLabel: upcoming.time.format(context),
// //                     countdown: _timeUntil(upcoming.time),
// //                     accent: Colors.orangeAccent,
// //                   )
// //                 else if (total > 0)
// //                   const _UpcomingCard(
// //                     name: 'Semua aman',
// //                     dose: 'Tidak ada jadwal dekat',
// //                     timeLabel: '—',
// //                     countdown: 'Istirahat sejenak',
// //                     accent: Colors.green,
// //                   ),
// //                 const SizedBox(height: 14),
// //                 if (filtered.isEmpty)
// //                   const _EmptyStateCard(
// //                     message:
// //                         'Belum ada pengingat. Tekan Tambah Obat atau buat jadwal baru.',
// //                   )
// //                 else
// //                   ...filtered.map(
// //                     (reminder) => Padding(
// //                       padding: const EdgeInsets.only(bottom: 12),
// //                       child: _MedicationCard(
// //                         reminder: reminder,
// //                         onToggle: () => _toggleTaken(reminder),
// //                       ),
// //                     ),
// //                   ),
// //               ],
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }

// //   String _resolvePeriod(TimeOfDay time) {
// //     if (time.hour >= 5 && time.hour < 11) return 'Pagi';
// //     if (time.hour >= 11 && time.hour < 15) return 'Siang';
// //     if (time.hour >= 15 && time.hour < 19) return 'Sore';
// //     return 'Malam';
// //   }

// //   String _toDbTime(TimeOfDay time) =>
// //       '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
// // }

// // /// ========================
// // /// UI COMPONENTS
// // /// ========================
// // class _SummaryCard extends StatelessWidget {
// //   const _SummaryCard({required this.completed, required this.total});
// //   final int completed;
// //   final int total;

// //   @override
// //   Widget build(BuildContext context) {
// //     final progress = total == 0 ? 0.0 : completed / total;
// //     return Container(
// //       padding: const EdgeInsets.all(20),
// //       decoration: BoxDecoration(
// //         borderRadius: BorderRadius.circular(22),
// //         gradient: LinearGradient(
// //           colors: [Colors.teal.shade500, Colors.teal.shade300],
// //           begin: Alignment.topLeft,
// //           end: Alignment.bottomRight,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.teal.withOpacity(0.18),
// //             blurRadius: 18,
// //             offset: const Offset(0, 10),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Container(
// //                 padding: const EdgeInsets.all(10),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white.withOpacity(0.18),
// //                   borderRadius: BorderRadius.circular(16),
// //                 ),
// //                 child: const Icon(Icons.health_and_safety, color: Colors.white),
// //               ),
// //               const SizedBox(width: 10),
// //               const Text(
// //                 'Progres Hari Ini',
// //                 style: TextStyle(
// //                   color: Colors.white70,
// //                   fontSize: 14,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //               const Spacer(),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(
// //                   horizontal: 10,
// //                   vertical: 6,
// //                 ),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white.withOpacity(0.18),
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Text(
// //                   '${(progress * 100).round()}%',
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Text(
// //             total == 0 ? 'Belum ada jadwal' : '$completed dari $total obat',
// //             style: const TextStyle(
// //               color: Colors.white,
// //               fontSize: 22,
// //               fontWeight: FontWeight.w700,
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(12),
// //             child: LinearProgressIndicator(
// //               value: progress.clamp(0, 1),
// //               minHeight: 10,
// //               backgroundColor: Colors.white24,
// //               valueColor: const AlwaysStoppedAnimation(Colors.white),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _PeriodSelector extends StatelessWidget {
// //   const _PeriodSelector({
// //     required this.periods,
// //     required this.selected,
// //     required this.onSelected,
// //   });
// //   final List<String> periods;
// //   final String selected;
// //   final ValueChanged<String> onSelected;

// //   @override
// //   Widget build(BuildContext context) {
// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Row(
// //         children: periods
// //             .map(
// //               (period) => Padding(
// //                 padding: const EdgeInsets.only(right: 8),
// //                 child: ChoiceChip(
// //                   label: Text(period),
// //                   selected: selected == period,
// //                   onSelected: (_) => onSelected(period),
// //                   selectedColor: Colors.teal.shade100,
// //                   labelStyle: TextStyle(
// //                     color: selected == period
// //                         ? Colors.teal.shade800
// //                         : Colors.black87,
// //                     fontWeight: selected == period
// //                         ? FontWeight.w700
// //                         : FontWeight.w500,
// //                   ),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                     side: BorderSide(
// //                       color: selected == period
// //                           ? Colors.teal.shade300
// //                           : Colors.grey.shade200,
// //                     ),
// //                   ),
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 10,
// //                     vertical: 8,
// //                   ),
// //                 ),
// //               ),
// //             )
// //             .toList(),
// //       ),
// //     );
// //   }
// // }

// // class _UpcomingCard extends StatelessWidget {
// //   const _UpcomingCard({
// //     required this.name,
// //     required this.dose,
// //     required this.timeLabel,
// //     required this.countdown,
// //     required this.accent,
// //   });
// //   final String name, dose, timeLabel, countdown;
// //   final Color accent;

// //   @override
// //   Widget build(BuildContext context) => Container(
// //     padding: const EdgeInsets.all(18),
// //     decoration: BoxDecoration(
// //       color: Colors.white,
// //       borderRadius: BorderRadius.circular(18),
// //       border: Border.all(color: accent.withOpacity(0.25)),
// //       boxShadow: [
// //         BoxShadow(
// //           color: Colors.black.withOpacity(0.05),
// //           blurRadius: 12,
// //           offset: const Offset(0, 6),
// //         ),
// //       ],
// //     ),
// //     child: Row(
// //       children: [
// //         Container(
// //           width: 56,
// //           height: 56,
// //           decoration: BoxDecoration(
// //             color: accent.withOpacity(0.15),
// //             borderRadius: BorderRadius.circular(16),
// //           ),
// //           child: Icon(Icons.alarm, color: accent),
// //         ),
// //         const SizedBox(width: 14),
// //         Expanded(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 name,
// //                 style: const TextStyle(
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.w700,
// //                 ),
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 dose,
// //                 style: TextStyle(
// //                   color: Colors.grey.shade700,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //               const SizedBox(height: 6),
// //               Row(
// //                 children: [
// //                   Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
// //                   const SizedBox(width: 4),
// //                   Text(
// //                     timeLabel,
// //                     style: const TextStyle(fontWeight: FontWeight.w700),
// //                   ),
// //                   const SizedBox(width: 12),
// //                   Container(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 10,
// //                       vertical: 6,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: accent.withOpacity(0.14),
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     child: Text(
// //                       countdown,
// //                       style: TextStyle(
// //                         color: accent,
// //                         fontWeight: FontWeight.w700,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ],
// //     ),
// //   );
// // }

// // class _EmptyStateCard extends StatelessWidget {
// //   const _EmptyStateCard({required this.message});
// //   final String message;
// //   @override
// //   Widget build(BuildContext context) => Center(
// //     child: Padding(
// //       padding: const EdgeInsets.all(28),
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           CircleAvatar(
// //             radius: 40,
// //             backgroundColor: Colors.teal.shade50,
// //             child: Icon(
// //               Icons.medication_outlined,
// //               size: 40,
// //               color: Colors.teal.shade400,
// //             ),
// //           ),
// //           const SizedBox(height: 12),
// //           Text(
// //             message,
// //             textAlign: TextAlign.center,
// //             style: const TextStyle(
// //               fontSize: 15,
// //               color: Colors.black54,
// //               height: 1.4,
// //             ),
// //           ),
// //         ],
// //       ),
// //     ),
// //   );
// // }

// // class _MedicationCard extends StatelessWidget {
// //   const _MedicationCard({required this.reminder, required this.onToggle});
// //   final MedicationReminder reminder;
// //   final VoidCallback onToggle;

// //   @override
// //   Widget build(BuildContext context) {
// //     final accent = reminder.taken ? Colors.green : Colors.blue;
// //     final note = reminder.note?.trim();
// //     return Container(
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(20),
// //         border: Border.all(
// //           color: reminder.taken
// //               ? Colors.green.withOpacity(0.2)
// //               : Colors.grey.shade200,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.04),
// //             blurRadius: 12,
// //             offset: const Offset(0, 6),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               CircleAvatar(
// //                 backgroundColor: accent.withOpacity(0.12),
// //                 foregroundColor: accent,
// //                 child: Icon(
// //                   reminder.taken
// //                       ? Icons.verified
// //                       : Icons.medication_liquid_outlined,
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(
// //                       reminder.name,
// //                       style: const TextStyle(
// //                         fontSize: 16,
// //                         fontWeight: FontWeight.w700,
// //                       ),
// //                     ),
// //                     Text(
// //                       reminder.dose?.isEmpty ?? true
// //                           ? 'Dosis belum diisi'
// //                           : reminder.dose!,
// //                       style: TextStyle(color: Colors.grey.shade700),
// //                     ),
// //                     if (note != null && note.isNotEmpty) ...[
// //                       const SizedBox(height: 4),
// //                       Text(
// //                         note,
// //                         style: TextStyle(
// //                           color: Colors.grey.shade600,
// //                           fontSize: 12,
// //                         ),
// //                       ),
// //                     ],
// //                   ],
// //                 ),
// //               ),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(
// //                   horizontal: 12,
// //                   vertical: 6,
// //                 ),
// //                 decoration: BoxDecoration(
// //                   color: Colors.grey.shade100,
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //                 child: Text(
// //                   reminder.period,
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.w600,
// //                     fontSize: 12,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           Row(
// //             children: [
// //               Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
// //               const SizedBox(width: 6),
// //               Text(
// //                 reminder.time.format(context),
// //                 style: const TextStyle(fontWeight: FontWeight.w700),
// //               ),
// //               const SizedBox(width: 10),
// //               Text(
// //                 reminder.taken ? 'Sudah diminum' : 'Belum diminum',
// //                 style: TextStyle(
// //                   color: reminder.taken ? Colors.green : Colors.orange,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 10),
// //           ElevatedButton.icon(
// //             onPressed: onToggle,
// //             style: ElevatedButton.styleFrom(
// //               backgroundColor: reminder.taken
// //                   ? Colors.grey.shade200
// //                   : Colors.teal.shade50,
// //               foregroundColor: reminder.taken
// //                   ? Colors.grey.shade800
// //                   : Colors.teal.shade700,
// //               elevation: 0,
// //               shape: RoundedRectangleBorder(
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //             ),
// //             icon: Icon(
// //               reminder.taken ? Icons.refresh : Icons.check_circle_outline,
// //             ),
// //             label: Text(reminder.taken ? 'Ulangi Jadwal' : 'Tandai diminum'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _AddMedicationDialog extends StatefulWidget {
// //   const _AddMedicationDialog();
// //   @override
// //   State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
// // }

// // class _AddMedicationDialogState extends State<_AddMedicationDialog> {
// //   final TextEditingController _nameController = TextEditingController();
// //   final TextEditingController _doseController = TextEditingController();
// //   final TextEditingController _noteController = TextEditingController();
// //   TimeOfDay? _selectedTime;

// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _doseController.dispose();
// //     _noteController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) => AlertDialog(
// //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //     backgroundColor: Colors.white,
// //     title: const Text('Tambah Pengingat'),
// //     content: SingleChildScrollView(
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           TextField(
// //             controller: _nameController,
// //             decoration: const InputDecoration(
// //               labelText: 'Nama obat',
// //               filled: true,
// //               fillColor: Color(0xfff7f9fb),
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.all(Radius.circular(12)),
// //                 borderSide: BorderSide.none,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 12),
// //           TextField(
// //             controller: _doseController,
// //             decoration: const InputDecoration(
// //               labelText: 'Dosis',
// //               filled: true,
// //               fillColor: Color(0xfff7f9fb),
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.all(Radius.circular(12)),
// //                 borderSide: BorderSide.none,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 12),
// //           TextField(
// //             controller: _noteController,
// //             decoration: const InputDecoration(
// //               labelText: 'Catatan (opsional)',
// //               filled: true,
// //               fillColor: Color(0xfff7f9fb),
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.all(Radius.circular(12)),
// //                 borderSide: BorderSide.none,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 12),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: Text(
// //                   _selectedTime == null
// //                       ? 'Jam belum dipilih'
// //                       : 'Jam: ${_selectedTime!.format(context)}',
// //                 ),
// //               ),
// //               TextButton.icon(
// //                 onPressed: () async {
// //                   final picked = await showTimePicker(
// //                     context: context,
// //                     initialTime: TimeOfDay.now(),
// //                   );
// //                   if (picked != null) setState(() => _selectedTime = picked);
// //                 },
// //                 icon: const Icon(Icons.schedule),
// //                 label: const Text('Pilih Jam'),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     ),
// //     actions: [
// //       TextButton(
// //         onPressed: () => Navigator.pop(context),
// //         child: const Text('Batal'),
// //       ),
// //       ElevatedButton(
// //         onPressed: () {
// //           if (_nameController.text.isEmpty || _selectedTime == null) return;
// //           Navigator.pop(context, {
// //             'name': _nameController.text,
// //             'dose': _doseController.text,
// //             'note': _noteController.text,
// //             'time': _selectedTime,
// //           });
// //         },
// //         child: const Text('Simpan'),
// //       ),
// //     ],
// //   );
// // }

// // ====================================================================
// // File: medication_reminder_screen.dart — Redesigned UI, same functions
// // ====================================================================

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../services/local/notification_service.dart';
// import 'medication_history_screen.dart';
// import 'models/medication_reminder.dart';
// import 'widgets/add_medication_dialog_v2.dart';
// import '../settings/settings_screen.dart';

// class MedicationReminderScreen extends StatefulWidget {
//   const MedicationReminderScreen({super.key});

//   @override
//   State<MedicationReminderScreen> createState() =>
//       _MedicationReminderScreenState();
// }

// class _MedicationReminderScreenState extends State<MedicationReminderScreen>
//     with SingleTickerProviderStateMixin {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   late final Stream<List<MedicationReminder>> _remindersStream;
//   final List<String> _periodFilters = const [
//     'Semua',
//     'Pagi',
//     'Siang',
//     'Sore',
//     'Malam',
//   ];
//   String _selectedPeriod = 'Semua';
//   String? _userId;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnim;

//   @override
//   void initState() {
//     super.initState();
//     _userId = _supabase.auth.currentUser?.id;
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//     _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     if (_userId == null) {
//       _remindersStream = Stream.value(const []);
//     } else {
//       _remindersStream = _supabase
//           .from('medication_reminders')
//           .stream(primaryKey: ['id'])
//           .eq('user_id', _userId!)
//           .order('time', ascending: true)
//           .map(
//             (rows) =>
//                 rows.map((row) => MedicationReminder.fromMap(row)).toList(),
//           );
//     }
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }

//   Future<void> _addMedication() async {
//     if (_userId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Masuk terlebih dahulu untuk menambah pengingat.'),
//         ),
//       );
//       return;
//     }
//     final result = await showDialog<Map<String, dynamic>>(
//       context: context,
//       builder: (_) => const AddMedicationDialogV2(),
//     );
//     if (result == null) return;

//     final List<TimeOfDay> times = result['times'] as List<TimeOfDay>;
//     final String name = result['name'] as String;

//     try {
//       for (final time in times) {
//         final payload = {
//           'user_id': _userId,
//           'name': name,
//           'time': _toDbTime(time),
//           'taken': false,
//           'total_stock': result['total_stock'] ?? 0,
//           'current_stock': result['current_stock'] ?? 0,
//         };
//         final inserted = await _supabase
//             .from('medication_reminders')
//             .insert(payload)
//             .select()
//             .single();
//         await NotificationService().scheduleMedicationNotification(
//           inserted['id'].toString(),
//           inserted['name'] as String,
//           time,
//         );
//       }
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Pengingat $name disetel untuk ${times.length} waktu'),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Gagal menambah pengingat: $e')));
//     }
//   }

//   Future<void> _toggleTaken(MedicationReminder reminder) async {
//     try {
//       await _supabase
//           .from('medication_reminders')
//           .update({'taken': !reminder.taken})
//           .eq('id', reminder.id);
//       if (!reminder.taken)
//         await NotificationService().cancelMedicationNotifications(
//           reminder.id.toString(),
//         );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
//     }
//   }

//   void _openHistory() {
//     if (_userId == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => MedicationHistoryScreen(userId: _userId!),
//       ),
//     );
//   }

//   List<MedicationReminder> _filterReminders(
//     List<MedicationReminder> reminders,
//   ) {
//     if (_selectedPeriod == 'Semua') return reminders;
//     return reminders.where((r) => r.period == _selectedPeriod).toList();
//   }

//   MedicationReminder? _upcomingReminder(List<MedicationReminder> reminders) {
//     if (reminders.isEmpty) return null;
//     final nowMin = _timeToMin(TimeOfDay.now());
//     try {
//       return reminders.firstWhere(
//         (r) => !r.taken && _timeToMin(r.time) >= nowMin,
//       );
//     } catch (_) {
//       final pending = reminders.where((r) => !r.taken).toList();
//       return pending.isNotEmpty ? pending.first : null;
//     }
//   }

//   int _timeToMin(TimeOfDay t) => t.hour * 60 + t.minute;

//   String _timeUntil(TimeOfDay time) {
//     final now = TimeOfDay.now();
//     var diff = _timeToMin(time) - _timeToMin(now);
//     if (diff < 0) diff += 24 * 60;
//     final h = diff ~/ 60;
//     final m = diff % 60;
//     if (h == 0) return '$m mnt lagi';
//     if (m == 0) return '$h jam lagi';
//     return '$h j $m m lagi';
//   }

//   String _toDbTime(TimeOfDay t) =>
//       '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark
//           ? const Color(0xFF0F1923)
//           : const Color(0xFFF0F4FF),
//       body: Stack(
//         children: [
//           // Header gradient bg
//           Container(
//             height: 240,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: isDark
//                     ? [const Color(0xFF1A237E), const Color(0xFF0F1923)]
//                     : [Colors.indigo.shade600, Colors.blue.shade400],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Column(
//               children: [
//                 // AppBar custom
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(
//                           Icons.arrow_back_ios_rounded,
//                           color: Colors.white,
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       Expanded(
//                         child: const Text(
//                           'Pengingat Obat',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(
//                           Icons.settings_rounded,
//                           color: Colors.white,
//                         ),
//                         onPressed: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const SettingsScreen(),
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(
//                           Icons.history_rounded,
//                           color: Colors.white,
//                         ),
//                         onPressed: _openHistory,
//                       ),
//                       IconButton(
//                         icon: const Icon(
//                           Icons.volume_up_rounded,
//                           color: Colors.white,
//                         ),
//                         onPressed: () => NotificationService().testAlarmNow(),
//                       ),
//                     ],
//                   ),
//                 ),

//                 Expanded(
//                   child: StreamBuilder<List<MedicationReminder>>(
//                     stream: _remindersStream,
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting)
//                         return const Center(child: CircularProgressIndicator());
//                       final reminders = snapshot.data ?? [];
//                       final filtered = _filterReminders(reminders);
//                       final upcoming = _upcomingReminder(filtered);
//                       final total = reminders.length;
//                       final completed = reminders.where((r) => r.taken).length;

//                       return ListView(
//                         padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
//                         children: [
//                           const SizedBox(height: 8),
//                           _summaryCard(completed, total, isDark),
//                           const SizedBox(height: 16),
//                           if (upcoming != null)
//                             _upcomingCard(upcoming, isDark)
//                           else if (total > 0)
//                             _allDoneCard(isDark),
//                           const SizedBox(height: 16),
//                           _periodSelector(),
//                           const SizedBox(height: 16),
//                           if (filtered.isEmpty)
//                             _emptyCard(isDark)
//                           else
//                             ...filtered.map(
//                               (r) => Padding(
//                                 padding: const EdgeInsets.only(bottom: 12),
//                                 child: _medicationCard(r, isDark),
//                               ),
//                             ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).padding.bottom + 80,
//         ),
//         child: FloatingActionButton.extended(
//           onPressed: _addMedication,
//           backgroundColor: Colors.indigo.shade500,
//           icon: const Icon(Icons.add),
//           label: const Text(
//             'Tambah Obat',
//             style: TextStyle(fontWeight: FontWeight.w700),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _summaryCard(int completed, int total, bool isDark) {
//     final progress = total == 0 ? 0.0 : completed / total;
//     final allDone = completed == total && total > 0;
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1A2636) : Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               ScaleTransition(
//                 scale: _pulseAnim,
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: allDone
//                           ? [Colors.green.shade400, Colors.teal.shade400]
//                           : [Colors.indigo.shade400, Colors.blue.shade400],
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Icon(
//                     allDone
//                         ? Icons.check_circle_rounded
//                         : Icons.medication_rounded,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Progres Hari Ini',
//                       style: TextStyle(
//                         color: Colors.grey.shade500,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       total == 0
//                           ? 'Belum ada jadwal'
//                           : '$completed dari $total obat diminum',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w800,
//                         color: isDark ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: allDone
//                       ? Colors.green.withOpacity(0.12)
//                       : Colors.indigo.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '${(progress * 100).round()}%',
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w800,
//                     color: allDone
//                         ? Colors.green.shade600
//                         : Colors.indigo.shade600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: LinearProgressIndicator(
//               value: progress.clamp(0, 1),
//               minHeight: 10,
//               backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
//               valueColor: AlwaysStoppedAnimation(
//                 allDone ? Colors.green.shade400 : Colors.indigo.shade400,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _upcomingCard(MedicationReminder reminder, bool isDark) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.orange.shade400, Colors.amber.shade400],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.orange.withOpacity(0.3),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Icon(
//               Icons.alarm_rounded,
//               color: Colors.white,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Jadwal Berikutnya',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   reminder.name,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.schedule, size: 14, color: Colors.white70),
//                     const SizedBox(width: 4),
//                     Text(
//                       reminder.time.format(context),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 3,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.25),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         _timeUntil(reminder.time),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _allDoneCard(bool isDark) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green.shade400, Colors.teal.shade400],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.3),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: const Icon(
//               Icons.check_circle_rounded,
//               color: Colors.white,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Luar biasa! Semua obat sudah diminum 🎉',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Pertahankan konsistensi Anda!',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.85),
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _periodSelector() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: _periodFilters.map((p) {
//           final sel = _selectedPeriod == p;
//           return GestureDetector(
//             onTap: () => setState(() => _selectedPeriod = p),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               margin: const EdgeInsets.only(right: 8),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: sel
//                     ? Colors.indigo.shade500
//                     : (isDark ? Colors.white12 : Colors.white),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: sel
//                     ? [
//                         BoxShadow(
//                           color: Colors.indigo.withOpacity(0.3),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ]
//                     : [],
//               ),
//               child: Text(
//                 p,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: sel ? Colors.white : Colors.grey.shade500,
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _emptyCard(bool isDark) {
//     return Container(
//       padding: const EdgeInsets.all(32),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1A2636) : Colors.white,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.indigo.shade100, Colors.blue.shade100],
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.medication_outlined,
//               size: 40,
//               color: Colors.indigo.shade400,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Belum ada pengingat',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//               color: isDark ? Colors.white : Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'Tekan tombol "Tambah Obat" untuk menambahkan jadwal obat Anda.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _medicationCard(MedicationReminder reminder, bool isDark) {
//     final accent = reminder.taken ? Colors.green : Colors.indigo;
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF1A2636) : Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: reminder.taken
//               ? Colors.green.withOpacity(0.3)
//               : Colors.transparent,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               GestureDetector(
//                 onTap: () => _toggleTaken(reminder),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: reminder.taken
//                         ? Colors.green.withOpacity(0.12)
//                         : Colors.indigo.withOpacity(0.08),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Icon(
//                     reminder.taken
//                         ? Icons.check_circle_rounded
//                         : Icons.medication_liquid_outlined,
//                     color: accent,
//                     size: 24,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       reminder.name,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: isDark ? Colors.white : Colors.black87,
//                         decoration: reminder.taken
//                             ? TextDecoration.lineThrough
//                             : null,
//                         decorationColor: Colors.grey,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.access_time,
//                           size: 13,
//                           color: Colors.grey.shade400,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           reminder.time.format(context),
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade400,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: reminder.taken
//                       ? Colors.green.withOpacity(0.12)
//                       : Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Text(
//                   reminder.taken ? '✓ Sudah' : 'Belum',
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w700,
//                     color: reminder.taken
//                         ? Colors.green.shade600
//                         : Colors.orange.shade700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (reminder.currentStock > 0 || reminder.totalStock > 0) ...[
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(
//                   Icons.inventory_2_outlined,
//                   size: 14,
//                   color: Colors.grey.shade400,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   'Stok: ${reminder.currentStock}/${reminder.totalStock}',
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
//                 ),
//                 const Spacer(),
//                 if (reminder.currentStock <= 5)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 3,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Text(
//                       'Stok hampir habis!',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.red,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ],
//           const SizedBox(height: 10),
//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton.icon(
//               onPressed: () => _toggleTaken(reminder),
//               icon: Icon(
//                 reminder.taken ? Icons.replay_rounded : Icons.check_rounded,
//                 size: 16,
//               ),
//               label: Text(
//                 reminder.taken ? 'Batalkan' : 'Tandai Diminum',
//                 style: const TextStyle(fontWeight: FontWeight.w600),
//               ),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: accent,
//                 side: BorderSide(color: accent.withOpacity(0.4)),
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ====================================================================
// File: medication_reminder_screen_v2.dart
// Medication Reminder — Toggle per-card, Edit, Delete, Alarm settings
// ====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/local/notification_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../data/mock_medications.dart';
import 'models/medication_reminder.dart';
import 'models/common_medications.dart';
import 'widgets/add_medication_dialog.dart';
import '../settings/settings_screen.dart';
import 'medication_history_screen.dart';

// ── Mock data model ────────────────────────────────────────────────────────
class MedicationV2 {
  String id;
  String name;
  String dose;
  String note;
  String category;
  TimeOfDay time;
  String period;
  bool taken;
  bool isActive; // NEW: can be toggled per-card
  String alarmSound; // NEW: alarm sound choice
  int stock;
  int totalStock;
  int frequencyPerDay;
  int quantityPerDose;

  MedicationV2({
    required this.id,
    required this.name,
    this.category = 'Antiplatelet',
    required this.dose,
    this.note = '',
    required this.time,
    required this.period,
    this.taken = false,
    this.isActive = true,
    this.alarmSound = 'default',
    this.stock = 30,
    this.totalStock = 30,
    this.frequencyPerDay = 1,
    this.quantityPerDose = 1,
  });
}

final _alarmSounds = [
  (id: 'default', label: 'Default', icon: Icons.notifications_rounded),
  (id: 'chime', label: 'Chime', icon: Icons.music_note_rounded),
  (id: 'alarm', label: 'Alarm', icon: Icons.alarm_rounded),
  (id: 'silent', label: 'Senyap', icon: Icons.notifications_off_rounded),
];

// ── Sample data ────────────────────────────────────────────────────────────
List<MedicationV2> _sampleMeds = [
  MedicationV2(
    id: '1',
    name: 'Aspirin',
    dose: '100mg',
    note: 'Setelah makan pagi',
    time: const TimeOfDay(hour: 8, minute: 0),
    period: 'Pagi',
    taken: true,
    isActive: true,
    alarmSound: 'bell',
    stock: 20,
    totalStock: 30,
  ),
  MedicationV2(
    id: '2',
    name: 'Atorvastatin',
    dose: '20mg',
    note: 'Sebelum tidur',
    time: const TimeOfDay(hour: 21, minute: 0),
    period: 'Malam',
    taken: false,
    isActive: true,
    alarmSound: 'default',
    stock: 28,
    totalStock: 30,
  ),
  MedicationV2(
    id: '3',
    name: 'Amlodipine',
    dose: '5mg',
    note: 'Setelah makan siang',
    time: const TimeOfDay(hour: 12, minute: 0),
    period: 'Siang',
    taken: false,
    isActive: false, // Disabled
    alarmSound: 'chime',
    stock: 5,
    totalStock: 30,
  ),
];

// ── Main Screen ────────────────────────────────────────────────────────────
class MedicationReminderScreenV2 extends StatefulWidget {
  final bool isPreview;
  const MedicationReminderScreenV2({super.key, this.isPreview = false});

  @override
  State<MedicationReminderScreenV2> createState() =>
      _MedicationReminderScreenV2State();
}

class _MedicationReminderScreenV2State extends State<MedicationReminderScreenV2>
    with SingleTickerProviderStateMixin {
  List<MedicationV2> _meds = [];
  String _selectedPeriod = 'Semua';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Simulated alarm popup
  Timer? _alarmTimer;
  bool _alarmVisible = false;
  MedicationV2? _alarmMed;

  @override
  void initState() {
    super.initState();
    _meds = globalSampleMeds;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _alarmTimer?.cancel();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  double get _fs => 1.0;

  List<MedicationV2> get _filtered {
    if (_selectedPeriod == 'Semua') return _meds;
    return _meds.where((m) => m.period == _selectedPeriod).toList();
  }

  int get _takenCount => _meds.where((m) => m.taken && m.isActive).length;
  int get _activeCount => _meds.where((m) => m.isActive).length;

  // ── Actions ──────────────────────────────────────────────────────────────
  void _toggleTaken(MedicationV2 med) {
    HapticFeedback.lightImpact();
    setState(() {
      med.taken = !med.taken;

      final dVal = double.tryParse(med.dose.split(' ').first) ?? 1.0;
      if (med.taken) {
        med.stock = (med.stock - dVal.toInt()).clamp(0, med.totalStock);
      } else {
        med.stock = (med.stock + dVal.toInt()).clamp(0, med.totalStock);
      }
    });
  }

  void _toggleActive(MedicationV2 med) {
    HapticFeedback.selectionClick();
    setState(() {
      med.isActive = !med.isActive;
      if (!med.isActive) med.taken = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          med.isActive
              ? '🔔 Pengingat ${med.name} diaktifkan'
              : '🔕 Pengingat ${med.name} dinonaktifkan',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteMed(MedicationV2 med) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pengingat'),
        content: Text('Hapus pengingat "${med.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _meds.remove(med));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _editMed(MedicationV2 med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditMedicationSheet(
        med: med,
        isDark: _isDark,
        onSave: (updated) {
          setState(() {
            med.name = updated.name;
            med.dose = updated.dose;
            med.note = updated.note;
            med.time = updated.time;
            med.period = updated.period;
            med.alarmSound = updated.alarmSound;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${med.name} berhasil diperbarui'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _addMed() async {
    final curUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddMedicationDialog(userId: curUserId),
    );

    if (result != null) {
      final name = result['name'] as String;
      final dose = result['dose'] as String;
      final note = result['note'] as String;
      final stockStr = result['stock'] as String?;
      final times = result['times'] as List<TimeOfDay>;
      final alarmSnd = result['alarmSound'] as String? ?? 'default';

      final int totalStock = int.tryParse(stockStr ?? '') ?? 0;

      setState(() {
        for (final t in times) {
          String period = 'Pagi';
          if (t.hour >= 18)
            period = 'Malam';
          else if (t.hour >= 15)
            period = 'Sore';
          else if (t.hour >= 11)
            period = 'Siang';

          final newMed = MedicationV2(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                t.hour.toString(),
            name: name,
            dose: dose,
            time: t,
            period: period,
            note: note,
            totalStock: totalStock,
            stock: totalStock,
            alarmSound: alarmSnd,
          );

          if (!globalSampleMeds.any((m) => m.id == newMed.id)) {
            globalSampleMeds.add(newMed);
          }
        }

        _meds = globalSampleMeds;

        // Sorting by time
        _meds.sort((a, b) {
          int aMin = a.time.hour * 60 + a.time.minute;
          int bMin = b.time.hour * 60 + b.time.minute;
          return aMin.compareTo(bMin);
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Obat $name berhasil ditambahkan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // Simulate alarm popup
  void _simulateAlarm(MedicationV2 med) {
    setState(() {
      _alarmVisible = true;
      _alarmMed = med;
    });
  }

  void _dismissAlarm() {
    setState(() {
      _alarmVisible = false;
      _alarmMed = null;
    });
  }

  void _takeMedFromAlarm() {
    if (_alarmMed != null) {
      setState(() => _alarmMed!.taken = true);
    }
    _dismissAlarm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${_alarmMed?.name ?? 'Obat'} sudah diminum'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? const Color(0xFF060B1A) : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),

          // Alarm popup overlay
          if (_alarmVisible && _alarmMed != null)
            _AlarmOverlay(
              med: _alarmMed!,
              isDark: _isDark,
              onTake: _takeMedFromAlarm,
              onSnooze: () {
                _dismissAlarm();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⏰ Alarm ditunda 5 menit')),
                );
              },
              onDismiss: _dismissAlarm,
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        child: FloatingActionButton.extended(
          onPressed: _addMed,
          backgroundColor: Colors.indigo.shade500,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Tambah Obat',
            style: TextStyle(fontSize: 14 * _fs, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A1A6E), const Color(0xFF060B1A)]
              : [Colors.indigo.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                          'Pengingat Obat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24 * _fs,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$_takenCount dari $_activeCount obat sudah diminum',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13 * _fs,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Test alarm button
                  GestureDetector(
                    onTap: () {
                      if (_meds.isNotEmpty) {
                        _simulateAlarm(_meds.first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _activeCount == 0 ? 0 : _takenCount / _activeCount,
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    _takenCount == _activeCount && _activeCount > 0
                        ? Colors.greenAccent
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Period filter
        _PeriodFilter(
          selected: _selectedPeriod,
          isDark: _isDark,
          fs: _fs,
          onChanged: (v) => setState(() => _selectedPeriod = v),
        ),
        const SizedBox(height: 16),

        // Upcoming card
        ..._buildUpcomingCard(),

        // Medication cards
        ..._filtered.map(
          (med) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MedicationCardV2(
              med: med,
              isDark: _isDark,
              fs: _fs,
              onToggleTaken: () => _toggleTaken(med),
              onToggleActive: () => _toggleActive(med),
              onEdit: () => _editMed(med),
              onDelete: () => _deleteMed(med),
              onTestAlarm: () => _simulateAlarm(med),
            ),
          ),
        ),

        if (_filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF0F1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 56,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada pengingat',
                  style: TextStyle(
                    fontSize: 16 * _fs,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildUpcomingCard() {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final upcoming = _meds
        .where(
          (m) =>
              m.isActive &&
              !m.taken &&
              (m.time.hour * 60 + m.time.minute) >= nowMin,
        )
        .toList();

    if (upcoming.isEmpty) return [];
    final next = upcoming.reduce(
      (a, b) =>
          (a.time.hour * 60 + a.time.minute) <
              (b.time.hour * 60 + b.time.minute)
          ? a
          : b,
    );

    final diffMin = (next.time.hour * 60 + next.time.minute) - nowMin;
    final countDown = diffMin < 60
        ? '$diffMin mnt lagi'
        : '${diffMin ~/ 60} jam lagi';

    return [
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Berikutnya',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    next.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${next.dose} • ${next.time.format(context)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                countDown,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

// ── Period Filter ──────────────────────────────────────────────────────────
class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.selected,
    required this.isDark,
    required this.fs,
    required this.onChanged,
  });
  final String selected;
  final bool isDark;
  final double fs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['Semua', 'Pagi', 'Siang', 'Sore', 'Malam']
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected == p
                          ? Colors.indigo.shade500
                          : (isDark ? Colors.white12 : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected == p
                            ? Colors.indigo.shade500
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 13 * fs,
                        fontWeight: FontWeight.w700,
                        color: selected == p
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Medication Card V2 ─────────────────────────────────────────────────────
class _MedicationCardV2 extends StatelessWidget {
  const _MedicationCardV2({
    required this.med,
    required this.isDark,
    required this.fs,
    required this.onToggleTaken,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onTestAlarm,
  });

  final MedicationV2 med;
  final bool isDark;
  final double fs;
  final VoidCallback onToggleTaken;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTestAlarm;

  Color get _accent => med.taken ? Colors.green : Colors.indigo;

  IconData get _alarmIcon {
    switch (med.alarmSound) {
      case 'chime':
        return Icons.music_note_rounded;
      case 'alarm':
        return Icons.alarm_rounded;
      case 'silent':
        return Icons.notifications_off_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF0F1B2E) : Colors.white;
    final opacity = med.isActive ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: med.taken
              ? Border.all(color: Colors.green.withOpacity(0.3))
              : (med.isActive
                    ? null
                    : Border.all(color: Colors.grey.withOpacity(0.3))),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      med.taken
                          ? Icons.check_circle_rounded
                          : Icons.medication_rounded,
                      color: _accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: TextStyle(
                            fontSize: 16 * fs,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            decoration: med.taken && med.isActive
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '${med.dose} • ${med.time.format(context)}',
                          style: TextStyle(
                            fontSize: 12 * fs,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status + toggle row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active toggle switch
                      Column(
                        children: [
                          Text(
                            med.isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 9 * fs,
                              color: med.isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Switch(
                            value: med.isActive,
                            onChanged: (_) => onToggleActive(),
                            activeColor: Colors.green,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Stock indicator
              if (med.totalStock > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stok: ${med.stock}/${med.totalStock}',
                      style: TextStyle(
                        fontSize: 11 * fs,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: med.stock / med.totalStock,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            med.stock <= 5 ? Colors.red : Colors.teal,
                          ),
                        ),
                      ),
                    ),
                    if (med.stock <= 5) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hampir habis!',
                          style: TextStyle(
                            fontSize: 9 * fs,
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              if (med.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '📝 ${med.note}',
                  style: TextStyle(
                    fontSize: 11 * fs,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons row
              Row(
                children: [
                  // Alarm sound badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_alarmIcon, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _alarmSounds
                              .firstWhere(
                                (a) => a.id == med.alarmSound,
                                orElse: () => _alarmSounds.first,
                              )
                              .label,
                          style: TextStyle(
                            fontSize: 11 * fs,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Test alarm
                  _SmallBtn(
                    icon: Icons.volume_up_rounded,
                    tooltip: 'Tes Alarm',
                    color: Colors.blue,
                    onTap: onTestAlarm,
                  ),
                  const SizedBox(width: 6),

                  // Edit
                  _SmallBtn(
                    icon: Icons.edit_rounded,
                    tooltip: 'Edit',
                    color: Colors.orange,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),

                  // Delete
                  _SmallBtn(
                    icon: Icons.delete_rounded,
                    tooltip: 'Hapus',
                    color: Colors.red,
                    onTap: onDelete,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Mark taken button
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: OutlinedButton.icon(
                    onPressed: med.isActive ? onToggleTaken : null,
                    icon: Icon(
                      med.taken
                          ? Icons.replay_rounded
                          : Icons.check_circle_outlined,
                      size: 16,
                    ),
                    label: Text(
                      med.taken ? 'Batalkan' : 'Tandai Diminum',
                      style: TextStyle(fontSize: 13 * fs),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: BorderSide(color: _accent.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ── Alarm Overlay ──────────────────────────────────────────────────────────
class _AlarmOverlay extends StatefulWidget {
  const _AlarmOverlay({
    required this.med,
    required this.isDark,
    required this.onTake,
    required this.onSnooze,
    required this.onDismiss,
  });
  final MedicationV2 med;
  final bool isDark;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  @override
  State<_AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<_AlarmOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    // Vibrate
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF0F1B2E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.indigo.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alarm icon
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF3D5AFE)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '⏰ Waktunya Minum Obat!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.med.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.indigo,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.med.dose} • ${widget.med.time.format(context)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                if (widget.med.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.med.note,
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onSnooze,
                        child: const Text('Tunda 5 Mnt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: widget.onTake,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Sudah Diminum',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text(
                    'Tutup',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Medication Bottom Sheet ───────────────────────────────────────────
class _EditMedicationSheet extends StatefulWidget {
  const _EditMedicationSheet({
    required this.med,
    required this.isDark,
    required this.onSave,
  });
  final MedicationV2 med;
  final bool isDark;
  final ValueChanged<MedicationV2> onSave;

  @override
  State<_EditMedicationSheet> createState() => _EditMedicationSheetState();
}

class _EditMedicationSheetState extends State<_EditMedicationSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _doseCtrl;
  late TextEditingController _noteCtrl;
  late TimeOfDay _time;
  late String _period;
  late String _alarmSound;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.med.name);
    _doseCtrl = TextEditingController(text: widget.med.dose);
    _noteCtrl = TextEditingController(text: widget.med.note);
    _time = widget.med.time;
    _period = widget.med.period;
    _alarmSound = widget.med.alarmSound;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.isDark ? const Color(0xFF0F1B2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.med.name.isEmpty ? 'Tambah Obat' : 'Edit Obat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _field(_nameCtrl, 'Nama Obat', Icons.medication_rounded),
                  const SizedBox(height: 12),
                  _field(
                    _doseCtrl,
                    'Dosis (misal: 100mg)',
                    Icons.science_rounded,
                  ),
                  const SizedBox(height: 12),
                  _field(_noteCtrl, 'Catatan', Icons.notes_rounded),
                  const SizedBox(height: 16),

                  // Time picker
                  _label('Waktu'),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.white10
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _time.format(context),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Period
                  _label('Periode'),
                  Row(
                    children: ['Pagi', 'Siang', 'Sore', 'Malam']
                        .map(
                          (p) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() => _period = p),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _period == p
                                        ? Colors.indigo
                                        : (widget.isDark
                                              ? Colors.white10
                                              : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _period == p
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Alarm sound
                  _label('Suara Alarm'),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _alarmSounds
                          .map(
                            (s) => GestureDetector(
                              onTap: () => setState(() => _alarmSound = s.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _alarmSound == s.id
                                      ? Colors.indigo
                                      : (widget.isDark
                                            ? Colors.white10
                                            : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      s.icon,
                                      color: _alarmSound == s.id
                                          ? Colors.white
                                          : Colors.grey,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _alarmSound == s.id
                                            ? Colors.white
                                            : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama obat tidak boleh kosong'),
                            ),
                          );
                          return;
                        }
                        widget.onSave(
                          MedicationV2(
                            id: widget.med.id,
                            name: _nameCtrl.text.trim(),
                            dose: _doseCtrl.text.trim(),
                            note: _noteCtrl.text.trim(),
                            time: _time,
                            period: _period,
                            taken: widget.med.taken,
                            isActive: widget.med.isActive,
                            alarmSound: _alarmSound,
                            stock: widget.med.stock,
                            totalStock: widget.med.totalStock,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
        filled: true,
        fillColor: widget.isDark ? Colors.white10 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        labelStyle: TextStyle(
          color: widget.isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: widget.isDark ? Colors.white54 : Colors.black54,
      ),
    ),
  );
}
