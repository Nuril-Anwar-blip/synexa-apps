import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../../extensions/emergency_contact_model_extension.dart';
import '../../extensions/user_model_extension.dart';
import '../../models/user_model.dart';
import '../../services/remote/auth_service.dart';
import '../../styles/colors/app_color.dart';
import '../../widgets/pop_up_loading.dart';
import '../pairing/pairing_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserModel? _user;

  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
    // pindah ke Dashboard
    // final service = FlutterBackgroundService();
    // service.startService();
    // service.on('log').listen((event) {
    //   debugPrint(event!['message']);
    // });
    _checkLocationAndStartService();
  }

  Future<void> _checkLocationAndStartService() async {
    // Cek apakah lokasi aktif
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Tampilkan dialog atau snackbar supaya user menyalakan lokasi
      if (!mounted) return;
      bool enabled =
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColor.background,
              title: const Text("Lokasi dimatikan"),
              content: const Text("Untuk mendeteksi jatuh, aktifkan lokasi."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(color: AppColor.error),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Buka pengaturan lokasi
                    await Geolocator.openLocationSettings();
                    if (!mounted) return;

                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "Buka Pengaturan",
                    style: TextStyle(color: AppColor.primary),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!enabled) return; // User menolak
    }

    // Minta izin lokasi
    bool granted = await requestLocationPermission();
    if (!granted) {
      debugPrint("User menolak izin lokasi");
      return;
    }

    // Mulai service
    final service = FlutterBackgroundService();
    service.startService();
    service.on('log').listen((event) {
      debugPrint(event!['message']);
    });
  }

  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
    });
    _user = await _authService.getUserById(widget.userId);
    if (_user == null) {
      await _authService.signOut();
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PairingScreen()),
        (route) => false,
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? PopUpLoading()
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildProfileHeader(
                  name: _user?.fullNameUI ?? "-",
                  phoneNumber: _user?.phoneNumberUI ?? "-",
                ),
                const SizedBox(height: 24),

                // Bagian Informasi Personal
                _buildInfoCard(
                  title: 'Informasi Personal',
                  icon: Icons.person_outline,
                  details: {
                    'Umur': '${_user?.age ?? "-"} Tahun',
                    'Jenis Kelamin': "${_user?.genderUI}",
                    'Berat Badan': '${_user?.weight ?? "-"} kg',
                  },
                ),
                const SizedBox(height: 16),

                // Bagian Kondisi Medis
                _buildInfoCard(
                  title: 'Kondisi Medis',
                  icon: Icons.medical_services_outlined,
                  details: {
                    'Riwayat Penyakit': _user?.medicalHistoryUI ?? "-",

                    'Alergi Obat': _user?.drugAllergyUI ?? "-",
                  },
                ),
                const SizedBox(height: 16),

                // Bagian Kontak Darurat
                _buildInfoCard(
                  title: 'Kontak Darurat',
                  icon: Icons.contact_phone_outlined,
                  details: {
                    'Nama':
                        '${_user?.emergencyContact.nameUI ?? ""} ${_user?.emergencyContact.relationshipUI == null ? "" : "(${_user?.emergencyContact.relationshipUI})"}',
                    'Nomor Telepon':
                        _user?.emergencyContact.phoneNumberUI ?? "-",
                  },
                ),
                const SizedBox(height: 32),

                // Tombol Logout
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                  ),
                  onPressed: () => _handleLogout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.background,
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Tidak',
              style: TextStyle(color: AppColor.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya', style: TextStyle(color: AppColor.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Panggil logout

      try {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false, // supaya ga bisa ditutup manual
          builder: (_) => const PopUpLoading(),
        );
        await _authService.signOut();
        if (!mounted) return;
        Navigator.of(context).pop();

        // Navigasi kembali ke login dan hapus semua route sebelumnya
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PairingScreen()),
          (route) => false,
        );
      } catch (e) {
        log(e.toString());
        if (!mounted) return;

        Navigator.of(context).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // Widget untuk header profil
  Widget _buildProfileHeader({
    required String name,
    required String phoneNumber,
  }) {
    return Card(
      elevation: 0,
      color: Color.fromARGB(255, 228, 246, 255),
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: Color.fromARGB(255, 186, 233, 255),
              child: Icon(Icons.person, size: 40, color: Colors.black),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk kartu informasi
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Map<String, String> details,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...details.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
