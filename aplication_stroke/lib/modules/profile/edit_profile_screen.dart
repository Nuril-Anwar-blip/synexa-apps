// ====================================================================
// File: edit_profile_screen.dart
// Edit Profil — Redesigned with full i18n, theme & font-size support
// ====================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/emergency_contact_model.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final double? weight;
  final double? height;
  final String? medicalHistory;
  final String? drugAllergy;
  final List<EmergencyContactModel>? emergencyContacts;
  final String? photoUrl;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.birthDate,
    this.gender,
    this.weight,
    this.height,
    this.medicalHistory,
    this.drugAllergy,
    this.emergencyContacts,
    this.photoUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _drugAllergyController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _emergencyContactRelationshipController;

  DateTime? _birthDate;
  String? _gender;
  String? _photoUrl;
  File? _pickedImage;
  bool _isUploading = false;
  bool _isPickingImage = false;
  int _currentSection = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _birthDate = widget.birthDate;
    _weightController = TextEditingController(
      text: widget.weight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.height?.toString() ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: widget.medicalHistory ?? '',
    );
    _drugAllergyController = TextEditingController(
      text: widget.drugAllergy ?? '',
    );

    final firstContact = (widget.emergencyContacts?.isNotEmpty ?? false)
        ? widget.emergencyContacts!.first
        : null;
    _emergencyContactNameController = TextEditingController(
      text: firstContact?.name ?? '',
    );
    _emergencyContactPhoneController = TextEditingController(
      text: firstContact?.phoneNumber ?? '',
    );
    _emergencyContactRelationshipController = TextEditingController(
      text: firstContact?.relationship ?? '',
    );

    _gender = widget.gender;
    _photoUrl = widget.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _medicalHistoryController.dispose();
    _drugAllergyController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
        await _uploadImageToSupabase(_pickedImage!);
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _uploadImageToSupabase(File file) async {
    setState(() => _isUploading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isUploading = false);
      return;
    }
    final path =
        '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = Supabase.instance.client.storage.from('profile_pictures');
    try {
      final bytes = await file.readAsBytes();
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      final url = storage.getPublicUrl(path);
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _saveProfile() {
    final lang = context.read<LanguageProvider>();

    List<String> parseList(String text) {
      if (text.trim().isEmpty) return [];
      return text
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (_drugAllergyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.translate({
              'id':
                  'Alergi Obat wajib diisi (ketik "Tidak ada" jika tidak punya).',
              'en': 'Drug Allergy is required (type "None" if you have none).',
              'ms': 'Alergi Ubat wajib diisi (taip "Tiada" jika tiada).',
            }),
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
      'name': _nameController.text,
      'phoneNumber': _phoneController.text,
      'birthDate': _birthDate,
      'gender': _gender,
      'weight': double.tryParse(_weightController.text),
      'height': double.tryParse(_heightController.text),
      'medicalHistory': parseList(_medicalHistoryController.text),
      'drugAllergy': parseList(_drugAllergyController.text),
      'emergencyContacts': [
        EmergencyContactModel(
          name: _emergencyContactNameController.text,
          phoneNumber: _emergencyContactPhoneController.text,
          relationship: _emergencyContactRelationshipController.text,
        ),
      ],
      'photoUrl': _photoUrl,
    });
  }

  // FIX: Kalkulasi umur yang benar
  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeP.isDarkMode;
    final fs = themeP.fontSize;

    String t(Map<String, String> m) => lang.translate(m);

    final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF4F7FB);
    final cardColor = isDark ? const Color(0xFF1A2636) : Colors.white;

    final sections = [
      t({'id': 'Info Pribadi', 'en': 'Personal', 'ms': 'Peribadi'}),
      t({'id': 'Medis', 'en': 'Medical', 'ms': 'Perubatan'}),
      t({'id': 'Darurat', 'en': 'Emergency', 'ms': 'Kecemasan'}),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Header gradient
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0D4A47), const Color(0xFF0F1923)]
                    : [Colors.teal.shade600, Colors.teal.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          t({
                            'id': 'Edit Profil',
                            'en': 'Edit Profile',
                            'ms': 'Edit Profil',
                          }),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * fs,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar
                const SizedBox(height: 8),
                _buildAvatar(fs),
                const SizedBox(height: 16),

                // Section tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: sections.asMap().entries.map((e) {
                        final selected = _currentSection == e.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _currentSection = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12 * fs,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.teal.shade700
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildSection(
                        _currentSection,
                        isDark,
                        cardColor,
                        fs,
                        lang,
                        t,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Save button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade600, Colors.teal.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        t({
                          'id': 'Simpan Perubahan',
                          'en': 'Save Changes',
                          'ms': 'Simpan Perubahan',
                        }),
                        style: TextStyle(
                          fontSize: 15 * fs,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isUploading ? null : _saveProfile,
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

  Widget _buildAvatar(double fs) {
    ImageProvider? provider;
    if (_pickedImage != null) {
      provider = FileImage(_pickedImage!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      provider = NetworkImage(_photoUrl!);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                backgroundImage: provider,
                child: provider == null
                    ? const Icon(Icons.person, size: 52, color: Colors.grey)
                    : null,
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: (_isUploading || _isPickingImage) ? null : _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    int index,
    bool isDark,
    Color cardColor,
    double fs,
    LanguageProvider lang,
    String Function(Map<String, String>) t,
  ) {
    switch (index) {
      case 0:
        return _buildPersonalSection(isDark, cardColor, fs, lang, t);
      case 1:
        return _buildMedicalSection(isDark, cardColor, fs, lang, t);
      case 2:
        return _buildEmergencySection(isDark, cardColor, fs, lang, t);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalSection(
    bool isDark,
    Color cardColor,
    double fs,
    LanguageProvider lang,
    String Function(Map<String, String>) t,
  ) {
    // FIX: Hitung umur dari _birthDate yang dipilih
    final age = _calculateAge(_birthDate);

    return Column(
      key: const ValueKey('personal'),
      children: [
        _sectionCard(
          title: t({
            'id': 'Informasi Dasar',
            'en': 'Basic Info',
            'ms': 'Info Asas',
          }),
          cardColor: cardColor,
          isDark: isDark,
          fs: fs,
          children: [
            _buildTextField(
              controller: _nameController,
              label: t({
                'id': 'Nama Lengkap',
                'en': 'Full Name',
                'ms': 'Nama Penuh',
              }),
              icon: Icons.person_outline,
              isDark: isDark,
              fs: fs,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: t({
                'id': 'Nomor Telepon',
                'en': 'Phone Number',
                'ms': 'Nombor Telefon',
              }),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              fs: fs,
            ),
            const SizedBox(height: 12),
            _buildGenderSelector(isDark, fs, lang, t),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: t({
            'id': 'Fisik & Lahir',
            'en': 'Physical & Birth',
            'ms': 'Fizikal & Lahir',
          }),
          cardColor: cardColor,
          isDark: isDark,
          fs: fs,
          children: [
            // Date picker
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate ?? DateTime(now.year - 20),
                  firstDate: DateTime(1900),
                  lastDate: now,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.teal.shade500,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (date != null && mounted) {
                  setState(() => _birthDate = date);
                }
              },
              child: _datePickerField(isDark, fs, t, age),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: t({
                      'id': 'Tinggi (cm)',
                      'en': 'Height (cm)',
                      'ms': 'Tinggi (cm)',
                    }),
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    fs: fs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: t({
                      'id': 'Berat (kg)',
                      'en': 'Weight (kg)',
                      'ms': 'Berat (kg)',
                    }),
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    fs: fs,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicalSection(
    bool isDark,
    Color cardColor,
    double fs,
    LanguageProvider lang,
    String Function(Map<String, String>) t,
  ) {
    return Column(
      key: const ValueKey('medical'),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t({
                    'id': 'Pisahkan beberapa item dengan koma (,)',
                    'en': 'Separate multiple items with comma (,)',
                    'ms': 'Pisahkan beberapa item dengan koma (,)',
                  }),
                  style: TextStyle(
                    fontSize: 12 * fs,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: t({
            'id': 'Kondisi Medis',
            'en': 'Medical Conditions',
            'ms': 'Kondisi Perubatan',
          }),
          cardColor: cardColor,
          isDark: isDark,
          fs: fs,
          children: [
            _buildTextField(
              controller: _medicalHistoryController,
              label: t({
                'id': 'Riwayat Penyakit',
                'en': 'Medical History',
                'ms': 'Sejarah Perubatan',
              }),
              hint: t({
                'id': 'hipertensi, diabetes',
                'en': 'hypertension, diabetes',
                'ms': 'hipertensi, diabetes',
              }),
              icon: Icons.history_edu_outlined,
              isDark: isDark,
              fs: fs,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _drugAllergyController,
              label: t({
                'id': 'Alergi Obat *',
                'en': 'Drug Allergy *',
                'ms': 'Alergi Ubat *',
              }),
              hint: t({
                'id': 'aspirin, parasetamol',
                'en': 'aspirin, paracetamol',
                'ms': 'aspirin, parasetamol',
              }),
              icon: Icons.vaccines_outlined,
              isDark: isDark,
              fs: fs,
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencySection(
    bool isDark,
    Color cardColor,
    double fs,
    LanguageProvider lang,
    String Function(Map<String, String>) t,
  ) {
    return Column(
      key: const ValueKey('emergency'),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.orange.shade400],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emergency_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t({
                    'id': 'Kontak ini akan dihubungi saat keadaan darurat.',
                    'en': 'This contact will be reached in emergencies.',
                    'ms': 'Kenalan ini akan dihubungi semasa kecemasan.',
                  }),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * fs,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: t({
            'id': 'Kontak Darurat',
            'en': 'Emergency Contact',
            'ms': 'Kenalan Kecemasan',
          }),
          cardColor: cardColor,
          isDark: isDark,
          fs: fs,
          children: [
            _buildTextField(
              controller: _emergencyContactNameController,
              label: t({
                'id': 'Nama Kontak',
                'en': 'Contact Name',
                'ms': 'Nama Kenalan',
              }),
              icon: Icons.person_pin_circle_outlined,
              isDark: isDark,
              fs: fs,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emergencyContactPhoneController,
              label: t({
                'id': 'Nomor Telepon',
                'en': 'Phone Number',
                'ms': 'Nombor Telefon',
              }),
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              fs: fs,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emergencyContactRelationshipController,
              label: t({
                'id': 'Hubungan',
                'en': 'Relationship',
                'ms': 'Hubungan',
              }),
              hint: t({
                'id': 'Contoh: Ayah, Ibu',
                'en': 'e.g. Father, Mother',
                'ms': 'cth. Bapa, Ibu',
              }),
              icon: Icons.handshake_outlined,
              isDark: isDark,
              fs: fs,
            ),
          ],
        ),
      ],
    );
  }

  Widget _datePickerField(
    bool isDark,
    double fs,
    String Function(Map<String, String>) t,
    int age,
  ) {
    final cardColor = isDark ? const Color(0xFF243347) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.cake_outlined, color: Colors.teal.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: _birthDate != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t({
                          'id': 'Tanggal Lahir',
                          'en': 'Birth Date',
                          'ms': 'Tarikh Lahir',
                        }),
                        style: TextStyle(
                          fontSize: 11 * fs,
                          color: Colors.teal.shade400,
                        ),
                      ),
                      Text(
                        '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: TextStyle(
                          fontSize: 15 * fs,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  )
                : Text(
                    t({
                      'id': 'Pilih Tanggal Lahir',
                      'en': 'Select Birth Date',
                      'ms': 'Pilih Tarikh Lahir',
                    }),
                    style: TextStyle(fontSize: 14 * fs, color: hintColor),
                  ),
          ),
          // FIX: Tampilkan umur yang dihitung dengan benar
          if (_birthDate != null && age > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$age ${t({'id': 'th', 'en': 'yr', 'ms': 'thn'})}',
                style: TextStyle(
                  fontSize: 13 * fs,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade600,
                ),
              ),
            ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: hintColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(
    bool isDark,
    double fs,
    LanguageProvider lang,
    String Function(Map<String, String>) t,
  ) {
    final options = {
      'male': t({'id': 'Laki-laki', 'en': 'Male', 'ms': 'Lelaki'}),
      'female': t({'id': 'Perempuan', 'en': 'Female', 'ms': 'Perempuan'}),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t({'id': 'Jenis Kelamin', 'en': 'Gender', 'ms': 'Jantina'}),
          style: TextStyle(
            fontSize: 12 * fs,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.entries.map((entry) {
            final selected = _gender == entry.key;
            final isMale = entry.key == 'male';
            final color = isMale ? Colors.blue : Colors.pink;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: isMale ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.12)
                        : (isDark
                              ? const Color(0xFF243347)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMale ? Icons.male : Icons.female,
                        color: selected ? color : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13 * fs,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required Color cardColor,
    required bool isDark,
    required double fs,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15 * fs,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required double fs,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14 * fs,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.teal.shade400, size: 20),
        labelStyle: TextStyle(fontSize: 13 * fs, color: Colors.grey.shade500),
        hintStyle: TextStyle(fontSize: 13 * fs, color: Colors.grey.shade400),
        filled: true,
        fillColor: isDark ? const Color(0xFF243347) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
