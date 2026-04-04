// // ====================================================================
// // File: edit_profile_screen.dart
// // Edit Profil — Redesigned with full i18n, theme & font-size support
// // ====================================================================

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../providers/theme_provider.dart';
// import '../../providers/language_provider.dart';
// import '../../models/emergency_contact_model.dart';

// class EditProfileScreen extends StatefulWidget {
//   final String name;
//   final String phoneNumber;
//   final DateTime? birthDate;
//   final String? gender;
//   final double? weight;
//   final double? height;
//   final String? medicalHistory;
//   final String? drugAllergy;
//   final List<EmergencyContactModel>? emergencyContacts;
//   final String? photoUrl;

//   const EditProfileScreen({
//     super.key,
//     required this.name,
//     required this.phoneNumber,
//     this.birthDate,
//     this.gender,
//     this.weight,
//     this.height,
//     this.medicalHistory,
//     this.drugAllergy,
//     this.emergencyContacts,
//     this.photoUrl,
//   });

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;
//   late TextEditingController _weightController;
//   late TextEditingController _heightController;
//   late TextEditingController _medicalHistoryController;
//   late TextEditingController _drugAllergyController;
//   late TextEditingController _emergencyContactNameController;
//   late TextEditingController _emergencyContactPhoneController;
//   late TextEditingController _emergencyContactRelationshipController;

//   DateTime? _birthDate;
//   String? _gender;
//   String? _photoUrl;
//   File? _pickedImage;
//   bool _isUploading = false;
//   bool _isPickingImage = false;
//   int _currentSection = 0;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.name);
//     _phoneController = TextEditingController(text: widget.phoneNumber);
//     _birthDate = widget.birthDate;
//     _weightController = TextEditingController(
//       text: widget.weight?.toString() ?? '',
//     );
//     _heightController = TextEditingController(
//       text: widget.height?.toString() ?? '',
//     );
//     _medicalHistoryController = TextEditingController(
//       text: widget.medicalHistory ?? '',
//     );
//     _drugAllergyController = TextEditingController(
//       text: widget.drugAllergy ?? '',
//     );

//     final firstContact = (widget.emergencyContacts?.isNotEmpty ?? false)
//         ? widget.emergencyContacts!.first
//         : null;
//     _emergencyContactNameController = TextEditingController(
//       text: firstContact?.name ?? '',
//     );
//     _emergencyContactPhoneController = TextEditingController(
//       text: firstContact?.phoneNumber ?? '',
//     );
//     _emergencyContactRelationshipController = TextEditingController(
//       text: firstContact?.relationship ?? '',
//     );

//     _gender = widget.gender;
//     _photoUrl = widget.photoUrl;
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _weightController.dispose();
//     _heightController.dispose();
//     _medicalHistoryController.dispose();
//     _drugAllergyController.dispose();
//     _emergencyContactNameController.dispose();
//     _emergencyContactPhoneController.dispose();
//     _emergencyContactRelationshipController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage() async {
//     if (_isPickingImage) return;
//     setState(() => _isPickingImage = true);
//     try {
//       final picker = ImagePicker();
//       final picked = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 75,
//       );
//       if (picked != null && mounted) {
//         setState(() => _pickedImage = File(picked.path));
//         await _uploadImageToSupabase(_pickedImage!);
//       }
//     } finally {
//       if (mounted) setState(() => _isPickingImage = false);
//     }
//   }

//   Future<void> _uploadImageToSupabase(File file) async {
//     setState(() => _isUploading = true);
//     final user = Supabase.instance.client.auth.currentUser;
//     if (user == null) {
//       setState(() => _isUploading = false);
//       return;
//     }
//     final path =
//         '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final storage = Supabase.instance.client.storage.from('profile_pictures');
//     try {
//       final bytes = await file.readAsBytes();
//       await storage.uploadBinary(
//         path,
//         bytes,
//         fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
//       );
//       final url = storage.getPublicUrl(path);
//       if (mounted) setState(() => _photoUrl = url);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
//       }
//     } finally {
//       if (mounted) setState(() => _isUploading = false);
//     }
//   }

//   void _saveProfile() {
//     final lang = context.read<LanguageProvider>();

//     List<String> parseList(String text) {
//       if (text.trim().isEmpty) return [];
//       return text
//           .split(',')
//           .map((e) => e.trim())
//           .where((s) => s.isNotEmpty)
//           .toList();
//     }

//     if (_drugAllergyController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             lang.translate({
//               'id':
//                   'Alergi Obat wajib diisi (ketik "Tidak ada" jika tidak punya).',
//               'en': 'Drug Allergy is required (type "None" if you have none).',
//               'ms': 'Alergi Ubat wajib diisi (taip "Tiada" jika tiada).',
//             }),
//           ),
//           backgroundColor: Colors.red.shade600,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//       return;
//     }

//     Navigator.pop(context, {
//       'name': _nameController.text,
//       'phoneNumber': _phoneController.text,
//       'birthDate': _birthDate,
//       'gender': _gender,
//       'weight': double.tryParse(_weightController.text),
//       'height': double.tryParse(_heightController.text),
//       'medicalHistory': parseList(_medicalHistoryController.text),
//       'drugAllergy': parseList(_drugAllergyController.text),
//       'emergencyContacts': [
//         EmergencyContactModel(
//           name: _emergencyContactNameController.text,
//           phoneNumber: _emergencyContactPhoneController.text,
//           relationship: _emergencyContactRelationshipController.text,
//         ),
//       ],
//       'photoUrl': _photoUrl,
//     });
//   }

//   // FIX: Kalkulasi umur yang benar
//   int _calculateAge(DateTime? birthDate) {
//     if (birthDate == null) return 0;
//     final today = DateTime.now();
//     int age = today.year - birthDate.year;
//     if (today.month < birthDate.month ||
//         (today.month == birthDate.month && today.day < birthDate.day)) {
//       age--;
//     }
//     return age < 0 ? 0 : age;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeP = context.watch<ThemeProvider>();
//     final lang = context.watch<LanguageProvider>();
//     final isDark = themeP.isDarkMode;
//     final fs = themeP.fontSize;

//     String t(Map<String, String> m) => lang.translate(m);

//     final bgColor = isDark ? const Color(0xFF0F1923) : const Color(0xFFF4F7FB);
//     final cardColor = isDark ? const Color(0xFF1A2636) : Colors.white;

//     final sections = [
//       t({'id': 'Info Pribadi', 'en': 'Personal', 'ms': 'Peribadi'}),
//       t({'id': 'Medis', 'en': 'Medical', 'ms': 'Perubatan'}),
//       t({'id': 'Darurat', 'en': 'Emergency', 'ms': 'Kecemasan'}),
//     ];

//     return Scaffold(
//       backgroundColor: bgColor,
//       body: Stack(
//         children: [
//           // Header gradient
//           Container(
//             height: 260,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: isDark
//                     ? [const Color(0xFF0D4A47), const Color(0xFF0F1923)]
//                     : [Colors.teal.shade600, Colors.teal.shade200],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),

//           SafeArea(
//             child: Column(
//               children: [
//                 // Top bar
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
//                         child: Text(
//                           t({
//                             'id': 'Edit Profil',
//                             'en': 'Edit Profile',
//                             'ms': 'Edit Profil',
//                           }),
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 20 * fs,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Avatar
//                 const SizedBox(height: 8),
//                 _buildAvatar(fs),
//                 const SizedBox(height: 16),

//                 // Section tabs
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Row(
//                       children: sections.asMap().entries.map((e) {
//                         final selected = _currentSection == e.key;
//                         return Expanded(
//                           child: GestureDetector(
//                             onTap: () =>
//                                 setState(() => _currentSection = e.key),
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 200),
//                               padding: const EdgeInsets.symmetric(vertical: 10),
//                               decoration: BoxDecoration(
//                                 color: selected
//                                     ? Colors.white
//                                     : Colors.transparent,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 e.value,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 12 * fs,
//                                   fontWeight: FontWeight.w700,
//                                   color: selected
//                                       ? Colors.teal.shade700
//                                       : Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 // Content
//                 Expanded(
//                   child: SingleChildScrollView(
//                     physics: const BouncingScrollPhysics(),
//                     padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
//                     child: AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 250),
//                       child: _buildSection(
//                         _currentSection,
//                         isDark,
//                         cardColor,
//                         fs,
//                         lang,
//                         t,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Save button
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: SafeArea(
//               top: false,
//               child: Container(
//                 padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
//                 decoration: BoxDecoration(
//                   color: cardColor,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.08),
//                       blurRadius: 20,
//                       offset: const Offset(0, -6),
//                     ),
//                   ],
//                 ),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Colors.teal.shade600, Colors.teal.shade400],
//                       ),
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.teal.withOpacity(0.4),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: ElevatedButton.icon(
//                       icon: const Icon(Icons.save_rounded),
//                       label: Text(
//                         t({
//                           'id': 'Simpan Perubahan',
//                           'en': 'Save Changes',
//                           'ms': 'Simpan Perubahan',
//                         }),
//                         style: TextStyle(
//                           fontSize: 15 * fs,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         foregroundColor: Colors.white,
//                         shadowColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                       onPressed: _isUploading ? null : _saveProfile,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAvatar(double fs) {
//     ImageProvider? provider;
//     if (_pickedImage != null) {
//       provider = FileImage(_pickedImage!);
//     } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
//       provider = NetworkImage(_photoUrl!);
//     }

//     return Column(
//       children: [
//         Stack(
//           alignment: Alignment.bottomRight,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white.withOpacity(0.25),
//               ),
//               child: CircleAvatar(
//                 radius: 52,
//                 backgroundColor: Colors.white,
//                 backgroundImage: provider,
//                 child: provider == null
//                     ? const Icon(Icons.person, size: 52, color: Colors.grey)
//                     : null,
//               ),
//             ),
//             if (_isUploading)
//               Positioned.fill(
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.black45,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Center(
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 ),
//               ),
//             GestureDetector(
//               onTap: (_isUploading || _isPickingImage) ? null : _pickImage,
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade500,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2.5),
//                 ),
//                 child: const Icon(
//                   Icons.camera_alt,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSection(
//     int index,
//     bool isDark,
//     Color cardColor,
//     double fs,
//     LanguageProvider lang,
//     String Function(Map<String, String>) t,
//   ) {
//     switch (index) {
//       case 0:
//         return _buildPersonalSection(isDark, cardColor, fs, lang, t);
//       case 1:
//         return _buildMedicalSection(isDark, cardColor, fs, lang, t);
//       case 2:
//         return _buildEmergencySection(isDark, cardColor, fs, lang, t);
//       default:
//         return const SizedBox();
//     }
//   }

//   Widget _buildPersonalSection(
//     bool isDark,
//     Color cardColor,
//     double fs,
//     LanguageProvider lang,
//     String Function(Map<String, String>) t,
//   ) {
//     // FIX: Hitung umur dari _birthDate yang dipilih
//     final age = _calculateAge(_birthDate);

//     return Column(
//       key: const ValueKey('personal'),
//       children: [
//         _sectionCard(
//           title: t({
//             'id': 'Informasi Dasar',
//             'en': 'Basic Info',
//             'ms': 'Info Asas',
//           }),
//           cardColor: cardColor,
//           isDark: isDark,
//           fs: fs,
//           children: [
//             _buildTextField(
//               controller: _nameController,
//               label: t({
//                 'id': 'Nama Lengkap',
//                 'en': 'Full Name',
//                 'ms': 'Nama Penuh',
//               }),
//               icon: Icons.person_outline,
//               isDark: isDark,
//               fs: fs,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _phoneController,
//               label: t({
//                 'id': 'Nomor Telepon',
//                 'en': 'Phone Number',
//                 'ms': 'Nombor Telefon',
//               }),
//               icon: Icons.phone_outlined,
//               keyboardType: TextInputType.phone,
//               isDark: isDark,
//               fs: fs,
//             ),
//             const SizedBox(height: 12),
//             _buildGenderSelector(isDark, fs, lang, t),
//           ],
//         ),
//         const SizedBox(height: 16),
//         _sectionCard(
//           title: t({
//             'id': 'Fisik & Lahir',
//             'en': 'Physical & Birth',
//             'ms': 'Fizikal & Lahir',
//           }),
//           cardColor: cardColor,
//           isDark: isDark,
//           fs: fs,
//           children: [
//             // Date picker
//             GestureDetector(
//               onTap: () async {
//                 final now = DateTime.now();
//                 final date = await showDatePicker(
//                   context: context,
//                   initialDate: _birthDate ?? DateTime(now.year - 20),
//                   firstDate: DateTime(1900),
//                   lastDate: now,
//                   builder: (ctx, child) => Theme(
//                     data: Theme.of(ctx).copyWith(
//                       colorScheme: ColorScheme.light(
//                         primary: Colors.teal.shade500,
//                       ),
//                     ),
//                     child: child!,
//                   ),
//                 );
//                 if (date != null && mounted) {
//                   setState(() => _birthDate = date);
//                 }
//               },
//               child: _datePickerField(isDark, fs, t, age),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildTextField(
//                     controller: _heightController,
//                     label: t({
//                       'id': 'Tinggi (cm)',
//                       'en': 'Height (cm)',
//                       'ms': 'Tinggi (cm)',
//                     }),
//                     icon: Icons.height,
//                     keyboardType: TextInputType.number,
//                     isDark: isDark,
//                     fs: fs,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildTextField(
//                     controller: _weightController,
//                     label: t({
//                       'id': 'Berat (kg)',
//                       'en': 'Weight (kg)',
//                       'ms': 'Berat (kg)',
//                     }),
//                     icon: Icons.monitor_weight_outlined,
//                     keyboardType: TextInputType.number,
//                     isDark: isDark,
//                     fs: fs,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildMedicalSection(
//     bool isDark,
//     Color cardColor,
//     double fs,
//     LanguageProvider lang,
//     String Function(Map<String, String>) t,
//   ) {
//     return Column(
//       key: const ValueKey('medical'),
//       children: [
//         Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color: Colors.amber.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.amber.withOpacity(0.3)),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   t({
//                     'id': 'Pisahkan beberapa item dengan koma (,)',
//                     'en': 'Separate multiple items with comma (,)',
//                     'ms': 'Pisahkan beberapa item dengan koma (,)',
//                   }),
//                   style: TextStyle(
//                     fontSize: 12 * fs,
//                     color: Colors.amber.shade800,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 14),
//         _sectionCard(
//           title: t({
//             'id': 'Kondisi Medis',
//             'en': 'Medical Conditions',
//             'ms': 'Kondisi Perubatan',
//           }),
//           cardColor: cardColor,
//           isDark: isDark,
//           fs: fs,
//           children: [
//             _buildTextField(
//               controller: _medicalHistoryController,
//               label: t({
//                 'id': 'Riwayat Penyakit',
//                 'en': 'Medical History',
//                 'ms': 'Sejarah Perubatan',
//               }),
//               hint: t({
//                 'id': 'hipertensi, diabetes',
//                 'en': 'hypertension, diabetes',
//                 'ms': 'hipertensi, diabetes',
//               }),
//               icon: Icons.history_edu_outlined,
//               isDark: isDark,
//               fs: fs,
//               maxLines: 2,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _drugAllergyController,
//               label: t({
//                 'id': 'Alergi Obat *',
//                 'en': 'Drug Allergy *',
//                 'ms': 'Alergi Ubat *',
//               }),
//               hint: t({
//                 'id': 'aspirin, parasetamol',
//                 'en': 'aspirin, paracetamol',
//                 'ms': 'aspirin, parasetamol',
//               }),
//               icon: Icons.vaccines_outlined,
//               isDark: isDark,
//               fs: fs,
//               maxLines: 2,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildEmergencySection(
//     bool isDark,
//     Color cardColor,
//     double fs,
//     LanguageProvider lang,
//     String Function(Map<String, String>) t,
//   ) {
//     return Column(
//       key: const ValueKey('emergency'),
//       children: [
//         Container(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.red.shade400, Colors.orange.shade400],
//             ),
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Row(
//             children: [
//               const Icon(
//                 Icons.emergency_outlined,
//                 color: Colors.white,
//                 size: 22,
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   t({
//                     'id': 'Kontak ini akan dihubungi saat keadaan darurat.',
//                     'en': 'This contact will be reached in emergencies.',
//                     'ms': 'Kenalan ini akan dihubungi semasa kecemasan.',
//                   }),
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 13 * fs,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 14),
//         _sectionCard(
//           title: t({
//             'id': 'Kontak Darurat',
//             'en': 'Emergency Contact',
//             'ms': 'Kenalan Kecemasan',
//           }),
//           cardColor: cardColor,
//           isDark: isDark,
//           fs: fs,
//           children: [
//             _buildTextField(
//               controller: _emergencyContactNameController,
//               label: t({
//                 'id': 'Nama Kontak',
//                 'en': 'Contact Name',
//                 'ms': 'Nama Kenalan',
//               }),
//               icon: Icons.person_pin_circle_outlined,
//               isDark: isDark,
//               fs: fs,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _emergencyContactPhoneController,
//               label: t({
//                 'id': 'Nomor Telepon',
//                 'en': 'Phone Number',
//                 'ms': 'Nombor Telefon',
//               }),
//               icon: Icons.phone_in_talk_outlined,
//               keyboardType: TextInputType.phone,
//               isDark: isDark,
//               fs: fs,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               controller: _emergencyContactRelationshipController,
//               label: t({
//                 'id': 'Hubungan',
//                 'en': 'Relationship',
//                 'ms': 'Hubungan',
//               }),
//               hint: t({
//                 'id': 'Contoh: Ayah, Ibu',
//                 'en': 'e.g. Father, Mother',
//                 'ms': 'cth. Bapa, Ibu',
//               }),
//               icon: Icons.handshake_outlined,
//               isDark: isDark,
//               fs: fs,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _datePickerField(
//     bool isDark,
//     double fs,
//     String Function(Map<String, String>) t,
//     int age,
//   ) {
//     final cardColor = isDark ? const Color(0xFF243347) : Colors.grey.shade100;
//     final textColor = isDark ? Colors.white70 : Colors.black87;
//     final hintColor = isDark ? Colors.white38 : Colors.grey.shade500;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.cake_outlined, color: Colors.teal.shade400, size: 22),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _birthDate != null
//                 ? Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         t({
//                           'id': 'Tanggal Lahir',
//                           'en': 'Birth Date',
//                           'ms': 'Tarikh Lahir',
//                         }),
//                         style: TextStyle(
//                           fontSize: 11 * fs,
//                           color: Colors.teal.shade400,
//                         ),
//                       ),
//                       Text(
//                         '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
//                         style: TextStyle(
//                           fontSize: 15 * fs,
//                           fontWeight: FontWeight.w600,
//                           color: textColor,
//                         ),
//                       ),
//                     ],
//                   )
//                 : Text(
//                     t({
//                       'id': 'Pilih Tanggal Lahir',
//                       'en': 'Select Birth Date',
//                       'ms': 'Pilih Tarikh Lahir',
//                     }),
//                     style: TextStyle(fontSize: 14 * fs, color: hintColor),
//                   ),
//           ),
//           // FIX: Tampilkan umur yang dihitung dengan benar
//           if (_birthDate != null && age > 0)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.teal.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 '$age ${t({'id': 'th', 'en': 'yr', 'ms': 'thn'})}',
//                 style: TextStyle(
//                   fontSize: 13 * fs,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.teal.shade600,
//                 ),
//               ),
//             ),
//           const SizedBox(width: 6),
//           Icon(Icons.chevron_right, color: hintColor, size: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildGenderSelector(
//     bool isDark,
//     double fs,
//     LanguageProvider lang,
//     String Function(Map<String, String>) t,
//   ) {
//     final options = {
//       'male': t({'id': 'Laki-laki', 'en': 'Male', 'ms': 'Lelaki'}),
//       'female': t({'id': 'Perempuan', 'en': 'Female', 'ms': 'Perempuan'}),
//     };

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           t({'id': 'Jenis Kelamin', 'en': 'Gender', 'ms': 'Jantina'}),
//           style: TextStyle(
//             fontSize: 12 * fs,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade500,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: options.entries.map((entry) {
//             final selected = _gender == entry.key;
//             final isMale = entry.key == 'male';
//             final color = isMale ? Colors.blue : Colors.pink;

//             return Expanded(
//               child: GestureDetector(
//                 onTap: () => setState(() => _gender = entry.key),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   margin: EdgeInsets.only(right: isMale ? 8 : 0),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   decoration: BoxDecoration(
//                     color: selected
//                         ? color.withOpacity(0.12)
//                         : (isDark
//                               ? const Color(0xFF243347)
//                               : Colors.grey.shade100),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(
//                       color: selected ? color : Colors.transparent,
//                       width: 2,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         isMale ? Icons.male : Icons.female,
//                         color: selected ? color : Colors.grey.shade400,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         entry.value,
//                         style: TextStyle(
//                           fontSize: 13 * fs,
//                           fontWeight: FontWeight.w700,
//                           color: selected ? color : Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _sectionCard({
//     required String title,
//     required Color cardColor,
//     required bool isDark,
//     required double fs,
//     required List<Widget> children,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
//             blurRadius: 20,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 15 * fs,
//               fontWeight: FontWeight.w800,
//               color: isDark ? Colors.white : Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required bool isDark,
//     required double fs,
//     TextInputType? keyboardType,
//     String? hint,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       style: TextStyle(
//         fontSize: 14 * fs,
//         color: isDark ? Colors.white : Colors.black87,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         prefixIcon: Icon(icon, color: Colors.teal.shade400, size: 20),
//         labelStyle: TextStyle(fontSize: 13 * fs, color: Colors.grey.shade500),
//         hintStyle: TextStyle(fontSize: 13 * fs, color: Colors.grey.shade400),
//         filled: true,
//         fillColor: isDark ? const Color(0xFF243347) : Colors.grey.shade100,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide.none,
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 14,
//         ),
//       ),
//     );
//   }
// }

// ====================================================================
// File: edit_profile_screen.dart — Full Redesign v3
// ✅ ThemeProvider + LanguageProvider di semua widget
// ✅ Tampilan premium dengan glassmorphism & gradient
// ✅ TextField dengan animasi fokus yang indah
// ✅ Gender selector visual yang menarik
// ====================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _headerAnim;
  late AnimationController _tabAnim;
  late Animation<double> _headerFade;

  // Section accent colors — same teal brand but per-section tint
  static const _sectionColors = [
    Color(0xFF00897B), // teal - personal
    Color(0xFFE53935), // red - medical
    Color(0xFFFF6F00), // amber - emergency
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _tabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();

    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _birthDate = widget.birthDate;
    _weightController = TextEditingController(text: widget.weight?.toString() ?? '');
    _heightController = TextEditingController(text: widget.height?.toString() ?? '');
    _medicalHistoryController = TextEditingController(text: widget.medicalHistory ?? '');
    _drugAllergyController = TextEditingController(text: widget.drugAllergy ?? '');

    final firstContact = (widget.emergencyContacts?.isNotEmpty ?? false)
        ? widget.emergencyContacts!.first : null;
    _emergencyContactNameController = TextEditingController(text: firstContact?.name ?? '');
    _emergencyContactPhoneController = TextEditingController(text: firstContact?.phoneNumber ?? '');
    _emergencyContactRelationshipController = TextEditingController(text: firstContact?.relationship ?? '');
    _gender = widget.gender;
    _photoUrl = widget.photoUrl;
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _tabAnim.dispose();
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
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
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
    if (user == null) { setState(() => _isUploading = false); return; }
    final path = '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = Supabase.instance.client.storage.from('profile_pictures');
    try {
      final bytes = await file.readAsBytes();
      await storage.uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final url = storage.getPublicUrl(path);
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _saveProfile() {
    final lang = context.read<LanguageProvider>();
    List<String> parseList(String text) {
      if (text.trim().isEmpty) return [];
      return text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
    }
    if (_drugAllergyController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.translate({'id': 'Alergi Obat wajib diisi.', 'en': 'Drug Allergy is required.', 'ms': 'Alergi Ubat wajib diisi.'})),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      setState(() => _currentSection = 1); // jump to medical tab
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context, {
      'name': _nameController.text,
      'phoneNumber': _phoneController.text,
      'birthDate': _birthDate,
      'gender': _gender,
      'weight': double.tryParse(_weightController.text),
      'height': double.tryParse(_heightController.text),
      'medicalHistory': parseList(_medicalHistoryController.text),
      'drugAllergy': parseList(_drugAllergyController.text),
      'emergencyContacts': [EmergencyContactModel(
        name: _emergencyContactNameController.text,
        phoneNumber: _emergencyContactPhoneController.text,
        relationship: _emergencyContactRelationshipController.text,
      )],
      'photoUrl': _photoUrl,
    });
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age < 0 ? 0 : age;
  }

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = themeP.isDarkMode;
    final fs = themeP.fontSize;
    String t(Map<String, String> m) => lang.translate(m);

    final bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF);
    final card = isDark ? const Color(0xFF131D2E) : Colors.white;
    final sectionColor = _sectionColors[_currentSection];

    final tabs = [
      (icon: Icons.person_rounded, label: t({'id': 'Info Pribadi', 'en': 'Personal', 'ms': 'Peribadi'})),
      (icon: Icons.medical_services_rounded, label: t({'id': 'Medis', 'en': 'Medical', 'ms': 'Perubatan'})),
      (icon: Icons.emergency_rounded, label: t({'id': 'Darurat', 'en': 'Emergency', 'ms': 'Kecemasan'})),
    ];

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        // ── Header dengan gradient dinamis per-section ──────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [sectionColor.withOpacity(0.6), const Color(0xFF0A0F1E)]
                  : [sectionColor, sectionColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(child: FadeTransition(opacity: _headerFade, child: Text(
                  t({'id': 'Edit Profil', 'en': 'Edit Profile', 'ms': 'Edit Profil'}),
                  style: TextStyle(color: Colors.white, fontSize: 20 * fs, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ))),
                // Quick settings indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(lang.languageName.substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),

            // Avatar section
            const SizedBox(height: 16),
            _AvatarWidget(
              pickedImage: _pickedImage,
              photoUrl: _photoUrl,
              isUploading: _isUploading,
              isPickingImage: _isPickingImage,
              onTap: _pickImage,
              sectionColor: sectionColor,
              fs: fs,
              lang: lang,
            ),
            const SizedBox(height: 20),

            // Tab bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(children: tabs.asMap().entries.map((e) {
                  final sel = _currentSection == e.key;
                  return Expanded(child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentSection = e.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))] : [],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(e.value.icon, size: 14, color: sel ? sectionColor : Colors.white.withOpacity(0.7)),
                        const SizedBox(width: 5),
                        Text(e.value.label, style: TextStyle(
                          fontSize: 11 * fs,
                          fontWeight: FontWeight.w700,
                          color: sel ? sectionColor : Colors.white.withOpacity(0.7),
                        )),
                      ]),
                    ),
                  ));
                }).toList()),
              ),
            ),
          ])),
        ),

        // ── Content area ────────────────────────────────────────────────
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(anim), child: child),
          ),
          child: KeyedSubtree(
            key: ValueKey(_currentSection),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: _buildSection(_currentSection, isDark, card, fs, lang, t, sectionColor),
            ),
          ),
        )),
      ]),

      // ── Save button ─────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: card,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6))],
        ),
        child: _SaveButton(isLoading: _isUploading, color: sectionColor, fs: fs, label: t({'id': 'Simpan Perubahan', 'en': 'Save Changes', 'ms': 'Simpan Perubahan'}), onTap: _saveProfile),
      )),
    );
  }

  Widget _buildSection(int index, bool isDark, Color card, double fs, LanguageProvider lang, String Function(Map<String, String>) t, Color accent) {
    switch (index) {
      case 0: return _PersonalSection(
        nameCtrl: _nameController, phoneCtrl: _phoneController,
        birthDate: _birthDate, gender: _gender,
        heightCtrl: _heightController, weightCtrl: _weightController,
        isDark: isDark, card: card, fs: fs, lang: lang, t: t, accent: accent,
        onBirthDateChanged: (d) => setState(() => _birthDate = d),
        onGenderChanged: (g) => setState(() => _gender = g),
        calculateAge: _calculateAge,
      );
      case 1: return _MedicalSection(
        medHistCtrl: _medicalHistoryController, allergyCtrl: _drugAllergyController,
        isDark: isDark, card: card, fs: fs, lang: lang, t: t, accent: accent,
      );
      case 2: return _EmergencySection(
        nameCtrl: _emergencyContactNameController,
        phoneCtrl: _emergencyContactPhoneController,
        relCtrl: _emergencyContactRelationshipController,
        isDark: isDark, card: card, fs: fs, lang: lang, t: t, accent: accent,
      );
      default: return const SizedBox();
    }
  }
}

// ── Avatar Widget ────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.pickedImage, required this.photoUrl, required this.isUploading, required this.isPickingImage, required this.onTap, required this.sectionColor, required this.fs, required this.lang});
  final File? pickedImage;
  final String? photoUrl;
  final bool isUploading, isPickingImage;
  final VoidCallback onTap;
  final Color sectionColor;
  final double fs;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (pickedImage != null) provider = FileImage(pickedImage!);
    else if (photoUrl != null && photoUrl!.isNotEmpty) provider = NetworkImage(photoUrl!);

    return Column(children: [
      GestureDetector(
        onTap: (isUploading || isPickingImage) ? null : onTap,
        child: Stack(alignment: Alignment.center, children: [
          // Outer glow ring
          Container(
            width: 116, height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.2)]),
            ),
          ),
          // Avatar
          Container(
            width: 108, height: 108,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
              boxShadow: [BoxShadow(color: sectionColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
            ),
            child: ClipOval(child: provider != null
              ? Image(image: provider, fit: BoxFit.cover, width: 108, height: 108)
              : Icon(Icons.person_rounded, size: 56, color: Colors.grey.shade400)),
          ),
          // Camera button
          if (!isUploading) Positioned(bottom: 6, right: 6, child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sectionColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: sectionColor.withOpacity(0.4), blurRadius: 8)],
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
          )),
          // Loading overlay
          if (isUploading) Container(
            width: 108, height: 108,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
            child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Text(lang.translate({'id': 'Ketuk untuk ubah foto', 'en': 'Tap to change photo', 'ms': 'Ketuk untuk tukar gambar'}),
        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12 * fs)),
    ]);
  }
}

// ── Save Button ───────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isLoading, required this.color, required this.fs, required this.label, required this.onTap});
  final bool isLoading;
  final Color color;
  final double fs;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Center(child: isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.save_alt_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(color: Colors.white, fontSize: 15 * fs, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            ])),
      ),
    );
  }
}

// ── Reusable TextField ────────────────────────────────────────────────────────
class _AppTextField extends StatefulWidget {
  const _AppTextField({required this.controller, required this.label, required this.icon, required this.isDark, required this.fs, required this.accent, this.keyboardType, this.hint, this.maxLines = 1, this.inputFormatters});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final double fs;
  final Color accent;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<_AppTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() { if (mounted) setState(() => _focused = _focus.hasFocus); });
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fill = widget.isDark
        ? (_focused ? widget.accent.withOpacity(0.08) : const Color(0xFF1E2D42))
        : (_focused ? widget.accent.withOpacity(0.04) : Colors.grey.shade50);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused ? [BoxShadow(color: widget.accent.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        inputFormatters: widget.inputFormatters,
        style: TextStyle(fontSize: 14 * widget.fs, color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            child: Icon(widget.icon, color: _focused ? widget.accent : Colors.grey.shade400, size: 20),
          ),
          labelStyle: TextStyle(fontSize: 13 * widget.fs, color: _focused ? widget.accent : Colors.grey.shade400, fontWeight: FontWeight.w500),
          hintStyle: TextStyle(fontSize: 13 * widget.fs, color: Colors.grey.shade400),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: widget.isDark ? Colors.white12 : Colors.grey.shade200, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: widget.accent, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        ),
      ),
    );
  }
}

// ── Section Card wrapper ──────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.isDark, required this.card, required this.accent, required this.children, this.subtitle});
  final String title;
  final IconData icon;
  final bool isDark;
  final Color card, accent;
  final List<Widget> children;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 20, offset: const Offset(0, 6))],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.transparent),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accent.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
            if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
        ]),
        const SizedBox(height: 18),
        ...children,
      ]),
    );
  }
}

// ── Section 0: Personal ───────────────────────────────────────────────────────
class _PersonalSection extends StatelessWidget {
  const _PersonalSection({required this.nameCtrl, required this.phoneCtrl, required this.birthDate, required this.gender, required this.heightCtrl, required this.weightCtrl, required this.isDark, required this.card, required this.fs, required this.lang, required this.t, required this.accent, required this.onBirthDateChanged, required this.onGenderChanged, required this.calculateAge});
  final TextEditingController nameCtrl, phoneCtrl, heightCtrl, weightCtrl;
  final DateTime? birthDate;
  final String? gender;
  final bool isDark;
  final Color card, accent;
  final double fs;
  final LanguageProvider lang;
  final String Function(Map<String, String>) t;
  final void Function(DateTime) onBirthDateChanged;
  final void Function(String) onGenderChanged;
  final int Function(DateTime?) calculateAge;

  @override
  Widget build(BuildContext context) {
    return Column(key: const ValueKey('personal'), children: [
      _SectionCard(
        title: t({'id': 'Informasi Dasar', 'en': 'Basic Info', 'ms': 'Info Asas'}),
        subtitle: t({'id': 'Data pribadi Anda', 'en': 'Your personal data', 'ms': 'Data peribadi anda'}),
        icon: Icons.person_rounded,
        isDark: isDark, card: card, accent: accent,
        children: [
          _AppTextField(controller: nameCtrl, label: t({'id': 'Nama Lengkap', 'en': 'Full Name', 'ms': 'Nama Penuh'}), icon: Icons.badge_rounded, isDark: isDark, fs: fs, accent: accent),
          const SizedBox(height: 12),
          _AppTextField(controller: phoneCtrl, label: t({'id': 'Nomor Telepon', 'en': 'Phone Number', 'ms': 'Nombor Telefon'}), icon: Icons.phone_rounded, isDark: isDark, fs: fs, accent: accent, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))]),
          const SizedBox(height: 16),
          _GenderSelector(selected: gender, isDark: isDark, fs: fs, accent: accent, lang: lang, t: t, onChanged: onGenderChanged),
        ],
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: t({'id': 'Fisik & Lahir', 'en': 'Physical & Birth', 'ms': 'Fizikal & Lahir'}),
        subtitle: t({'id': 'Data kesehatan fisik', 'en': 'Physical health data', 'ms': 'Data kesihatan fizikal'}),
        icon: Icons.accessibility_new_rounded,
        isDark: isDark, card: card, accent: accent,
        children: [
          _DatePickerField(birthDate: birthDate, isDark: isDark, fs: fs, accent: accent, lang: lang, t: t, calculateAge: calculateAge, onChanged: onBirthDateChanged),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _AppTextField(controller: heightCtrl, label: t({'id': 'Tinggi (cm)', 'en': 'Height (cm)', 'ms': 'Tinggi (cm)'}), icon: Icons.height_rounded, isDark: isDark, fs: fs, accent: accent, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: _AppTextField(controller: weightCtrl, label: t({'id': 'Berat (kg)', 'en': 'Weight (kg)', 'ms': 'Berat (kg)'}), icon: Icons.monitor_weight_rounded, isDark: isDark, fs: fs, accent: accent, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          ]),
        ],
      ),
    ]);
  }
}

// ── Gender Selector ───────────────────────────────────────────────────────────
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.isDark, required this.fs, required this.accent, required this.lang, required this.t, required this.onChanged});
  final String? selected;
  final bool isDark;
  final double fs;
  final Color accent;
  final LanguageProvider lang;
  final String Function(Map<String, String>) t;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (value: 'male', icon: Icons.male_rounded, label: t({'id': 'Laki-laki', 'en': 'Male', 'ms': 'Lelaki'}), color: Colors.blue.shade500),
      (value: 'female', icon: Icons.female_rounded, label: t({'id': 'Perempuan', 'en': 'Female', 'ms': 'Perempuan'}), color: Colors.pink.shade400),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t({'id': 'Jenis Kelamin', 'en': 'Gender', 'ms': 'Jantina'}),
        style: TextStyle(fontSize: 13 * fs, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      const SizedBox(height: 10),
      Row(children: options.map((o) {
        final sel = selected == o.value;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: o.value == 'male' ? 8 : 0),
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(o.value); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? o.color.withOpacity(0.1) : (isDark ? const Color(0xFF1E2D42) : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? o.color : (isDark ? Colors.white12 : Colors.grey.shade200), width: sel ? 2 : 1),
                boxShadow: sel ? [BoxShadow(color: o.color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
              ),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sel ? o.color.withOpacity(0.15) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(o.icon, size: 28, color: sel ? o.color : Colors.grey.shade400),
                ),
                const SizedBox(height: 6),
                Text(o.label, style: TextStyle(fontSize: 13 * fs, fontWeight: FontWeight.w700, color: sel ? o.color : Colors.grey.shade400)),
                if (sel) ...[
                  const SizedBox(height: 4),
                  Container(width: 20, height: 3, decoration: BoxDecoration(color: o.color, borderRadius: BorderRadius.circular(2))),
                ],
              ]),
            ),
          ),
        ));
      }).toList()),
    ]);
  }
}

// ── Date Picker Field ─────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.birthDate, required this.isDark, required this.fs, required this.accent, required this.lang, required this.t, required this.calculateAge, required this.onChanged});
  final DateTime? birthDate;
  final bool isDark;
  final double fs;
  final Color accent;
  final LanguageProvider lang;
  final String Function(Map<String, String>) t;
  final int Function(DateTime?) calculateAge;
  final void Function(DateTime) onChanged;

  @override
  Widget build(BuildContext context) {
    final age = calculateAge(birthDate);
    final hasBirth = birthDate != null;
    final fill = isDark ? const Color(0xFF1E2D42) : Colors.grey.shade50;

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: birthDate ?? DateTime(now.year - 25),
          firstDate: DateTime(1900), lastDate: now,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: accent, onPrimary: Colors.white, surface: isDark ? const Color(0xFF1A2636) : Colors.white)),
            child: child!,
          ),
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.cake_rounded, color: hasBirth ? accent : Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(child: hasBirth ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t({'id': 'Tanggal Lahir', 'en': 'Birth Date', 'ms': 'Tarikh Lahir'}), style: TextStyle(fontSize: 11 * fs, color: accent)),
            Text('${birthDate!.day}/${birthDate!.month}/${birthDate!.year}', style: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          ]) : Text(t({'id': 'Pilih Tanggal Lahir', 'en': 'Select Birth Date', 'ms': 'Pilih Tarikh Lahir'}), style: TextStyle(fontSize: 14 * fs, color: Colors.grey.shade400))),
          if (hasBirth && age > 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withOpacity(0.3))),
            child: Text('$age ${t({'id': 'th', 'en': 'yr', 'ms': 'thn'})}', style: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w800, color: accent)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}

// ── Section 1: Medical ────────────────────────────────────────────────────────
class _MedicalSection extends StatelessWidget {
  const _MedicalSection({required this.medHistCtrl, required this.allergyCtrl, required this.isDark, required this.card, required this.fs, required this.lang, required this.t, required this.accent});
  final TextEditingController medHistCtrl, allergyCtrl;
  final bool isDark;
  final Color card, accent;
  final double fs;
  final LanguageProvider lang;
  final String Function(Map<String, String>) t;

  @override
  Widget build(BuildContext context) {
    return Column(key: const ValueKey('medical'), children: [
      // Info banner
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.amber.shade600.withOpacity(0.15), Colors.orange.shade400.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t({'id': 'Tips Pengisian', 'en': 'Filling Tips', 'ms': 'Tips Pengisian'}), style: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
            const SizedBox(height: 2),
            Text(t({'id': 'Pisahkan beberapa item dengan koma (,)\nContoh: hipertensi, diabetes', 'en': 'Separate items with comma (,)\nExample: hypertension, diabetes', 'ms': 'Pisahkan item dengan koma (,)'}),
              style: TextStyle(fontSize: 11 * fs, color: Colors.amber.shade700, height: 1.4)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: t({'id': 'Kondisi Medis', 'en': 'Medical Conditions', 'ms': 'Kondisi Perubatan'}),
        subtitle: t({'id': 'Informasi untuk apoteker Anda', 'en': 'Info for your pharmacist', 'ms': 'Info untuk ahli farmasi anda'}),
        icon: Icons.medical_information_rounded,
        isDark: isDark, card: card, accent: accent,
        children: [
          _AppTextField(
            controller: medHistCtrl,
            label: t({'id': 'Riwayat Penyakit', 'en': 'Medical History', 'ms': 'Sejarah Perubatan'}),
            hint: t({'id': 'Contoh: hipertensi, diabetes', 'en': 'e.g. hypertension, diabetes', 'ms': 'cth: hipertensi, diabetes'}),
            icon: Icons.history_edu_rounded,
            isDark: isDark, fs: fs, accent: accent, maxLines: 3,
          ),
          const SizedBox(height: 14),
          // Allergy field with required indicator
          Stack(children: [
            _AppTextField(
              controller: allergyCtrl,
              label: t({'id': 'Alergi Obat', 'en': 'Drug Allergy', 'ms': 'Alergi Ubat'}),
              hint: t({'id': 'Ketik "Tidak ada" jika tidak punya', 'en': 'Type "None" if you have none', 'ms': 'Taip "Tiada" jika tiada'}),
              icon: Icons.vaccines_rounded,
              isDark: isDark, fs: fs, accent: accent, maxLines: 3,
            ),
            Positioned(right: 12, top: 12, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('WAJIB', style: TextStyle(fontSize: 9 * fs, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
            )),
          ]),
        ],
      ),
    ]);
  }
}

// ── Section 2: Emergency ──────────────────────────────────────────────────────
class _EmergencySection extends StatelessWidget {
  const _EmergencySection({required this.nameCtrl, required this.phoneCtrl, required this.relCtrl, required this.isDark, required this.card, required this.fs, required this.lang, required this.t, required this.accent});
  final TextEditingController nameCtrl, phoneCtrl, relCtrl;
  final bool isDark;
  final Color card, accent;
  final double fs;
  final LanguageProvider lang;
  final String Function(Map<String, String>) t;

  @override
  Widget build(BuildContext context) {
    return Column(key: const ValueKey('emergency'), children: [
      // Emergency banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFE53935)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t({'id': 'Kontak Darurat Penting!', 'en': 'Emergency Contact Important!', 'ms': 'Kenalan Kecemasan Penting!'}),
              style: TextStyle(color: Colors.white, fontSize: 14 * fs, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(t({'id': 'Kontak ini akan dihubungi saat Anda membutuhkan bantuan darurat.', 'en': 'This contact will be reached in emergency situations.', 'ms': 'Kenalan ini akan dihubungi dalam situasi kecemasan.'}),
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11 * fs, height: 1.4)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: t({'id': 'Kontak Darurat', 'en': 'Emergency Contact', 'ms': 'Kenalan Kecemasan'}),
        subtitle: t({'id': 'Pastikan nomor aktif dan dapat dihubungi', 'en': 'Make sure number is active', 'ms': 'Pastikan nombor aktif'}),
        icon: Icons.contact_phone_rounded,
        isDark: isDark, card: card, accent: accent,
        children: [
          _AppTextField(controller: nameCtrl, label: t({'id': 'Nama Kontak', 'en': 'Contact Name', 'ms': 'Nama Kenalan'}), icon: Icons.person_pin_rounded, isDark: isDark, fs: fs, accent: accent),
          const SizedBox(height: 12),
          _AppTextField(controller: phoneCtrl, label: t({'id': 'Nomor Telepon', 'en': 'Phone Number', 'ms': 'Nombor Telefon'}), icon: Icons.phone_in_talk_rounded, isDark: isDark, fs: fs, accent: accent, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _AppTextField(controller: relCtrl, label: t({'id': 'Hubungan', 'en': 'Relationship', 'ms': 'Hubungan'}), hint: t({'id': 'Contoh: Istri, Ayah, Kakak', 'en': 'e.g. Wife, Father, Sister', 'ms': 'cth: Isteri, Ayah, Kakak'}), icon: Icons.family_restroom_rounded, isDark: isDark, fs: fs, accent: accent),
        ],
      ),
      const SizedBox(height: 16),
      // Quick contact preview
      if (nameCtrl.text.isNotEmpty || phoneCtrl.text.isNotEmpty)
        ListenableBuilder(
          listenable: Listenable.merge([nameCtrl, phoneCtrl, relCtrl]),
          builder: (_, __) => _ContactPreviewCard(name: nameCtrl.text, phone: phoneCtrl.text, rel: relCtrl.text, isDark: isDark, card: card, fs: fs, lang: lang, t: t),
        ),
    ]);
  }
}

// ── Contact Preview Card ──────────────────────────────────────────────────────
class _ContactPreviewCard extends StatelessWidget {
  const _ContactPreviewCard({required this.name, required this.phone, required this.rel, required this.isDark, required this.card, required this.fs, required this.lang, required this.t});
  final String name, phone, rel;
  final bool isDark;
  final Color card;
  final double fs;
  final LanguageProvider lang;
  final String Function(Map<String, String>) t;

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty && phone.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade400, Colors.teal.shade400]), shape: BoxShape.circle),
          child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isNotEmpty ? name : '-', style: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
          if (phone.isNotEmpty) Text(phone, style: TextStyle(fontSize: 12 * fs, color: Colors.grey.shade500)),
          if (rel.isNotEmpty) Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(rel, style: TextStyle(fontSize: 10 * fs, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ),
        ])),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded, color: Colors.green.shade500, size: 20),
        ),
      ]),
    );
  }
}