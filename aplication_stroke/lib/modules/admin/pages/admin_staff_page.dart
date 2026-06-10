import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_service.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Staff',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Buat undangan registrasi untuk apoteker dan dokter baru',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: TabBar(
            controller: _tab,
            labelColor: const Color(0xFF0A7AC1),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF0A7AC1),
            tabs: const [
              Tab(
                icon: Icon(Icons.local_pharmacy_outlined),
                text: 'Apoteker',
              ),
              Tab(
                icon: Icon(Icons.medical_services_outlined),
                text: 'Dokter',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _PharmacistRegisterForm(),
              _DoctorRegisterForm(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PharmacistRegisterForm extends StatefulWidget {
  const _PharmacistRegisterForm();

  @override
  State<_PharmacistRegisterForm> createState() =>
      _PharmacistRegisterFormState();
}

class _PharmacistRegisterFormState extends State<_PharmacistRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _license = TextEditingController();
  final _pharmacy = TextEditingController();
  final _admin = AdminService();

  bool _loading = false;
  String? _token;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _license.dispose();
    _pharmacy.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _token = null;
    });
    try {
      final token = await _admin.createPharmacistInvitation(
        name: _name.text,
        email: _email.text,
        licenseNumber: _license.text,
        pharmacyName: _pharmacy.text,
      );
      if (!mounted) return;
      setState(() => _token = token);
      _name.clear();
      _email.clear();
      _license.clear();
      _pharmacy.clear();
      _formKey.currentState?.reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _StaffFormCard(
              title: 'Undangan Apoteker Baru',
              subtitle:
                  'Apoteker menggunakan kode undangan saat registrasi di aplikasi mobile.',
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_name, 'Nama lengkap', Icons.person_outline),
                    const SizedBox(height: 14),
                    _field(
                      _email,
                      'Email',
                      Icons.email_outlined,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _license,
                      'Nomor SIPA / STRA',
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _pharmacy,
                      'Nama apotek',
                      Icons.store_outlined,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Buat Undangan Apoteker'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _TokenResultCard(
              token: _token,
              roleLabel: 'Apoteker',
              color: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorRegisterForm extends StatefulWidget {
  const _DoctorRegisterForm();

  @override
  State<_DoctorRegisterForm> createState() => _DoctorRegisterFormState();
}

class _DoctorRegisterFormState extends State<_DoctorRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _license = TextEditingController();
  final _specialization = TextEditingController();
  final _hospital = TextEditingController();
  final _admin = AdminService();

  bool _loading = false;
  String? _token;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _license.dispose();
    _specialization.dispose();
    _hospital.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _token = null;
    });
    try {
      final token = await _admin.createDoctorInvitation(
        name: _name.text,
        email: _email.text,
        licenseNumber: _license.text,
        specialization: _specialization.text,
        hospitalName: _hospital.text,
      );
      if (!mounted) return;
      setState(() => _token = token);
      _name.clear();
      _email.clear();
      _license.clear();
      _specialization.clear();
      _hospital.clear();
      _formKey.currentState?.reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _StaffFormCard(
              title: 'Undangan Dokter Baru',
              subtitle:
                  'Dokter menggunakan kode undangan saat registrasi di aplikasi mobile.',
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_name, 'Nama lengkap', Icons.person_outline),
                    const SizedBox(height: 14),
                    _field(
                      _email,
                      'Email',
                      Icons.email_outlined,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _field(_license, 'Nomor STR', Icons.badge_outlined),
                    const SizedBox(height: 14),
                    _field(
                      _specialization,
                      'Spesialisasi',
                      Icons.medical_information_outlined,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _hospital,
                      'Rumah sakit / klinik',
                      Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Buat Undangan Dokter'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _TokenResultCard(
              token: _token,
              roleLabel: 'Dokter',
              color: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _field(
  TextEditingController c,
  String label,
  IconData icon, {
  TextInputType type = TextInputType.text,
}) {
  return TextFormField(
    controller: c,
    keyboardType: type,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
      if (label == 'Email' && !v.contains('@')) return 'Email tidak valid';
      return null;
    },
  );
}

class _StaffFormCard extends StatelessWidget {
  const _StaffFormCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _TokenResultCard extends StatelessWidget {
  const _TokenResultCard({
    required this.token,
    required this.roleLabel,
    required this.color,
  });

  final String? token;
  final String roleLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.vpn_key_rounded, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            'Kode Undangan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (token == null)
            Text(
              'Kode akan muncul setelah undangan $roleLabel berhasil dibuat.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            )
          else ...[
            Text(
              'Bagikan kode ini ke $roleLabel untuk registrasi:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color),
              ),
              child: Text(
                token!,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode disalin ke clipboard')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Salin Kode'),
            ),
          ],
        ],
      ),
    );
  }
}
