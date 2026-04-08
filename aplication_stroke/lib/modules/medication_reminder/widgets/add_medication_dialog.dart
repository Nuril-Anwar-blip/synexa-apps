import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/common_medications.dart';
import '../../../services/remote/medication_service.dart';

Color _darken(Color color, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color _lighten(Color color, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

class AddMedicationDialog extends StatefulWidget {
  final String userId;
  const AddMedicationDialog({super.key, required this.userId});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _svc = MedicationService.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String? _selectedMedication;
  bool _isCustomMedication = false;
  String _frequency = '1x sehari';
  List<TimeOfDay> _selectedTimes = [];
  String _alarmSound = 'default';

  bool _loadingMaster = false;
  bool _loadingUserMeds = false;

  List<MedicationMaster> _masterList = [];
  List<MedicationMaster> _filltered = [];
  List<UserMedication> _userMeds = [];

  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  MedicationMaster? _selectedMaster;
  TimeOfDay _time = TimeOfDay.now();
  bool _saveAsUserMed = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadData();
    _searchCtrl.addListener(_onSearch);
    _generateTimes();
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingMaster = true;
      _loadingUserMeds = true;
    });

    try {
      final results = await Future.wait([
        _svc.fetchMedicationMaster(),
        _svc.fetchUserMedications(widget.userId),
      ]);

      if (!mounted) return;
      setState(() {
        _masterList = results[0] as List<MedicationMaster>;
        _userMeds = results[1] as List<UserMedication>;
        _filltered = _masterList;
        _loadingMaster = false;
        _loadingUserMeds = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMaster = false;
        _loadingUserMeds = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filltered = q.isEmpty
          ? _masterList
          : _masterList.where((m) {
              return m.name.toLowerCase().contains(q) ||
                  (m.genericName?.toLowerCase().contains(q) ?? false) ||
                  m.category.toLowerCase().contains(q);
            }).toList();
    });
  }

  void _pickMaster(MedicationMaster med) {
    setState(() {
      _selectedMaster = med;
      _nameCtrl.text = med.name;
      _doseCtrl.text = med.defaultDose ?? '';
    });
    _tab.animateTo(2);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _onMedicationChanged(String? value) {
    setState(() {
      _selectedMedication = value;
      _isCustomMedication = value == 'Lainnya';
      if (!_isCustomMedication && value != null) {
        final med = CommonMedications.findByName(value);
        if (med != null && med.defaultDose != null) {
          _doseController.text = med.defaultDose!;
        }
      } else {
        _doseController.clear();
      }
      _nameController.text = _isCustomMedication ? '' : (value ?? '');
    });
  }

  void _onFrequencyChanged(String value) {
    setState(() {
      _frequency = value;
      _selectedTimes.clear();
      _generateTimes();
    });
  }

  void _generateTimes() {
    _selectedTimes.clear();

    switch (_frequency) {
      case '1x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
        break;
      case '2x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 20, minute: 0));
        break;
      case '3x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 7, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 18, minute: 0));
        break;
      case '4x sehari':
        _selectedTimes.add(const TimeOfDay(hour: 6, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 18, minute: 0));
        _selectedTimes.add(const TimeOfDay(hour: 22, minute: 0));
        break;
      default:
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
    }
  }

  Future<void> _editTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E3A5F), const Color(0xFF0D1B2A)]
                : [Colors.white, Colors.grey.shade50],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Header with Gradient
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tambah Obat Baru',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Isi detail obat untuk menjadwalkan pengingat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            // Content with Premium Cards
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Medicine Selection Card
                    _buildPremiumCard(
                      stepNumber: '1',
                      title: 'Pilih Obat',
                      icon: Icons.medication_rounded,
                      iconColor: Colors.indigo,
                      isDark: isDark,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedMedication,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Pilih dari daftar...',
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: [
                              ...CommonMedications.list.map(
                                (med) => DropdownMenuItem(
                                  value: med.name,
                                  child: Text(
                                    med.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'Lainnya',
                                child: Text('+ Lainnya (Ketik manual)'),
                              ),
                            ],
                            onChanged: _onMedicationChanged,
                          ),
                          if (_isCustomMedication) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ketik nama obat...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Step 2: Dosage Card
                    _buildPremiumCard(
                      stepNumber: '2',
                      title: 'Dosis & Stok',
                      icon: Icons.straighten_rounded,
                      iconColor: Colors.teal,
                      isDark: isDark,
                      child: Column(
                        children: [
                          TextField(
                            controller: _doseController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Contoh: 80 mg, 1 tablet',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Icons.medical_services_outlined,
                                color: Colors.teal.shade400,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Jumlah obat (contoh: 30)',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.teal.shade400,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Step 3: Schedule Card
                    _buildPremiumCard(
                      stepNumber: '3',
                      title: 'Jadwal Minum',
                      icon: Icons.schedule_rounded,
                      iconColor: Colors.orange,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _frequency,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '1x sehari',
                                child: Text('1x sehari (Pagi)'),
                              ),
                              DropdownMenuItem(
                                value: '2x sehari',
                                child: Text('2x sehari (Pagi & Malam)'),
                              ),
                              DropdownMenuItem(
                                value: '3x sehari',
                                child: Text('3x sehari (Pagi, Siang, Sore)'),
                              ),
                              DropdownMenuItem(
                                value: '4x sehari',
                                child: Text('4x sehari (Setiap 6 jam)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _onFrequencyChanged(value);
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_selectedTimes.isNotEmpty) ...[
                            Text(
                              'Waktu:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTimes.asMap().entries.map((
                                entry,
                              ) {
                                final idx = entry.key;
                                final time = entry.value;
                                return InkWell(
                                  onTap: () => _editTime(idx),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.amber.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          time.format(context),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Step 4: Note Card (Optional)
                    _buildPremiumCard(
                      stepNumber: '4',
                      title: 'Catatan (Opsional)',
                      icon: Icons.note_alt_rounded,
                      iconColor: Colors.purple,
                      isDark: isDark,
                      child: TextField(
                        controller: _noteController,
                        maxLines: 2,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Setelah makan, Sebelum tidur',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Premium Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade600,
                            Colors.blue.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final name = _isCustomMedication
                              ? _nameController.text
                              : (_selectedMedication ?? '');
                          if (name.isEmpty || _selectedTimes.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Mohon lengkapi obat dan jadwal',
                                ),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {
                            'name': name,
                            'dose': _doseController.text,
                            'note': _noteController.text,
                            'stock': _stockController.text,
                            'times': _selectedTimes,
                            'frequency': _frequency,
                            'alarmSound': _alarmSound,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Simpan',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard({
    required String stepNumber,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _lighten(iconColor, 0.2),
                        _darken(iconColor, 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      stepNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
