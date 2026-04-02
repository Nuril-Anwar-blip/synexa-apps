// ====================================================================
// File: profile_screen.dart
// Layar Profil Pengguna — Redesigned with full settings integration
// ====================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase/supabase_client.dart';
import '../../models/user_model.dart';
import '../../extensions/user_model_extension.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'edit_profile_screen.dart';
import '../../auth/login_screen.dart';
import '../pairing_scanner/pairing_scanner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? userModel;
  bool isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final response = await SupabaseManager.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          if (response != null) userModel = UserModel.fromMap(response);
          isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      debugPrint("❌ LOG FETCH ERROR: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showSnack('Gagal memuat profil: $e');
      }
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> dataForSupabase = {
      'full_name': data['name'],
      'phone_number': data['phoneNumber'],
      'birth_date': data['birthDate'] != null
          ? (data['birthDate'] as DateTime).toIso8601String()
          : null,
      'gender': data['gender'],
      'weight': data['weight'],
      'height': data['height'],
      'medical_history': data['medicalHistory'],
      'drug_allergy': data['drugAllergy'],
      'emergency_contact':
          data['emergencyContacts']
              ?.map(
                (e) => {
                  'name': e.name,
                  'phone_number': e.phoneNumber,
                  'relationship': e.relationship ?? '',
                },
              )
              .toList() ??
          [],
    };

    if (data['photoUrl'] != null && (data['photoUrl'] as String).isNotEmpty) {
      dataForSupabase['photo_url'] = data['photoUrl'];
    }

    try {
      await Supabase.instance.client
          .from('users')
          .update(dataForSupabase)
          .eq('id', user.id);
    } catch (e) {
      if (mounted) _showSnack('Gagal memperbarui profil: $e');
    }
    await _fetchProfile();
  }

  Future<void> _openEditProfile() async {
    if (userModel == null) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => EditProfileScreen(
          name: userModel?.fullName ?? '',
          phoneNumber: userModel?.phoneNumber ?? '',
          birthDate: userModel?.birthDate,
          gender: userModel?.gender,
          weight: userModel?.weight,
          height: userModel?.height,
          medicalHistory: userModel?.medicalHistory.join(', '),
          drugAllergy: userModel?.drugAllergy.join(', '),
          emergencyContacts: userModel?.emergencyContacts ?? [],
          photoUrl: userModel?.photoUrl,
        ),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (result != null) await _updateProfile(result);
  }

  Future<void> _confirmLogout() async {
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          lang.translate({
            'id': 'Konfirmasi Logout',
            'en': 'Confirm Logout',
            'ms': 'Pengesahan Log Keluar',
          }),
        ),
        content: Text(
          lang.translate({
            'id': 'Apakah Anda yakin ingin keluar?',
            'en': 'Are you sure you want to sign out?',
            'ms': 'Adakah anda pasti mahu log keluar?',
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              lang.translate({'id': 'Tidak', 'en': 'No', 'ms': 'Tidak'}),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              lang.translate({
                'id': 'Ya, Keluar',
                'en': 'Yes, Logout',
                'ms': 'Ya, Keluar',
              }),
            ),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showQuickSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuickSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageProvider>();
    final themeP = context.watch<ThemeProvider>();
    final isDark = themeP.isDarkMode;
    final fs = themeP.fontSize;

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.teal.shade400),
              const SizedBox(height: 16),
              Text(
                lang.translate({
                  'id': 'Memuat profil...',
                  'en': 'Loading profile...',
                  'ms': 'Memuatkan profil...',
                }),
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1923)
          : const Color(0xFFF4F7FB),
      body: userModel == null
          ? _buildEmptyState(lang)
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _fetchProfile,
                color: Colors.teal,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    _buildSliverAppBar(isDark, lang, fs),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildQuickStats(userModel!, isDark, fs, lang),
                            const SizedBox(height: 20),
                            _buildInfoCard(
                              title: lang.translate({
                                'id': 'Detail Pribadi',
                                'en': 'Personal Details',
                                'ms': 'Butiran Peribadi',
                              }),
                              icon: Icons.badge_outlined,
                              isDark: isDark,
                              fs: fs,
                              children: [
                                _infoRow(
                                  lang.translate({
                                    'id': 'Telepon',
                                    'en': 'Phone',
                                    'ms': 'Telefon',
                                  }),
                                  userModel!.phoneNumberUI,
                                  Icons.phone_outlined,
                                  isDark,
                                  fs,
                                ),
                                _infoRow(
                                  'Email',
                                  userModel!.email,
                                  Icons.email_outlined,
                                  isDark,
                                  fs,
                                ),
                                _infoRow(
                                  lang.translate({
                                    'id': 'Jenis Kelamin',
                                    'en': 'Gender',
                                    'ms': 'Jantina',
                                  }),
                                  userModel!.genderUI,
                                  Icons.wc_outlined,
                                  isDark,
                                  fs,
                                ),
                                _infoRow(
                                  lang.translate({
                                    'id': 'Tanggal Lahir',
                                    'en': 'Birth Date',
                                    'ms': 'Tarikh Lahir',
                                  }),
                                  _formatBirthDate(userModel!.birthDate, lang),
                                  Icons.cake_outlined,
                                  isDark,
                                  fs,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              title: lang.translate({
                                'id': 'Kondisi Medis',
                                'en': 'Medical Condition',
                                'ms': 'Kondisi Perubatan',
                              }),
                              icon: Icons.medical_services_outlined,
                              isDark: isDark,
                              fs: fs,
                              children: [
                                _chipGroupRow(
                                  label: lang.translate({
                                    'id': 'Riwayat Penyakit',
                                    'en': 'Medical History',
                                    'ms': 'Sejarah Perubatan',
                                  }),
                                  items: userModel!.medicalHistory
                                      .where((e) => e.trim().isNotEmpty)
                                      .toList(),
                                  color: Colors.orange,
                                  isDark: isDark,
                                  fs: fs,
                                ),
                                _chipGroupRow(
                                  label: lang.translate({
                                    'id': 'Alergi Obat',
                                    'en': 'Drug Allergy',
                                    'ms': 'Alergi Ubat',
                                  }),
                                  items: userModel!.drugAllergy
                                      .where((e) => e.trim().isNotEmpty)
                                      .toList(),
                                  color: Colors.red,
                                  isDark: isDark,
                                  fs: fs,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildEmergencyCard(isDark, fs, lang),
                            const SizedBox(height: 20),
                            _buildActionButton(
                              icon: Icons.watch_outlined,
                              title: lang.translate({
                                'id': 'Pair Smartwatch',
                                'en': 'Pair Smartwatch',
                                'ms': 'Pasang Smartwatch',
                              }),
                              subtitle: lang.translate({
                                'id': 'Hubungkan perangkat wearable',
                                'en': 'Connect wearable device',
                                'ms': 'Sambungkan peranti boleh pakai',
                              }),
                              gradient: [
                                Colors.blue.shade400,
                                Colors.indigo.shade400,
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PairingScannerScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.logout_rounded,
                              title: lang.translate({
                                'id': 'Logout',
                                'en': 'Logout',
                                'ms': 'Log Keluar',
                              }),
                              subtitle: lang.translate({
                                'id': 'Keluar dari akun Anda',
                                'en': 'Sign out securely',
                                'ms': 'Keluar dengan selamat',
                              }),
                              gradient: [
                                Colors.red.shade400,
                                Colors.pink.shade400,
                              ],
                              onTap: _confirmLogout,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, LanguageProvider lang, double fs) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F1923) : Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Quick Settings',
          onPressed: _showQuickSettings,
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: _openEditProfile,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _ProfileHeroCard(
          name: userModel!.fullNameUI,
          email: userModel!.email,
          phone: userModel!.phoneNumberUI,
          photoUrl: userModel!.photoUrl,
          onEdit: _openEditProfile,
          isDark: isDark,
          fs: fs,
          lang: lang,
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate({
                'id': 'Data profil tidak ditemukan',
                'en': 'Profile data not found',
                'ms': 'Data profil tidak dijumpai',
              }),
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate({
                'id': 'Mohon lengkapi profil Anda.',
                'en': 'Please complete your profile.',
                'ms': 'Sila lengkapkan profil anda.',
              }),
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    UserModel user,
    bool isDark,
    double fs,
    LanguageProvider lang,
  ) {
    // FIX: Kalkulasi umur yang benar
    final age = _calculateAge(user.birthDate);
    final stats = [
      (
        label: lang.translate({'id': 'Umur', 'en': 'Age', 'ms': 'Umur'}),
        value: age > 0 ? '$age th' : '-',
        icon: Icons.cake_outlined,
        color: Colors.purple,
      ),
      (
        label: lang.translate({'id': 'Tinggi', 'en': 'Height', 'ms': 'Tinggi'}),
        value: _formatMeasure(user.height, 'cm'),
        icon: Icons.height,
        color: Colors.teal,
      ),
      (
        label: lang.translate({'id': 'Berat', 'en': 'Weight', 'ms': 'Berat'}),
        value: _formatMeasure(user.weight, 'kg'),
        icon: Icons.monitor_weight_outlined,
        color: Colors.orange,
      ),
    ];

    return Row(
      children: stats
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Container(
                margin: EdgeInsets.only(left: e.key > 0 ? 10 : 0),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2636) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: e.value.color.withOpacity(isDark ? 0.15 : 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: e.value.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(e.value.icon, color: e.value.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.value.value,
                      style: TextStyle(
                        fontSize: 18 * fs,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 11 * fs,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required double fs,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2636) : Colors.white,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.teal.shade400, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16 * fs,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    IconData icon,
    bool isDark,
    double fs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal.shade300),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11 * fs,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 14 * fs,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipGroupRow({
    required String label,
    required List<String> items,
    required Color color,
    required bool isDark,
    required double fs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * fs,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          items.isEmpty
              ? Text(
                  '-',
                  style: TextStyle(
                    fontSize: 14 * fs,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: items
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 12 * fs,
                              color: color.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(bool isDark, double fs, LanguageProvider lang) {
    final contacts = userModel?.emergencyContacts ?? [];
    final first = contacts.isNotEmpty ? contacts.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emergency_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                lang.translate({
                  'id': 'Kontak Darurat',
                  'en': 'Emergency Contact',
                  'ms': 'Kenalan Kecemasan',
                }),
                style: TextStyle(
                  fontSize: 16 * fs,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (first == null || first.name.isEmpty)
            Text(
              lang.translate({
                'id': 'Belum diisi',
                'en': 'Not set yet',
                'ms': 'Belum ditetapkan',
              }),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14 * fs,
              ),
            )
          else ...[
            _emergencyInfoPill(Icons.person_outline, first.name, fs),
            const SizedBox(height: 6),
            _emergencyInfoPill(Icons.phone_outlined, first.phoneNumber, fs),
            const SizedBox(height: 6),
            _emergencyInfoPill(
              Icons.family_restroom_outlined,
              first.relationship.isEmpty ? '-' : first.relationship,
              fs,
            ),
          ],
        ],
      ),
    );
  }

  Widget _emergencyInfoPill(IconData icon, String value, double fs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13 * fs,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final themeP = context.read<ThemeProvider>();
    final fs = themeP.fontSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.map((c) => c.withOpacity(0.12)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: gradient.first.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15 * fs,
                          fontWeight: FontWeight.w700,
                          color: gradient.first,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12 * fs,
                          color: gradient.first.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: gradient.first.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FIX: Kalkulasi umur yang benar berdasarkan tanggal saat ini
  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    // Kurangi 1 jika belum ulang tahun tahun ini
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  String _formatBirthDate(DateTime? date, LanguageProvider lang) {
    if (date == null) return '-';
    final months = lang.currentLanguage == 'en'
        ? [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agt',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMeasure(num? value, String unit) {
    if (value == null || value <= 0) return '-';
    final display = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$display $unit';
  }
}

// ====================================================================
// Profile Hero Card
// ====================================================================
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.onEdit,
    required this.isDark,
    required this.fs,
    required this.lang,
  });

  final String name, email, phone;
  final String? photoUrl;
  final VoidCallback onEdit;
  final bool isDark;
  final double fs;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D4A47), const Color(0xFF1A2636)]
              : [Colors.teal.shade600, Colors.teal.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (photoUrl != null && photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: (photoUrl == null || photoUrl!.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.teal.shade300,
                            )
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.teal.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * fs,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoPill(Icons.email_outlined, email),
                  _infoPill(Icons.phone_rounded, phone),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 12 * fs),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// Quick Settings Sheet
// ====================================================================
class _QuickSettingsSheet extends StatelessWidget {
  const _QuickSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final langP = context.watch<LanguageProvider>();
    final isDark = themeP.isDarkMode;

    final bgColor = isDark ? const Color(0xFF1A2636) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    String t(Map<String, String> m) => langP.translate(m);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
                t({
                  'id': 'Pengaturan Cepat',
                  'en': 'Quick Settings',
                  'ms': 'Tetapan Pantas',
                }),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // --- TEMA ---
              _settingSection(
                label: t({'id': 'Tema', 'en': 'Theme', 'ms': 'Tema'}),
                icon: Icons.palette_outlined,
                isDark: isDark,
                child: Row(
                  children: [
                    _themeButton(
                      context: context,
                      icon: Icons.light_mode_rounded,
                      label: t({'id': 'Terang', 'en': 'Light', 'ms': 'Cerah'}),
                      isSelected: !isDark,
                      onTap: () => themeP.setThemeMode(ThemeMode.light),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _themeButton(
                      context: context,
                      icon: Icons.dark_mode_rounded,
                      label: t({'id': 'Gelap', 'en': 'Dark', 'ms': 'Gelap'}),
                      isSelected: isDark,
                      onTap: () => themeP.setThemeMode(ThemeMode.dark),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- BAHASA ---
              _settingSection(
                label: t({'id': 'Bahasa', 'en': 'Language', 'ms': 'Bahasa'}),
                icon: Icons.language_rounded,
                isDark: isDark,
                child: Row(
                  children: [
                    _langButton(
                      context,
                      'id',
                      '🇮🇩',
                      'Indonesia',
                      langP.currentLanguage == 'id',
                      isDark,
                      langP,
                    ),
                    const SizedBox(width: 8),
                    _langButton(
                      context,
                      'en',
                      '🇬🇧',
                      'English',
                      langP.currentLanguage == 'en',
                      isDark,
                      langP,
                    ),
                    const SizedBox(width: 8),
                    _langButton(
                      context,
                      'ms',
                      '🇲🇾',
                      'Melayu',
                      langP.currentLanguage == 'ms',
                      isDark,
                      langP,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- UKURAN FONT ---
              _settingSection(
                label: t({
                  'id': 'Ukuran Teks',
                  'en': 'Text Size',
                  'ms': 'Saiz Teks',
                }),
                icon: Icons.text_fields_rounded,
                isDark: isDark,
                child: Row(
                  children: [
                    _fontSizeButton(
                      context,
                      0.85,
                      t({'id': 'Kecil', 'en': 'Small', 'ms': 'Kecil'}),
                      themeP,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _fontSizeButton(
                      context,
                      1.0,
                      t({'id': 'Normal', 'en': 'Normal', 'ms': 'Normal'}),
                      themeP,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _fontSizeButton(
                      context,
                      1.2,
                      t({'id': 'Besar', 'en': 'Large', 'ms': 'Besar'}),
                      themeP,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingSection({
    required String label,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.teal.shade400),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _themeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.teal.shade400
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.teal.shade400 : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langButton(
    BuildContext context,
    String code,
    String flag,
    String label,
    bool isSelected,
    bool isDark,
    LanguageProvider langP,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => langP.setLanguage(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade400
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fontSizeButton(
    BuildContext context,
    double size,
    String label,
    ThemeProvider themeP,
    bool isDark,
  ) {
    final isSelected = (themeP.fontSize - size).abs() < 0.05;
    final sampleSize = 13.0 * size;
    return Expanded(
      child: GestureDetector(
        onTap: () => themeP.setFontSize(size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.purple.shade400
                : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: sampleSize,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
