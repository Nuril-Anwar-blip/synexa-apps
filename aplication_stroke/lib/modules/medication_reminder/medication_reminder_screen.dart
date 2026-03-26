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
import '../../services/remote/backend_api_service.dart';
import '../../services/remote/socket_service.dart';
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
  final BackendApiService _apiService = BackendApiService.instance;
  final SocketService _socketService = SocketService.instance;

  List<MedicationReminder> _reminders = [];
  String? _userId;
  int _selectedTab = 0; // 0 = Medicine, 1 = Exercise
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = _supabase.auth.currentUser?.id;
    _loadReminders();
    _setupSocketListener();
  }

  @override
  void dispose() {
    _socketService.offMedicationUpdated();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await _apiService.getMedications(_userId!);
      setState(() {
        _reminders = data
            .map((row) => MedicationReminder.fromMap(row))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  void _setupSocketListener() {
    _socketService.onMedicationUpdated((data) {
      final action = data['action'];
      final medicationData = data['data'];

      if (action == 'created') {
        final newReminder = MedicationReminder.fromMap(medicationData);
        setState(() {
          _reminders.insert(0, newReminder);
        });
      } else if (action == 'taken') {
        final updatedReminder = MedicationReminder.fromMap(medicationData);
        setState(() {
          final index = _reminders.indexWhere(
            (r) => r.id == updatedReminder.id,
          );
          if (index != -1) {
            _reminders[index] = updatedReminder;
          }
        });
      }
    });
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
      final data = await _apiService.addMedication(
        name: result['name'],
        dose: result['dose'],
        note: result['note'],
        time: result['time'],
        period: result['period'],
        frequency: result['frequency'],
      );

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
      await _apiService.markMedicationTaken(reminder.id);

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
      // Note: Backend doesn't have toggle endpoint, so we'll use Supabase directly for now
      await _supabase
          .from('medication_reminders')
          .update({'is_active': !reminder.isActive})
          .eq('id', reminder.id);

      final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
      if (updatedReminder.isActive) {
        await NotificationService().scheduleAllReminders(updatedReminder);
      } else {
        await NotificationService().cancelMedicationNotifications(reminder.id);
      }

      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = updatedReminder;
        }
      });

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
        // Note: Backend doesn't have delete endpoint, so we'll use Supabase directly for now
        await _supabase
            .from('medication_reminders')
            .delete()
            .eq('id', reminder.id);

        // Batalkan Alarm
        await NotificationService().cancelMedicationNotifications(reminder.id);

        setState(() {
          _reminders.removeWhere((r) => r.id == reminder.id);
        });

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
      // Note: Backend doesn't have update endpoint, so we'll use Supabase directly for now
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

      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = updatedReminder;
        }
      });

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
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildRemindersList(isDark, bottomPad, langProvider),
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

  Widget _buildRemindersList(
    bool isDark,
    double bottomPad,
    LanguageProvider langProvider,
  ) {
    final filteredReminders = _reminders
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
                ? Icons.medication_outlined
                : Icons.fitness_center_outlined,
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
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Sekarang'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminder.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    reminder.isActive ? Icons.alarm_on : Icons.alarm_off,
                    color: reminder.isActive ? Colors.teal : Colors.grey,
                  ),
                  onPressed: onToggleActive,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (reminder.dose != null && reminder.dose!.isNotEmpty)
              Text(
                'Dosis: ${reminder.dose}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  reminder.period,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: reminder.takenTimes / reminder.timesPerDay,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                reminder.isAllTaken ? Colors.green : Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${reminder.takenTimes}/${reminder.timesPerDay} diminum',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (!reminder.isAllTaken)
                  ElevatedButton(
                    onPressed: onMarkTaken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Minum'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add Reminder Sheet
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
  final _noteController = TextEditingController();
  String _selectedPeriod = 'Pagi';
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.editReminder != null) {
      _nameController.text = widget.editReminder!.name;
      _doseController.text = widget.editReminder!.dose ?? '';
      _noteController.text = widget.editReminder!.note ?? '';
      _selectedPeriod = widget.editReminder!.period;
      // Use the first time from the times list
      if (widget.editReminder!.times.isNotEmpty) {
        _selectedTime = widget.editReminder!.times.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text,
        'dose': _doseController.text,
        'note': _noteController.text,
        'period': _selectedPeriod,
        'time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'frequency': 'daily',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.editReminder != null
                    ? 'Edit Pengingat'
                    : 'Tambah Pengingat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Obat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama obat harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doseController,
                decoration: InputDecoration(
                  labelText: 'Dosis (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  labelText: 'Periode',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Pagi', 'Siang', 'Sore', 'Malam']
                    .map(
                      (period) =>
                          DropdownMenuItem(value: period, child: Text(period)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Waktu'),
                subtitle: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.editReminder != null ? 'Simpan' : 'Tambah',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
