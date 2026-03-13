import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/emergency_contact_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/remote/auth_service.dart';
import '../../../../utils/input_validator.dart';
import '../../../../widgets/pop_up_loading.dart';
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
  // ── State ───────────────────────────────────────────────────────────────
  int _currentStep = 0;
  bool _isLoading = false;

  // FormKey — TIDAK pernah direset agar state form tetap terjaga
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
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _pharmacistCodeController = TextEditingController();

  DateTime? _birthDate;
  final _authService = AuthService();

  List<String> _selectedMedicalHistory = [];
  List<String> _selectedDrugAllergy = [];
  String _gender = "male";

  bool get _isPharmacist => widget.role == RegisterRole.pharmacist;

  // ── Konstanta ────────────────────────────────────────────────────────────
  static const _stepColors = [
    Color(0xFF0A7AC1),
    Color(0xFF059669),
    Color(0xFFD97706),
  ];
  static const _stepTitles = ["Data Diri", "Kesehatan", "Kontak"];
  static const _stepIcons = [
    Icons.person_outline_rounded,
    Icons.favorite_outline_rounded,
    Icons.contact_phone_outlined,
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void dispose() {
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

  // ── Validasi ─────────────────────────────────────────────────────────────
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKeyStep1.currentState?.validate() ?? false;
      case 1:
        if (_isPharmacist) return true;
        if (!(_formKeyStep2.currentState?.validate() ?? false)) return false;
        if (_birthDate == null) {
          _showSnackBar("Tanggal lahir wajib diisi.", isError: true);
          return false;
        }
        return true;
      case 2:
        if (_isPharmacist) return true;
        return _formKeyStep3.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  // ── Navigasi ─────────────────────────────────────────────────────────────
  Future<void> _nextStep() async {
    if (_isLoading) return;
    if (!_validateCurrentStep()) return;
    FocusScope.of(context).unfocus();
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      await _handleRegister();
    }
  }

  void _prevStep() {
    if (_isLoading || _currentStep == 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep--);
  }

  void _goToStep(int index) {
    if (_isLoading || index >= _currentStep) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = index);
  }

  // ── Submit ────────────────────────────────────────────────────────────────
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
            : (double.tryParse(_heightController.text.trim()) ?? 0.0),
        weight: _isPharmacist
            ? 0
            : (double.tryParse(_weightController.text.trim()) ?? 0.0),
        medicalHistory: _isPharmacist ? const [] : _selectedMedicalHistory,
        gender: _gender,
        drugAllergy: _isPharmacist ? const [] : _selectedDrugAllergy,
        emergencyContacts: _isPharmacist
            ? []
            : [
                EmergencyContactModel(
                  name: _emergencyContactNameController.text.trim(),
                  relationship: _emergencyContactRelationshipController.text
                      .trim(),
                  phoneNumber: _emergencyContactPhoneNumberController.text
                      .trim(),
                ),
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final activeColor = _stepColors[_currentStep];

    // Konten per step — dirender dengan AnimatedSwitcher
    // sehingga tinggi otomatis menyesuaikan tanpa perlu scroll
    final steps = [
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
        onDrugAllergyChanged: (v) => setState(() => _selectedDrugAllergy = v),
      ),
      _Step3KontakDarurat(
        formKey: _formKeyStep3,
        isPharmacist: _isPharmacist,
        nameController: _emergencyContactNameController,
        relationshipController: _emergencyContactRelationshipController,
        phoneController: _emergencyContactPhoneNumberController,
      ),
    ];

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Step Indicator ──────────────────────────────────────────────
            _StepIndicator(
              titles: _stepTitles,
              icons: _stepIcons,
              colors: _stepColors,
              currentStep: _currentStep,
              onTap: _goToStep,
            ),

            const SizedBox(height: 20),

            // ── Konten Step — AnimatedSwitcher (TANPA PageView) ─────────────
            // Kunci: tinggi mengikuti konten secara alami, tidak perlu scroll
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                // NOTE: `anim` already has the curve applied by AnimatedSwitcher.
                // Do NOT wrap it in another CurvedAnimation — that causes assertion
                // errors when values go outside [0.0, 1.0].
                final slide = Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(anim);
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: steps[_currentStep],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tombol Navigasi ─────────────────────────────────────────────
            Row(
              children: [
                // Tombol Kembali
                if (_currentStep > 0) ...[
                  _BackButton(onPressed: _isLoading ? null : _prevStep),
                  const SizedBox(width: 10),
                ],

                // Tombol Lanjut / Daftar
                Expanded(
                  child: _NextButton(
                    label: _currentStep == 2 ? "Daftar Sekarang" : "Lanjut",
                    icon: _currentStep == 2
                        ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: activeColor,
                    isLoading: _isLoading,
                    onPressed: _nextStep,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const AuthRedirectText(isLogin: false),
          ],
        ),
        // ── PopUp Loading ───────────────────────────────────────────────
        if (_isLoading) const PopUpLoading(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOMBOL NAVIGASI
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _BackButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: 100,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 13,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              "Kembali",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _NextButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: isLoading
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
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Icon(icon, size: 15, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ),
      ),
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
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isDone = currentStep > stepIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
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

        final stepIndex = i ~/ 2;
        final isActive = currentStep == stepIndex;
        final isDone = currentStep > stepIndex;
        final color = colors[stepIndex];

        return GestureDetector(
          onTap: isDone ? () => onTap(stepIndex) : null,
          child: SizedBox(
            width: 58,
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),

          // Tanggal Lahir
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: birthDate ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) onBirthDateChanged(date);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    color: birthDate != null
                        ? const Color(0xFF059669)
                        : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    birthDate != null
                        ? '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'
                        : 'Tanggal Lahir',
                    style: TextStyle(
                      fontSize: 15,
                      color: birthDate != null
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade400,
                      fontWeight: birthDate != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
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
          const SizedBox(height: 14),
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
