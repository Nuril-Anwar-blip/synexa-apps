import 'dart:async';
import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../extensions/emergency_contact_model_extension.dart';
import '../../extensions/user_model_extension.dart';
import '../../models/user_model.dart';
import '../../services/remote/auth_service.dart';
import '../../styles/colors/app_color.dart';
import '../../utils/health_manager.dart';
import '../../widgets/base_screen.dart';
import '../../widgets/pop_up_loading.dart';
import '../pairing/pairing_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final UserModel? _user;
  final _authService = AuthService();
  bool _isLoading = false;
  int _currentIndex = 0; // untuk dot indicator
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  late final HealthManager _healthManager;
  StrokeSensorData? _latestSensorData;
  StreamSubscription<StrokeSensorData>? _sensorSub;

  @override
  void initState() {
    super.initState();
    _healthManager = HealthManager();
    _init();
    // _checkLocationAndStartService();
    _setupHealth();
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _healthManager.dispose();
    super.dispose();
  }

  Future<void> _setupHealth() async {
    final granted = await _healthManager.init();
    
    if (!granted) {
      // Anda bisa berikan dialog agar user mengaktifkan permission di phone/watch
      debugPrint('Health permission tidak diberikan.');
      return;
    }
    // listen ke stream realtime
    _sensorSub = _healthManager.stream.listen((data) {
      if (!mounted) return;
      setState(() {
        _latestSensorData = data;
      });
    });

    // mulai polling setiap 5 detik
    _healthManager.start(interval: Duration(seconds: 5));
  }

  Future<void> _checkLocationAndStartService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
      if (!enabled) return;
    }

    bool granted = await requestLocationPermission();
    if (!granted) {
      debugPrint("User menolak izin lokasi");
      return;
    }

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
    // Ambil ukuran layar smartwatch
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double baseFontSize = screenWidth * 0.05; // skala font

    return BaseScreen(
      body: _isLoading
          ? PopUpLoading()
          : Column(
              children: [
                Expanded(
                  child: CarouselSlider(
                    carouselController: _carouselController,
                    options: CarouselOptions(
                      scrollDirection: Axis.vertical,
                      height: double.infinity,
                      viewportFraction: 0.8,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                    items: [
                      _buildProfileCard(baseFontSize),
                      _buildStrokeMonitorCard(baseFontSize),
                      _buildPersonalInfoCard(baseFontSize),
                      _buildMedicalInfoCard(baseFontSize),
                      _buildEmergencyContactCard(baseFontSize),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                AnimatedSmoothIndicator(
                  activeIndex: _currentIndex,
                  count: 4,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: AppColor.primary,
                    dotColor: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
    );
  }

  // CARD baru menampilkan data realtime dari _latestSensorData
  Widget _buildStrokeMonitorCard(double fontScale) {
    final data = _latestSensorData;
    final hrText = data?.heartRate != null
        ? '${data!.heartRate!.toStringAsFixed(0)} bpm'
        : '-';
    final sdnnText = data?.hrVariability != null
        ? '${data!.hrVariability!.toStringAsFixed(1)} ms'
        : '-';
    final sysText = data?.systolic != null
        ? data!.systolic!.toStringAsFixed(0)
        : '-';
    final diaText = data?.diastolic != null
        ? data!.diastolic!.toStringAsFixed(0)
        : '-';
    final status = data?.risk ?? 'normal';
    Color statusColor = Colors.green;
    if (status == 'warning') statusColor = Colors.orange;
    if (status == 'high') statusColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(fontScale * 0.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    color: Colors.blue.shade700,
                    size: fontScale * 1.2,
                  ),
                  SizedBox(width: fontScale * 0.5),
                  Text(
                    'Monitoring Stroke',
                    style: TextStyle(
                      fontSize: fontScale * 1.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: fontScale * 1.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _smallInfoColumn('HR', hrText, fontScale),
                  _smallInfoColumn('HRV (SDNN)', sdnnText, fontScale),
                  _smallInfoColumn('Sys/Dia', '$sysText / $diaText', fontScale),
                ],
              ),
              SizedBox(height: fontScale * 0.6),
              Text(
                data?.message ?? 'Menunggu data...',
                style: TextStyle(
                  fontSize: fontScale * 0.8,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: fontScale * 0.4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  data != null
                      ? 'Terakhir: ${_formatTime(data.timestamp)}'
                      : '',
                  style: TextStyle(
                    fontSize: fontScale * 0.7,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallInfoColumn(String title, String value, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: fontScale * 0.8,
          ),
        ),
        SizedBox(height: fontScale * 0.1),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontScale * 0.95,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  Widget _buildProfileCard(double fontScale) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: Color.fromARGB(255, 228, 246, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: fontScale * 1.2,
                backgroundColor: Color.fromARGB(255, 186, 233, 255),
                child: Icon(
                  Icons.person,
                  size: fontScale * 2,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: fontScale * 0.5),
              Text(
                _user?.fullNameUI ?? "-",
                style: TextStyle(
                  fontSize: fontScale * 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: fontScale * 0.2),
              Text(
                _user?.phoneNumberUI ?? "-",
                style: TextStyle(
                  fontSize: fontScale * 0.9,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: fontScale),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: fontScale * 0.5,
                    horizontal: fontScale,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                ),
                onPressed: _handleLogout,
                icon: Icon(Icons.logout, size: fontScale),
                label: Text('Logout', style: TextStyle(fontSize: fontScale)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(double fontScale) {
    return _buildInfoCard(
      fontScale: fontScale,
      title: 'Informasi Personal',
      icon: Icons.person_outline,
      details: {
        'Umur': '${_user?.age ?? "-"} Tahun',
        'Jenis Kelamin': _user?.genderUI ?? "-",
        'Berat Badan': '${_user?.weight ?? "-"} kg',
      },
    );
  }

  Widget _buildMedicalInfoCard(double fontScale) {
    return _buildInfoCard(
      fontScale: fontScale,
      title: 'Kondisi Medis',
      icon: Icons.medical_services_outlined,
      details: {
        'Riwayat Penyakit': _user?.medicalHistoryUI ?? "-",
        'Alergi Obat': _user?.drugAllergyUI ?? "-",
      },
    );
  }

  Widget _buildEmergencyContactCard(double fontScale) {
    return _buildInfoCard(
      fontScale: fontScale,
      title: 'Kontak Darurat',
      icon: Icons.contact_phone_outlined,
      details: {
        'Nama':
            '${_user?.emergencyContact.nameUI ?? ""} ${_user?.emergencyContact.relationshipUI == null ? "" : "(${_user?.emergencyContact.relationshipUI})"}',
        'Nomor Telepon': _user?.emergencyContact.phoneNumberUI ?? "-",
      },
    );
  }

  Widget _buildInfoCard({
    required double fontScale,
    required String title,
    required IconData icon,
    required Map<String, String> details,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(fontScale * 0.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.blue.shade700,
                    size: fontScale * 1.2,
                  ),
                  SizedBox(width: fontScale * 0.5),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontScale * 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(height: fontScale * 1.5),
              ...details.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: fontScale * 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: fontScale * 0.9,
                        ),
                      ),
                      SizedBox(width: fontScale * 0.3),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: fontScale * 0.95,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
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
      try {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PopUpLoading(),
        );
        await _authService.signOut();
        if (!mounted) return;
        Navigator.of(context).pop();
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
}
