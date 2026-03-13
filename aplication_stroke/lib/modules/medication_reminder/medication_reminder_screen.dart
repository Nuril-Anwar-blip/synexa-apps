/// ====================================================================
/// File: medication_reminder_screen.dart
/// --------------------------------------------------------------------
/// Layar Pengingat Obat (Medication Reminder Screen)
///
/// Dokumen ini berisi layar utama untuk mengelola pengingat obat
/// dan olahraga dengan fitur:
/// - Tambah obat dengan jenis, dosis, jumlah
/// - Tracking kepatuhan pasien (compliance)
/// - Pengurangan jumlah obat saat diminum
/// - Pengaturan waktu kustom (berapakali per hari)
/// - Edit, hapus, nonaktifkan alarm
/// - Tipe alarm: obat atau olahraga
/// - Alarm snooze 5 menit jika tidak diklik
/// - Popup notifikasi di layar utama
///
/// Author: Tim Developer Synexa
/// ====================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/local/notification_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'models/medication_reminder.dart';
import 'medication_history_screen.dart';

/// List of common medications for stroke patients (for dropdown)
const List<Map<String, String>> commonMedications = [
  {'name': 'Aspirin', 'dose': '80mg'},
  {'name': 'Clopidogrel', 'dose': '75mg'},
  {'name': 'Warfarin', 'dose': '2.5mg'},
  {'name': 'Amlodipine', 'dose': '5mg'},
  {'name': 'Lisinopril', 'dose': '10mg'},
  {'name': 'Metoprolol', 'dose': '50mg'},
  {'name': 'Atorvastatin', 'dose': '20mg'},
  {'name': 'Simvastatin', 'dose': '20mg'},
  {'name': 'Gabapentin', 'dose': '300mg'},
  {'name': 'Paracetamol', 'dose': '500mg'},
  {'name': 'Amoxicillin', 'dose': '500mg'},
  {'name': 'Omeprazole', 'dose': '20mg'},
];

class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() =>
      _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Stream<List<MedicationReminder>> _remindersStream;
  String? _userId;
  int _selectedTab = 0; // 0 = Medicine, 1 = Exercise

  @override
  void initState() {
    super.initState();
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) {
      _remindersStream = Stream.value(const []);
    } else {
      _remindersStream = _supabase
          .from('medication_reminders')
          .stream(primaryKey: ['id'])
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .map(
            (rows) =>
                rows.map((row) => MedicationReminder.fromMap(row)).toList(),
          );
    }
  }

  Future<void> _addReminder() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(
        alarmType: _selectedTab == 0 ? AlarmType.medicine : AlarmType.exercise,
      ),
    );

    if (result == null || _userId == null) return;

    try {
      final data = await _supabase
          .from('medication_reminders')
          .insert({
            'user_id': _userId,
            'name': result['name'],
            'dose': result['dose'],
            'quantity': result['quantity'],
            'times_per_day': result['timesPerDay'],
            'times': result['times'],
            'taken_times': 0,
            'is_active': true,
            'alarm_type': _selectedTab == 0 ? 'medicine' : 'exercise',
            'note': result['note'],
          })
          .select()
          .single();

      // Penjadwalan Alarm
      final newReminder = MedicationReminder.fromMap(data);
      await NotificationService().scheduleAllReminders(newReminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengingat berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambahkan: $e')));
      }
    }
  }

  Future<void> _markAsTaken(MedicationReminder reminder) async {
    if (reminder.isAllTaken) return;

    try {
      final newTakenTimes = reminder.takenTimes + 1;
      final newQuantity = reminder.quantity > 0 ? reminder.quantity - 1 : 0;

      await _supabase
          .from('medication_reminders')
          .update({'taken_times': newTakenTimes, 'quantity': newQuantity})
          .eq('id', reminder.id);

      // Show success feedback
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reminder.name} telah ditandai diminum!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _toggleActive(MedicationReminder reminder) async {
    try {
      final data = await _supabase
          .from('medication_reminders')
          .update({'is_active': !reminder.isActive})
          .eq('id', reminder.id)
          .select()
          .single();

      final updatedReminder = MedicationReminder.fromMap(data);
      if (updatedReminder.isActive) {
        await NotificationService().scheduleAllReminders(updatedReminder);
      } else {
        await NotificationService().cancelMedicationNotifications(reminder.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedReminder.isActive
                  ? 'Alarm diaktifkan'
                  : 'Alarm dinonaktifkan',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengingat'),
        content: Text('Apakah Anda yakin ingin menghapus "${reminder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('medication_reminders')
            .delete()
            .eq('id', reminder.id);

        // Batalkan Alarm
        await NotificationService().cancelMedicationNotifications(reminder.id);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pengingat dihapus')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  Future<void> _editReminder(MedicationReminder reminder) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(
        alarmType: reminder.alarmType,
        editReminder: reminder,
      ),
    );

    if (result == null) return;

    try {
      final data = await _supabase
          .from('medication_reminders')
          .update({
            'name': result['name'],
            'dose': result['dose'],
            'quantity': result['quantity'],
            'times_per_day': result['timesPerDay'],
            'times': result['times'],
          })
          .eq('id', reminder.id)
          .select()
          .single();

      // Update Alarm
      final updatedReminder = MedicationReminder.fromMap(data);
      await NotificationService().scheduleAllReminders(updatedReminder);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengingat diperbarui!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.teal,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    langProvider.translate({
                      'id': 'Pengingat',
                      'en': 'Reminders',
                      'ms': 'Pengingat',
                    }),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1E2A3A), const Color(0xFF0D47A1)]
                            : [Colors.teal.shade600, Colors.teal.shade400],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () {
                      if (_userId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MedicationHistoryScreen(userId: _userId!),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              // Tab Selection
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: langProvider.translate({
                            'id': 'Obat',
                            'en': 'Medicine',
                            'ms': 'Ubat',
                          }),
                          icon: Icons.medication_rounded,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TabButton(
                          label: langProvider.translate({
                            'id': 'Olahraga',
                            'en': 'Exercise',
                            'ms': 'Senaman',
                          }),
                          icon: Icons.fitness_center_rounded,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Reminders List
              StreamBuilder<List<MedicationReminder>>(
                stream: _remindersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allReminders = snapshot.data ?? [];
                  final filteredReminders = allReminders
                      .where(
                        (r) => _selectedTab == 0
                            ? r.alarmType == AlarmType.medicine
                            : r.alarmType == AlarmType.exercise,
                      )
                      .toList();

                  if (filteredReminders.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(
                        isMedicine: _selectedTab == 0,
                        isDark: isDark,
                        onAdd: _addReminder,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final reminder = filteredReminders[index];
                        return _ReminderCard(
                          reminder: reminder,
                          isDark: isDark,
                          langProvider: langProvider,
                          onMarkTaken: () => _markAsTaken(reminder),
                          onToggleActive: () => _toggleActive(reminder),
                          onEdit: () => _editReminder(reminder),
                          onDelete: () => _deleteReminder(reminder),
                        );
                      }, childCount: filteredReminders.length),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addReminder,
            backgroundColor: Colors.teal,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              langProvider.translate({
                'id': 'Tambah',
                'en': 'Add',
                'ms': 'Tambah',
              }),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// Tab Button Widget
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.teal
              : (isDark ? const Color(0xFF1E2A3A) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? Colors.teal
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty State Widget
class _EmptyState extends StatelessWidget {
  final bool isMedicine;
  final bool isDark;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.isMedicine,
    required this.isDark,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMedicine
                ? Icons.medication_rounded
                : Icons.fitness_center_rounded,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            isMedicine
                ? 'Belum ada pengingat obat'
                : 'Belum ada pengingat olahraga',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMedicine
                ? 'Tambah obat untuk memulai'
                : 'Tambah olahraga untuk memulai',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reminder Card Widget
class _ReminderCard extends StatelessWidget {
  final MedicationReminder reminder;
  final bool isDark;
  final LanguageProvider langProvider;
  final VoidCallback onMarkTaken;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.isDark,
    required this.langProvider,
    required this.onMarkTaken,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMedicine = reminder.alarmType == AlarmType.medicine;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: reminder.isActive
            ? null
            : Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isMedicine ? Colors.teal : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isMedicine
                            ? Icons.medication_rounded
                            : Icons.fitness_center_rounded,
                        color: isMedicine ? Colors.teal : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & Dose
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (reminder.dose != null)
                            Text(
                              reminder.dose!,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Action Buttons
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      color: isDark ? const Color(0xFF2D3A4A) : Colors.white,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                          case 'toggle':
                            onToggleActive();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, size: 20),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                reminder.isActive
                                    ? Icons.notifications_off_rounded
                                    : Icons.notifications_on_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reminder.isActive
                                    ? 'Matikan Alarm'
                                    : 'Nyalakan Alarm',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    // Times per day
                    _StatChip(
                      icon: Icons.schedule_rounded,
                      label: '${reminder.timesPerDay}x/hari',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    // Taken
                    _StatChip(
                      icon: Icons.check_circle_rounded,
                      label:
                          '${reminder.takenTimes}/${reminder.timesPerDay} diambil',
                      isDark: isDark,
                      color: reminder.isAllTaken ? Colors.green : null,
                    ),
                    if (isMedicine && reminder.quantity > 0) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.inventory_2_rounded,
                        label: '${reminder.remainingQuantity} tersisa',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),

                // Progress Bar
                const SizedBox(height: 12),
                _ComplianceBar(
                  compliance: reminder.complianceRate,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Action Button
          if (reminder.isActive && !reminder.isAllTaken)
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMarkTaken,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tandai sudah diminum',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // All taken indicator
          if (reminder.isAllTaken)
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Semua dosis hari ini sudah diambil!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Stat Chip Widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? (isDark ? Colors.white54 : Colors.black54);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: chipColor)),
        ],
      ),
    );
  }
}

/// Compliance Bar Widget
class _ComplianceBar extends StatelessWidget {
  final double compliance;
  final bool isDark;

  const _ComplianceBar({required this.compliance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (compliance >= 80) {
      barColor = Colors.green;
    } else if (compliance >= 50) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kepatuhan',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            Text(
              '${compliance.round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: compliance / 100,
            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Add Reminder Bottom Sheet
class _AddReminderSheet extends StatefulWidget {
  final AlarmType alarmType;
  final MedicationReminder? editReminder;

  const _AddReminderSheet({required this.alarmType, this.editReminder});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  int _timesPerDay = 1;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  String? _selectedMedicine; // For dropdown

  @override
  void initState() {
    super.initState();
    if (widget.editReminder != null) {
      _nameController.text = widget.editReminder!.name;
      _doseController.text = widget.editReminder!.dose ?? '';
      _quantityController.text = widget.editReminder!.quantity.toString();
      _noteController.text = widget.editReminder!.note ?? '';
      _timesPerDay = widget.editReminder!.timesPerDay;
      _times = widget.editReminder!.times.isNotEmpty
          ? List.from(widget.editReminder!.times)
          : [const TimeOfDay(hour: 8, minute: 0)];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (time != null) {
      setState(() => _times[index] = time);
    }
  }

  void _addTime() {
    if (_timesPerDay < 6) {
      setState(() {
        _timesPerDay++;
        _times.add(const TimeOfDay(hour: 12, minute: 0));
      });
    }
  }

  void _removeTime() {
    if (_timesPerDay > 1) {
      setState(() {
        _timesPerDay--;
        _times.removeLast();
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final timesString = _times
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .join(',');

    Navigator.pop(context, {
      'name': _nameController.text,
      'dose': _doseController.text.isNotEmpty ? _doseController.text : null,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'timesPerDay': _timesPerDay,
      'times': timesString,
      'note': _noteController.text.isNotEmpty ? _noteController.text : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMedicine = widget.alarmType == AlarmType.medicine;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.editReminder != null
                    ? 'Edit ${isMedicine ? "Obat" : "Olahraga"}'
                    : 'Tambah ${isMedicine ? "Obat" : "Olahraga"}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field with Dropdown for common medications
              if (isMedicine) ...[
                // Dropdown untuk memilih obat umum
                DropdownButtonFormField<String>(
                  value: _selectedMedicine,
                  decoration: InputDecoration(
                    labelText: 'Pilih Obat (atau ketik sendiri)',
                    prefixIcon: const Icon(Icons.medication_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Ketik nama obat sendiri'),
                    ),
                    ...commonMedications.map(
                      (med) => DropdownMenuItem<String>(
                        value: med['name'],
                        child: Text('${med['name']} (${med['dose']})'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMedicine = value;
                      if (value != null) {
                        // Auto-fill dose from common medications
                        final med = commonMedications.firstWhere(
                          (m) => m['name'] == value,
                          orElse: () => {'dose': ''},
                        );
                        _nameController.text = value;
                        _doseController.text = med['dose'] ?? '';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Custom name field (shown when no dropdown selection)
                if (_selectedMedicine == null)
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Obat',
                      prefixIcon: const Icon(Icons.medication_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Mohon isi nama';
                      }
                      return null;
                    },
                  ),
                if (_selectedMedicine == null) const SizedBox(height: 16),
              ] else ...[
                // Name Field for exercise
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isMedicine ? 'Nama Obat' : 'Nama Olahraga',
                    prefixIcon: Icon(
                      isMedicine
                          ? Icons.medication_rounded
                          : Icons.fitness_center_rounded,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon isi nama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Dose Field (for medicine only)
              if (isMedicine) ...[
                TextFormField(
                  controller: _doseController,
                  decoration: InputDecoration(
                    labelText: 'Dosis (contoh: 500mg)',
                    prefixIcon: const Icon(Icons.scale_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity Field
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Stok Obat',
                    prefixIcon: const Icon(Icons.inventory_2_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Catatan/Notes Field
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Times per day
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Berapa kali per hari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _timesPerDay > 1 ? _removeTime : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.teal,
                      ),
                      Text(
                        '$_timesPerDay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: _timesPerDay < 6 ? _addTime : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time Pickers
              ...List.generate(_timesPerDay, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectTime(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: Colors.teal),
                          const SizedBox(width: 12),
                          Text(
                            'Jam ke-${index + 1}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _times[index].format(context),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.editReminder != null
                        ? 'Simpan Perubahan'
                        : 'Tambah Pengingat',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
