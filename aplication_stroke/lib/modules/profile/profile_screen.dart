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
import '../auth/login_screen.dart';
import '../pairing_scanner/pairing_scanner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? userModel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    // Pastikan widget masih ada sebelum melakukan setState
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
          if (response != null) {
            userModel = UserModel.fromMap(response);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ LOG FETCH ERROR: Gagal mengambil profil: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat profil: $e")));
      }
    }
  }

  // Di dalam class _ProfileScreenState di file profile_screen.dart

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint("LOG UPDATE: User tidak ditemukan, update dibatalkan.");
      return;
    }

    // --- INI BAGIAN PENTINGNYA ---
    // Kita buat Map baru untuk "menerjemahkan" kunci dari camelCase ke snake_case
    final Map<String, dynamic> dataForSupabase = {
      'full_name': data['name'],
      'phone_number': data['phoneNumber'],
      'age': data['age'],
      'gender': data['gender'],
      'weight': data['weight'],
      'height': data['height'],
      'medical_history': data['medicalHistory'],
      'drug_allergy':
          data['drugAllergy'], // <-- Kunci ini sekarang benar ('drug_allergy')
      'emergency_contact': {
        'name': data['emergencyContactName'],
        'phone_number': data['emergencyContactPhone'],
        'relationship': data['emergencyContactRelationship'] ?? '',
      },
      // Pastikan photo_url juga menggunakan snake_case jika perlu,
      // tapi biasanya dari Supabase sudah benar. Kita tambahkan secara kondisional.
    };

    if (data['photoUrl'] != null && (data['photoUrl'] as String).isNotEmpty) {
      dataForSupabase['photo_url'] = data['photoUrl'];
    }

    debugPrint(
      "✅ LOG UPDATE: Data payload FINAL yang dikirim ke Supabase: $dataForSupabase",
    );

    try {
      await Supabase.instance.client
          .from('users')
          .update(dataForSupabase) // <-- Gunakan Map yang sudah diterjemahkan
          .eq('id', user.id);

      debugPrint("🎉 LOG UPDATE: SUKSES memperbarui data di Supabase.");
    } catch (e) {
      debugPrint("❌ LOG UPDATE ERROR: Gagal saat memanggil .update() Supabase: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: $e')));
      }
    }

    await _fetchProfile();
  }

  Future<void> _openEditProfile() async {
    if (userModel == null) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: userModel?.fullName ?? '',
          phoneNumber: userModel?.phoneNumber ?? '',
          age: userModel?.age,
          gender: userModel?.gender,
          weight: userModel?.weight,
          height: userModel?.height,
          medicalHistory: userModel?.medicalHistory.join(', '),
          drugAllergy: userModel?.drugAllergy.join(', '),
          emergencyContactName: userModel?.emergencyContact.name,
          emergencyContactPhone: userModel?.emergencyContact.phoneNumber,
          photoUrl: userModel?.photoUrl,
        ),
      ),
    );

    if (result != null) {
      await _updateProfile(result);
    }
  }

  Future<void> _confirmLogout() async {
    if (!mounted) return;
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya'),
            ),
          ],
        );
      },
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

  /// Menampilkan dialog untuk memilih jenis font
  void _showFontDialog(BuildContext context, ThemeProvider themeProvider) {
    final fonts = ['Poppins', 'Inter', 'Roboto', 'Lato', 'Open Sans'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Jenis Font'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts.map((font) => ListTile(
            title: Text(font, style: GoogleFonts.getFont(font)),
            trailing: themeProvider.fontFamily == font ? const Icon(Icons.check, color: Colors.teal) : null,
            onTap: () {
              themeProvider.setFontFamily(font);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  /// Menampilkan dialog untuk mengatur ukuran font
  void _showFontSizeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Ukuran Teks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sesuaikan kenyamanan membaca Anda'),
                const SizedBox(height: 20),
                Slider(
                  value: themeProvider.fontSize,
                  min: 0.8,
                  max: 1.4,
                  divisions: 3,
                  label: themeProvider.fontSize == 0.8 ? 'Kecil' : (themeProvider.fontSize == 1.0 ? 'Normal' : (themeProvider.fontSize == 1.2 ? 'Besar' : 'Sangat Besar')),
                  onChanged: (val) {
                    themeProvider.setFontSize(val);
                    setDialogState(() {});
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('A', style: TextStyle(fontSize: 12)),
                    Text('A', style: TextStyle(fontSize: 16)),
                    Text('A', style: TextStyle(fontSize: 20)),
                    Text('A', style: TextStyle(fontSize: 24)),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))
            ],
          );
        }
      ),
    );
  }

  /// Menampilkan dialog untuk memilih bahasa
  void _showLanguageDialog(BuildContext context, LanguageProvider langProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, langProvider, code: 'id', name: 'Bahasa Indonesia', flag: '🇮🇩'),
            _buildLanguageOption(context, langProvider, code: 'en', name: 'English', flag: '🇺🇸'),
            _buildLanguageOption(context, langProvider, code: 'ms', name: 'Melayu', flag: '🇲🇾'),
          ],
        ),
      ),
    );
  }

  /// Widget pembantu untuk opsi bahasa dalam dialog
  Widget _buildLanguageOption(
    BuildContext context,
    LanguageProvider langProvider, {
    required String code,
    required String name,
    required String flag,
  }) {
    final isSelected = langProvider.currentLanguage == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      onTap: () {
        langProvider.setLanguage(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bahasa diubah ke $name')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _openEditProfile,
          ),
        ],
      ),
      body: userModel == null
          ? const Center(
              child: Text(
                'Data profil tidak ditemukan.\nMohon lengkapi profil Anda.',
                textAlign: TextAlign.center,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
                children: [
                  const SizedBox(height: 12),
                  /// Widget hero untuk menampilkan informasi dasar profil pengguna.
                  _ProfileHero(
                    name: userModel!.fullNameUI,
                    email: userModel!.email,
                    phone: userModel!.phoneNumberUI,
                    photoUrl: userModel!.photoUrl,
                    onEdit: _openEditProfile,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildQuickStats(userModel!),
                        const SizedBox(height: 20),
                        _InfoSectionCard(
                          title: 'Detail Pribadi',
                          icon: Icons.badge_outlined,
                          children: [
                            _InfoRow(
                              label: 'Nomor Telepon',
                              value: userModel!.phoneNumberUI,
                            ),
                            _InfoRow(label: 'Email', value: userModel!.email),
                            _InfoRow(
                              label: 'Jenis Kelamin',
                              value: userModel!.genderUI,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoSectionCard(
                          title: 'Kondisi Medis',
                          icon: Icons.medical_services_outlined,
                          children: [
                            _InfoRow(
                              label: 'Riwayat Penyakit',
                              child: _ChipGroup(
                                items: userModel!.medicalHistory
                                    .where((e) => e.trim().isNotEmpty)
                                    .toList(),
                              ),
                            ),
                            _InfoRow(
                              label: 'Alergi Obat',
                              child: _ChipGroup(
                                items: userModel!.drugAllergy
                                    .where((e) => e.trim().isNotEmpty)
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoSectionCard(
                          title: 'Kontak Darurat',
                          icon: Icons.contact_phone_outlined,
                          children: [
                            _InfoRow(
                              label: 'Nama',
                              value: userModel!.emergencyContact.name.isNotEmpty
                                  ? userModel!.emergencyContact.name
                                  : '-',
                            ),
                            _InfoRow(
                              label: 'Nomor Telepon',
                              value:
                                  userModel!
                                      .emergencyContact
                                      .phoneNumber
                                      .isNotEmpty
                                  ? userModel!.emergencyContact.phoneNumber
                                  : '-',
                            ),
                            _InfoRow(
                              label: 'Hubungan',
                              value:
                                  userModel!
                                      .emergencyContact
                                      .relationship
                                      .isNotEmpty
                                  ? userModel!.emergencyContact.relationship
                                  : '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _ProfileActionButton(
                          icon: Icons.watch_outlined,
                          title: 'Pair Smartwatch',
                          subtitle:
                              'Hubungkan perangkat wearable untuk memantau data.',
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PairingScannerScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _InfoSectionCard(
                          title: 'Pengaturan Aplikasi',
                          icon: Icons.settings_outlined,
                          children: [
                            Consumer<LanguageProvider>(
                              builder: (context, langProvider, _) {
                                return ListTile(
                                  leading: const Icon(Icons.language_rounded, color: Colors.orange),
                                  title: const Text('Bahasa'),
                                  subtitle: Text(langProvider.languageName),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _showLanguageDialog(context, langProvider),
                                );
                              },
                            ),
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.font_download_rounded, color: Colors.blue),
                                      title: const Text('Jenis Font'),
                                      subtitle: Text(themeProvider.fontFamily),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => _showFontDialog(context, themeProvider),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.format_size_rounded, color: Colors.green),
                                      title: const Text('Ukuran Teks'),
                                      subtitle: Text(themeProvider.fontSize == 0.8 ? 'Kecil' : (themeProvider.fontSize == 1.0 ? 'Normal' : 'Besar')),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => _showFontSizeDialog(context, themeProvider),
                                    ),
                                    SwitchListTile(
                                      secondary: Icon(
                                        themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                        color: themeProvider.isDarkMode ? Colors.purple : Colors.amber,
                                      ),
                                      title: Text(themeProvider.isDarkMode ? 'Mode Gelap' : 'Mode Terang'),
                                      value: themeProvider.isDarkMode,
                                      onChanged: (val) => themeProvider.toggleTheme(),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ProfileActionButton(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Keluar dari akun Anda dengan aman.',
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          onTap: _confirmLogout,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickStats(UserModel user) {
    final cards = [
      _QuickStatCard(
        label: 'Umur',
        value: user.age > 0 ? '${user.age} th' : '-',
      ),
      _QuickStatCard(
        label: 'Tinggi',
        value: _formatMeasurement(user.height, 'cm'),
      ),
      _QuickStatCard(
        label: 'Berat',
        value: _formatMeasurement(user.weight, 'kg'),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  String _formatMeasurement(num value, String unit) {
    if (value <= 0) return '-';
    final display = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$display $unit';
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [Colors.teal.shade500, Colors.teal.shade300],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? Icon(Icons.person, size: 44, color: Colors.teal.shade300)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              _HeroInfoPill(icon: Icons.email_outlined, value: email),
              _HeroInfoPill(icon: Icons.phone_rounded, value: phone),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 77, 209, 29),
              side: BorderSide(color: Colors.white.withOpacity(0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profil'),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoPill extends StatelessWidget {
  const _HeroInfoPill({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal.shade600),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          child ??
              Text(
                value ?? '-',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Belum ada data',
        style: TextStyle(color: Colors.grey.shade500),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Chip(
              label: Text(item),
              backgroundColor: Colors.teal.shade50,
              labelStyle: TextStyle(color: Colors.teal.shade800),
            ),
          )
          .toList(),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: foregroundColor.withOpacity(0.1),
                child: Icon(icon, color: foregroundColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: foregroundColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }
}

