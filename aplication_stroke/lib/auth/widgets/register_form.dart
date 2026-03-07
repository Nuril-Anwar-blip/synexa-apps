// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '../../../../models/emergency_contact_model.dart';
// import '../../../../models/user_model.dart';
// import '../../../../services/remote/auth_service.dart';
// import '../../../../utils/input_validator.dart';
// import 'splash_screen.dart';
// import 'auth_redirect_text.dart';
// import 'gender_radio_form.dart';
// import 'multi_select_form.dart';
// import 'password_form_field_with_label.dart';
// import 'text_form_field_with_label.dart';

// // Role registrasi untuk menentukan apakah user pasien atau apoteker
// /// Enam peran pendaftaran: Pasien atau Apoteker.
// enum RegisterRole { patient, pharmacist }

// /// Form pendaftaran dengan stepper (bertahap).
// /// Menyesuaikan input berdasarkan [RegisterRole] yang dipilih.
// class RegisterForm extends StatefulWidget {
//   // role default pasien
//   final RegisterRole role;
//   const RegisterForm({super.key, this.role = RegisterRole.patient});

//   @override
//   State<RegisterForm> createState() => _RegisterFormState();
// }

// class _RegisterFormState extends State<RegisterForm> {
//   // Stepper State
//   // menyimpan step yang aktif (1, 2, 3)
//   int _currentStep = 0;

//   // FormKey khusus step 1
//   late final GlobalKey<FormState> _formKeyStep1;

//   // FormKey khusus step 2
//   late final GlobalKey<FormState> _formKeyStep2;

//   // FormKey khusus step 3
//   late final GlobalKey<FormState> _formKeyStep3;

//   // late final GlobalKey<FormState> _formKey;
//   // Text Controller
//   late final TextEditingController _emailController;
//   late final TextEditingController _passwordController;
//   late final TextEditingController _fullNameController;
//   late final TextEditingController _phoneNumberController;
//   late final TextEditingController _emergencyContactNameController;
//   late final TextEditingController _emergencyContactRelationshipController;
//   late final TextEditingController _emergencyContactPhoneNumberController;
//   late final TextEditingController _ageController;
//   late final TextEditingController _heightController;
//   late final TextEditingController _weightController;
//   late final TextEditingController
//   _pharmacistCodeController; // <-- Controller untuk kode apoteker

//   // AuthService
//   // service untuk ke backend
//   final _authService = AuthService();

//   // List pilihan multi select
//   List<String> _selectedMedicalHistory = [];
//   List<String> _selectedDrugAllergy = [];
//   // Gender
//   String gender = "male";
//   // helper untuk cek apakah role apoteker
//   bool get _isPharmacist => widget.role == RegisterRole.pharmacist;

//   @override
//   void initState() {
//     super.initState();
//     // init form key
//     _formKeyStep1 = GlobalKey<FormState>();
//     _formKeyStep2 = GlobalKey<FormState>();
//     _formKeyStep3 = GlobalKey<FormState>();

//     // _formKey = GlobalKey<FormState>();
//     // init controller
//     _emailController = TextEditingController();
//     _passwordController = TextEditingController();
//     _fullNameController = TextEditingController();
//     _phoneNumberController = TextEditingController();
//     _emergencyContactNameController = TextEditingController();
//     _emergencyContactRelationshipController = TextEditingController();
//     _emergencyContactPhoneNumberController = TextEditingController();
//     _ageController = TextEditingController();
//     _heightController = TextEditingController();
//     _weightController = TextEditingController();
//     _pharmacistCodeController =
//         TextEditingController(); // <-- Inisialisasi controller
//   }

//   @override
//   void dispose() {
//     // dispose controller untuk menghindari memory leak
//     _emailController.dispose();
//     _passwordController.dispose();
//     _fullNameController.dispose();
//     _phoneNumberController.dispose();
//     _emergencyContactNameController.dispose();
//     _emergencyContactRelationshipController.dispose();
//     _emergencyContactPhoneNumberController.dispose();
//     _ageController.dispose();
//     _heightController.dispose();
//     _weightController.dispose();
//     _pharmacistCodeController.dispose(); // <-- Jangan lupa dispose
//     super.dispose();
//   }

//   /// Validasi Step
//   ///
//   /// fungsi ini memastikan user tidak bisa lanjut step
//   /// sebelum data pada step itu valid
//   ///

//   bool _validateCurrentStep() {
//     if (_currentStep == 0) {
//       // step 1: Data Diri
//       return _formKeyStep1.currentState?.validate() ?? false;
//     }

//     if (_currentStep == 1) {
//       // step 2: Kesehatan
//       // Apoteker tidak perlu mengisi data kesehatan
//       if (_isPharmacist) return true;
//       return _formKeyStep2.currentState?.validate() ?? false;
//     }

//     if (_currentStep == 2) {
//       // step 3: Kontak darurat
//       // Apoteker tidak perlu mengisi data kontak darurat
//       if (_isPharmacist) return true;
//       return _formKeyStep3.currentState?.validate() ?? false;
//     }

//     return false;
//   }

//   void _nextStep() async {
//     final valid = _validateCurrentStep();
//     if (!valid) return;

//     // jika belum step terakhir, maju step
//     if (_currentStep < 2) {
//       setState(() => _currentStep++);
//     } else {
//       // step terakhir -> submit
//       await _handleRegisterButton();
//     }
//   }

//   /// Mundur ke step sebelumnya.
//   void _prevStep() {
//     if (_currentStep > 0) {
//       setState(() => _currentStep--);
//     }
//   }

//   /// Menangani proses registrasi ke backend.
//   /// Mengirim data sesuai model [UserModel].
//   // submit register
//   Future<void> _handleRegisterButton() async {
//     try {
//       // tampilan loading
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const AlertDialog(content: CircularProgressIndicator()),
//       );

//       // susun user model dari input
//       final user = UserModel(
//         email: _emailController.text.trim(),
//         phoneNumber: _phoneNumberController.text.trim(),
//         fullName: _fullNameController.text.trim(),

//         // jika apoteker, data kesehatan di-set 0/empty
//         age: _isPharmacist ? 0 : int.tryParse(_ageController.text.trim()) ?? 0,
//         height: _isPharmacist
//             ? 0
//             : double.tryParse(_heightController.text.trim()) ?? 0.0,
//         weight: _isPharmacist
//             ? 0
//             : double.tryParse(_weightController.text.trim()) ?? 0.0,
//         medicalHistory: _isPharmacist ? const [] : _selectedMedicalHistory,
//         gender: gender,
//         drugAllergy: _isPharmacist ? const [] : _selectedDrugAllergy,

//         // jika apoteker, emergency contact default
//         emergencyContact: _isPharmacist
//             ? EmergencyContactModel(
//                 name: '-',
//                 relationship: '-',
//                 phoneNumber: '-',
//               )
//             : EmergencyContactModel(
//                 name: _emergencyContactNameController.text.trim(),
//                 relationship: _emergencyContactRelationshipController.text
//                     .trim(),
//                 phoneNumber: _emergencyContactPhoneNumberController.text.trim(),
//               ),
//       );

//       // panggil api register
//       final response = await _authService.register(
//         user: user,
//         password: _passwordController.text.trim(),
//         pharmacistCode: _isPharmacist
//             ? _pharmacistCodeController.text.trim()
//             : null,
//       );

//       // tutup loading
//       if (!mounted) return;
//       Navigator.of(context).pop();

//       // jika sukses -> pindah ke splash screen
//       if (response.user != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const SplashScreen()),
//         );
//       } else {
//         // gagal register
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Registrasi gagal")));
//       }
//     } catch (e) {
//       // error -> tutup loading lalu tampilkan error
//       if (mounted) Navigator.of(context).pop();
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//       }
//     }
//   }

//   // Data diri
//   Widget _step1DataDiri() {
//     return Form(
//       key: _formKeyStep1,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextFormFieldWithLabel(
//             label: "Nama Lengkap",
//             controller: _fullNameController,
//             validator: (v) => InputValidator.empty(v, "Nama"),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Nomor Telepon Anda",
//             controller: _phoneNumberController,
//             validator: (v) => InputValidator.empty(v, "Nama"),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Email",
//             controller: _emailController,
//             validator: (v) => InputValidator.email(v),
//           ),
//           const SizedBox(height: 10),
//           PasswordFormFieldWithLabel(
//             controller: _passwordController,
//             validator: (v) => InputValidator.minLength(v, "Password", 8),
//           ),
//           const SizedBox(height: 10),
//           GenderRadioForm(
//             selectedGender: gender,
//             onChanged: (value) => setState(() => gender = value),
//           ),

//           // Jika apoteker -> munculkan field kode registrasi apoteker
//           if (_isPharmacist)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10.0),
//               child: TextFormFieldWithLabel(
//                 label: "Kode Registrasi Apoteker",
//                 controller: _pharmacistCodeController,
//                 validator: (value) =>
//                     InputValidator.empty(value, "Kode Registrasi"),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // kesehatan
//   Widget _step2KesehatanFisik() {
//     if (_isPharmacist) {
//       return const Text(
//         "Role apoteker tidak membutuhkan data kesehatan & fisik.",
//         style: TextStyle(fontSize: 14),
//       );
//     }

//     return Form(
//       key: _formKeyStep2,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextFormFieldWithLabel(
//             label: "Umur (Tahun)",
//             controller: _ageController,
//             validator: (v) => InputValidator.empty(v, "Umur"),
//             fieldType: InputFieldType.number,
//             inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//           ),
//           const SizedBox(height: 10),

//           Row(
//             children: [
//               Expanded(
//                 child: TextFormFieldWithLabel(
//                   label: "Tinggi (cm)",
//                   controller: _heightController,
//                   validator: (v) => InputValidator.empty(v, "Tinggi badan"),
//                   fieldType: InputFieldType.number,
//                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: TextFormFieldWithLabel(
//                   label: "Berat (kg)",
//                   controller: _weightController,
//                   validator: (v) => InputValidator.empty(v, "Berat badan"),
//                   fieldType: InputFieldType.number,
//                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           MultiSelectForm(
//             title: "Riwayat Penyakit",
//             hintText: "Masukkan penyakit",
//             selectedItems: _selectedMedicalHistory,
//             onChanged: (newList) =>
//                 setState(() => _selectedMedicalHistory = newList),
//           ),
//           const SizedBox(height: 10),
//           MultiSelectForm(
//             title: "Alergi Obat",
//             hintText: "Masukkan obat",
//             selectedItems: _selectedDrugAllergy,
//             onChanged: (list) => setState(() => _selectedDrugAllergy = list),
//           ),
//         ],
//       ),
//     );
//   }

//   // kontak darurat
//   Widget _step3KontakDarurat() {
//     // Apoteker tidak butuh step ini
//     if (_isPharmacist) {
//       return const Text(
//         "Role apoteker tidak membutuhkan kontak darurat.",
//         style: TextStyle(fontSize: 14),
//       );
//     }

//     return Form(
//       key: _formKeyStep3,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           const Text(
//             "Kontak Darurat",
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Nama Kontak",
//             controller: _emergencyContactNameController,
//             validator: (v) => InputValidator.empty(v, "Nama kontak"),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Hubungan",
//             controller: _emergencyContactRelationshipController,
//             validator: (v) => InputValidator.empty(v, "Hubungan"),
//           ),
//           const SizedBox(height: 10),
//           TextFormFieldWithLabel(
//             label: "Nomor Telepon Kontak",
//             controller: _emergencyContactPhoneNumberController,
//             validator: (v) => InputValidator.phoneNumber(v),
//           ),
//         ],
//       ),
//     );
//   }

//   // build ui
//   @override
//   Widget build(BuildContext context) {
//     final steps = [
//       _StepData(
//         title: "Data Diri",
//         content: _step1DataDiri(),
//         icon: Icons.person_outline_rounded,
//       ),
//       _StepData(
//         title: "Kesehatan & Fisik",
//         content: _step2KesehatanFisik(),
//         icon: Icons.health_and_safety_outlined,
//       ),
//       _StepData(
//         title: "Kontak Darurat",
//         content: _step3KontakDarurat(),
//         icon: Icons.contact_emergency_outlined,
//       ),
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         _HorizontalStepIndicator(
//           steps: steps,
//           currentStep: _currentStep,
//           onStepTapped: (i) {
//             if (i < _currentStep) {
//               setState(() => _currentStep = i);
//             }
//           },
//         ),

//         const SizedBox(height: 24),

//         AnimatedSwitcher(
//           duration: const Duration(milliseconds: 300),
//           transitionBuilder: (child, anim) {
//             final slide =
//                 Tween<Offset>(
//                   begin: const Offset(0.08, 0),
//                   end: Offset.zero,
//                 ).animate(
//                   CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
//                 );
//             return FadeTransition(
//               opacity: anim,
//               child: SlideTransition(position: slide, child: child),
//             );
//           },
//           child: KeyedSubtree(
//             key: ValueKey(_currentStep),
//             child: steps[_currentStep].content,
//           ),
//         ),

//         const SizedBox(height: 24),

//         Row(
//           children: [
//             if (_currentStep > 0) ...[
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: _prevStep,
//                   label: const Text("Kembali"),
//                   icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//             ],

//             Expanded(
//               flex: 2,
//               child: ElevatedButton.icon(
//                 onPressed: _nextStep,
//                 icon: Icon(
//                   _currentStep == 2
//                       ? Icons.check_rounded
//                       : Icons.arrow_forward_ios_rounded,
//                   size: 14,
//                 ),
//                 label: Text(
//                   _currentStep == 2 ? "Daftar Sekarang?" : "Lanjut",
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   backgroundColor: const Color(0xFF0A7AC1),
//                   foregroundColor: Colors.white,
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 16),
//         const AuthRedirectText(isLogin: false),
//       ],
//     );
//   }
// }

// class _StepData {
//   final String title;
//   final IconData icon;
//   final Widget content;

//   const _StepData({
//     required this.title,
//     required this.icon,
//     required this.content,
//   });
// }

// class _HorizontalStepIndicator extends StatelessWidget {
//   final List<_StepData> steps;
//   final int currentStep;
//   final ValueChanged<int> onStepTapped;

//   const _HorizontalStepIndicator({
//     required this.steps,
//     required this.currentStep,
//     required this.onStepTapped,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: List.generate(steps.length * 2 - 1, (i) {
//         if (i.isOdd) {
//           final stepIndex = i ~/ 2;
//           final isDone = currentStep > stepIndex;
//           return Expanded(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 400),
//               curve: Curves.easeOutCubic,
//               height: 2,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(2),
//                 color: isDone ? const Color(0xFF0A7AC1) : Colors.grey.shade200,
//               ),
//             ),
//           );
//         }

//         final stepIndex = i ~/ 2;
//         final isActive = currentStep == stepIndex;
//         final isDone = currentStep > stepIndex;
//         final isTappable = currentStep < stepIndex;

//         return GestureDetector(
//           onTap: isTappable ? () => onStepTapped(stepIndex) : null,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInBack,
//                 width: isActive ? 44 : 36,
//                 height: isActive ? 44 : 36,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isDone
//                       ? const Color(0xFF0A7AC1)
//                       : Colors.grey.shade100,
//                   border: Border.all(
//                     color: isActive || isDone
//                         ? const Color(0xFF0A7AC1)
//                         : Colors.grey.shade300,
//                   ),
//                   boxShadow: isActive
//                       ? [
//                           BoxShadow(
//                             color: const Color(0xFF0A7AC1).withOpacity(0.25),
//                             blurRadius: 12,
//                             offset: const Offset(0, 4),
//                           ),
//                         ]
//                       : [],
//                 ),
//                 child: Center(
//                   child: AnimatedSwitcher(
//                     duration: const Duration(microseconds: 200),
//                     child: isDone
//                         ? const Icon(
//                             Icons.check_rounded,
//                             key: ValueKey('check'),
//                             color: Colors.white,
//                             size: 18,
//                           )
//                         : Icon(
//                             steps[stepIndex].icon,
//                             key: ValueKey('icon_$stepIndex'),
//                             size: isActive ? 20 : 16,
//                             color: isActive
//                                 ? Colors.white
//                                 : Colors.grey.shade400,
//                           ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 6),

//               AnimatedDefaultTextStyle(
//                 duration: const Duration(milliseconds: 200),
//                 style: TextStyle(
//                   fontSize: isActive ? 11 : 10,
//                   fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//                   color: isActive || isDone
//                       ? const Color(0xFF0A7AC1)
//                       : Colors.grey.shade400,
//                 ),
//                 child: Text(steps[stepIndex].title),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }

// class _StepSkippedCard extends StatelessWidget {
//   final IconData icon;
//   final String message;

//   const _StepSkippedCard({required this.icon, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.blue.shade100),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: const Color(0xFF0A7AC1).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: const Color(0xFF0A7AC1), size: 20),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Langkah dilewati",
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF0A7AC1),
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   message,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.blue.shade700,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/emergency_contact_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/remote/auth_service.dart';
import '../../../../utils/input_validator.dart';
import 'splash_screen.dart';
import 'auth_redirect_text.dart';
import 'gender_radio_form.dart';
import 'multi_select_form.dart';
import 'password_form_field_with_label.dart';
import 'text_form_field_with_label.dart';

enum RegisterRole { patient, pharmacist }

class RegisterForm extends StatefulWidget {
  final RegisterRole role;
  const RegisterForm({super.key, this.role = RegisterRole.patient});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // ── State ──────────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isLoading = false;

  // PageController untuk animasi slide antar step
  final _pageController = PageController();

  // FormKey — dibuat sebagai final field agar tidak pernah reset
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactRelationshipController = TextEditingController();
  final _emergencyContactPhoneNumberController = TextEditingController();
  DateTime? _birthDate;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _pharmacistCodeController = TextEditingController();

  final _authService = AuthService();

  List<String> _selectedMedicalHistory = [];
  List<String> _selectedDrugAllergy = [];
  String _gender = "male";

  bool get _isPharmacist => widget.role == RegisterRole.pharmacist;

  // ── Konstanta ───────────────────────────────────────────────────────────
  static const _stepColors = [
    Color(0xFF0A7AC1), // biru
    Color(0xFF059669), // hijau
    Color(0xFFD97706), // amber
  ];
  static const _stepTitles = ["Data Diri", "Kesehatan", "Kontak"];
  static const _stepIcons = [
    Icons.person_outline_rounded,
    Icons.favorite_outline_rounded,
    Icons.contact_phone_outlined,
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactRelationshipController.dispose();
    _emergencyContactPhoneNumberController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pharmacistCodeController.dispose();
    super.dispose();
  }

  // ── Validasi ────────────────────────────────────────────────────────────
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKeyStep1.currentState?.validate() ?? false;
      case 1:
        if (_isPharmacist) return true;
        bool formValid = _formKeyStep2.currentState?.validate() ?? false;
        if (_birthDate == null) {
          _showSnackBar("Tanggal lahir wajib diisi.", isError: true);
          return false;
        }
        return formValid;
      case 2:
        if (_isPharmacist) return true;
        return _formKeyStep3.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  // ── Navigasi Step ────────────────────────────────────────────────────────
  Future<void> _nextStep() async {
    if (_isLoading) return;
    if (!_validateCurrentStep()) return;

    if (_currentStep < 2) {
      // Tutup keyboard sebelum pindah
      FocusScope.of(context).unfocus();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _handleRegister();
    }
  }

  Future<void> _prevStep() async {
    if (_isLoading || _currentStep == 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _goToStep(int index) async {
    if (_isLoading || index >= _currentStep) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final user = UserModel(
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        birthDate: _isPharmacist ? null : _birthDate,
        height: _isPharmacist
            ? 0
            : double.tryParse(_heightController.text.trim()) ?? 0.0,
        weight: _isPharmacist
            ? 0
            : double.tryParse(_weightController.text.trim()) ?? 0.0,
        medicalHistory: _isPharmacist ? const [] : _selectedMedicalHistory,
        gender: _gender,
        drugAllergy: _isPharmacist ? const [] : _selectedDrugAllergy,
        emergencyContacts: _isPharmacist
            ? []
            : [
                EmergencyContactModel(
                  name: _emergencyContactNameController.text.trim(),
                  relationship: _emergencyContactRelationshipController.text.trim(),
                  phoneNumber: _emergencyContactPhoneNumberController.text.trim(),
                )
              ],
      );

      final response = await _authService.register(
        user: user,
        password: _passwordController.text.trim(),
        pharmacistCode: _isPharmacist
            ? _pharmacistCodeController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
        );
      } else {
        _showSnackBar("Registrasi gagal. Silakan coba lagi.", isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final activeColor = _stepColors[_currentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Step Indicator ───────────────────────────────────────────────
        _StepIndicator(
          titles: _stepTitles,
          icons: _stepIcons,
          colors: _stepColors,
          currentStep: _currentStep,
          onTap: _goToStep,
        ),

        const SizedBox(height: 20),

        // ── Konten Step via PageView ─────────────────────────────────────
        // NeverScrollableScrollPhysics — scroll dikendalikan oleh controller
        // sehingga tidak bisa di-swipe manual (cegah bypass validasi)
        SizedBox(
          // tinggi dikira dari konten terpanjang; gunakan intrinsic agar fleksibel
          child: _PageViewContent(
            controller: _pageController,
            pages: [
              // Step 1
              _Step1DataDiri(
                formKey: _formKeyStep1,
                fullNameController: _fullNameController,
                phoneController: _phoneNumberController,
                emailController: _emailController,
                passwordController: _passwordController,
                pharmacistCodeController: _pharmacistCodeController,
                isPharmacist: _isPharmacist,
                gender: _gender,
                onGenderChanged: (v) => setState(() => _gender = v),
              ),
              // Step 2
              _Step2Kesehatan(
                formKey: _formKeyStep2,
                isPharmacist: _isPharmacist,
                birthDate: _birthDate,
                onBirthDateChanged: (d) => setState(() => _birthDate = d),
                heightController: _heightController,
                weightController: _weightController,
                selectedMedicalHistory: _selectedMedicalHistory,
                selectedDrugAllergy: _selectedDrugAllergy,
                onMedicalHistoryChanged: (v) =>
                    setState(() => _selectedMedicalHistory = v),
                onDrugAllergyChanged: (v) =>
                    setState(() => _selectedDrugAllergy = v),
              ),
              // Step 3
              _Step3KontakDarurat(
                formKey: _formKeyStep3,
                isPharmacist: _isPharmacist,
                nameController: _emergencyContactNameController,
                relationshipController: _emergencyContactRelationshipController,
                phoneController: _emergencyContactPhoneNumberController,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Tombol Navigasi ──────────────────────────────────────────────
        Row(
          children: [
            // Tombol Kembali — muncul di step > 0
            if (_currentStep > 0) ...[
              SizedBox(
                width: 110,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_back_ios_new_rounded, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "Kembali",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Tombol Lanjut / Daftar
            Expanded(
              child: SizedBox(
                height: 50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _nextStep,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep == 2
                                        ? "Daftar Sekarang"
                                        : "Lanjut",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _currentStep == 2
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const AuthRedirectText(isLogin: false),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE VIEW WRAPPER
// Mengukur tinggi masing-masing halaman secara dinamis
// ─────────────────────────────────────────────────────────────────────────────

class _PageViewContent extends StatefulWidget {
  final PageController controller;
  final List<Widget> pages;

  const _PageViewContent({required this.controller, required this.pages});

  @override
  State<_PageViewContent> createState() => _PageViewContentState();
}

class _PageViewContentState extends State<_PageViewContent> {
  // Tinggi tiap halaman disimpan agar PageView bisa menyesuaikan
  final Map<int, double> _heights = {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = widget.controller.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = _heights[_currentPage] ?? 400.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: height,
      child: PageView.builder(
        controller: widget.controller,
        // Nonaktifkan swipe manual agar user tidak bisa lewati validasi
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.pages.length,
        itemBuilder: (context, index) {
          return _MeasuredPage(
            onHeightMeasured: (h) {
              if (_heights[index] != h) {
                // Update tinggi tanpa rebuild seluruh tree
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _heights[index] = h);
                });
              }
            },
            child: widget.pages[index],
          );
        },
      ),
    );
  }
}

/// Mengukur tinggi child setelah layout selesai
class _MeasuredPage extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onHeightMeasured;

  const _MeasuredPage({required this.child, required this.onHeightMeasured});

  @override
  State<_MeasuredPage> createState() => _MeasuredPageState();
}

class _MeasuredPageState extends State<_MeasuredPage> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      widget.onHeightMeasured(box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Scroll di dalam page jika konten melebihi layar
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(key: _key, width: double.infinity, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final List<String> titles;
  final List<IconData> icons;
  final List<Color> colors;
  final int currentStep;
  final ValueChanged<int> onTap;

  const _StepIndicator({
    required this.titles,
    required this.icons,
    required this.colors,
    required this.currentStep,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(titles.length * 2 - 1, (i) {
        // ── Garis penghubung ─────────────────────────────────────────
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isDone = currentStep > stepIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: isDone
                      ? LinearGradient(
                          colors: [colors[stepIndex], colors[stepIndex + 1]],
                        )
                      : null,
                  color: isDone ? null : Colors.grey.shade200,
                ),
              ),
            ),
          );
        }

        // ── Lingkaran step ───────────────────────────────────────────
        final stepIndex = i ~/ 2;
        final isActive = currentStep == stepIndex;
        final isDone = currentStep > stepIndex;
        final color = colors[stepIndex];

        return GestureDetector(
          onTap: isDone ? () => onTap(stepIndex) : null,
          child: SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  width: isActive ? 42 : 34,
                  height: isActive ? 42 : 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive || isDone ? color : Colors.grey.shade100,
                    border: Border.all(
                      color: isActive || isDone ? color : Colors.grey.shade300,
                      width: isActive ? 2.5 : 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: isDone
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('done'),
                              color: Colors.white,
                              size: 16,
                            )
                          : Icon(
                              icons[stepIndex],
                              key: ValueKey('icon_$stepIndex'),
                              size: isActive ? 20 : 16,
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade400,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  titles[stepIndex],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive || isDone ? color : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Data Diri
// ─────────────────────────────────────────────────────────────────────────────

class _Step1DataDiri extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController pharmacistCodeController;
  final bool isPharmacist;
  final String gender;
  final ValueChanged<String> onGenderChanged;

  const _Step1DataDiri({
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.pharmacistCodeController,
    required this.isPharmacist,
    required this.gender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.person_outline_rounded,
            title: "Data Diri",
            subtitle: "Isi identitas dasar Anda dengan benar",
            color: const Color(0xFF0A7AC1),
          ),
          const SizedBox(height: 16),
          TextFormFieldWithLabel(
            label: "Nama Lengkap",
            controller: fullNameController,
            validator: (v) => InputValidator.empty(v, "Nama"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Nomor Telepon",
            controller: phoneController,
            fieldType: InputFieldType.phone,
            validator: (v) => InputValidator.phoneNumber(v),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Email",
            controller: emailController,
            fieldType: InputFieldType.email,
            validator: (v) => InputValidator.email(v),
          ),
          const SizedBox(height: 10),
          PasswordFormFieldWithLabel(
            controller: passwordController,
            showStrength: true,
            validator: (v) => InputValidator.minLength(v, "Password", 8),
          ),
          const SizedBox(height: 12),
          GenderRadioForm(selectedGender: gender, onChanged: onGenderChanged),
          if (isPharmacist) ...[
            const SizedBox(height: 10),
            TextFormFieldWithLabel(
              label: "Kode Registrasi Apoteker",
              controller: pharmacistCodeController,
              validator: (v) => InputValidator.empty(v, "Kode Registrasi"),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Kesehatan & Fisik
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Kesehatan extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isPharmacist;
  final DateTime? birthDate;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final List<String> selectedMedicalHistory;
  final List<String> selectedDrugAllergy;
  final ValueChanged<List<String>> onMedicalHistoryChanged;
  final ValueChanged<List<String>> onDrugAllergyChanged;

  const _Step2Kesehatan({
    required this.formKey,
    required this.isPharmacist,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.heightController,
    required this.weightController,
    required this.selectedMedicalHistory,
    required this.selectedDrugAllergy,
    required this.onMedicalHistoryChanged,
    required this.onDrugAllergyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isPharmacist) {
      return _SkippedCard(
        icon: Icons.favorite_outline_rounded,
        color: const Color(0xFF059669),
        message: "Apoteker tidak membutuhkan data kesehatan & fisik.",
      );
    }
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.favorite_outline_rounded,
            title: "Kesehatan & Fisik",
            subtitle: "Membantu pemantauan kondisi Anda",
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    // Cek context dari FormKey karena StatelessWidget tidak punya context navigator
                    final ctx = formKey.currentContext ?? context;
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: birthDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      onBirthDateChanged(date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          birthDate != null 
                              ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
                              : 'Tanggal Lahir',
                          style: TextStyle(
                            color: birthDate != null ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormFieldWithLabel(
                  label: "Tinggi (cm)",
                  controller: heightController,
                  validator: (v) => InputValidator.empty(v, "Tinggi badan"),
                  fieldType: InputFieldType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormFieldWithLabel(
                  label: "Berat (kg)",
                  controller: weightController,
                  validator: (v) => InputValidator.empty(v, "Berat badan"),
                  fieldType: InputFieldType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MultiSelectForm(
            title: "Riwayat Penyakit",
            hintText: "Masukkan penyakit",
            selectedItems: selectedMedicalHistory,
            onChanged: onMedicalHistoryChanged,
          ),
          const SizedBox(height: 10),
          MultiSelectForm(
            title: "Alergi Obat",
            hintText: "Masukkan obat",
            selectedItems: selectedDrugAllergy,
            onChanged: onDrugAllergyChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — Kontak Darurat
// ─────────────────────────────────────────────────────────────────────────────

class _Step3KontakDarurat extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isPharmacist;
  final TextEditingController nameController;
  final TextEditingController relationshipController;
  final TextEditingController phoneController;

  const _Step3KontakDarurat({
    required this.formKey,
    required this.isPharmacist,
    required this.nameController,
    required this.relationshipController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    if (isPharmacist) {
      return _SkippedCard(
        icon: Icons.contact_phone_outlined,
        color: const Color(0xFFD97706),
        message: "Apoteker tidak membutuhkan kontak darurat.",
      );
    }
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.contact_phone_outlined,
            title: "Kontak Darurat",
            subtitle: "Dihubungi jika terjadi kondisi darurat",
            color: const Color(0xFFD97706),
          ),
          const SizedBox(height: 16),
          TextFormFieldWithLabel(
            label: "Nama Kontak",
            controller: nameController,
            validator: (v) => InputValidator.empty(v, "Nama kontak"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Hubungan (misal: Ibu, Suami)",
            controller: relationshipController,
            validator: (v) => InputValidator.empty(v, "Hubungan"),
          ),
          const SizedBox(height: 10),
          TextFormFieldWithLabel(
            label: "Nomor Telepon Kontak",
            controller: phoneController,
            fieldType: InputFieldType.phone,
            validator: (v) => InputValidator.phoneNumber(v),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkippedCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _SkippedCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Langkah dilewati",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    height: 1.4,
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
