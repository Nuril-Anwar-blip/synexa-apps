// services/health_manager.dart
import 'dart:async';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class StrokeSensorData {
  final double? heartRate;
  final double? hrVariability;
  final double? systolic;
  final double? diastolic;
  final DateTime timestamp;
  final String risk;
  final String message;

  StrokeSensorData({
    required this.heartRate,
    required this.hrVariability,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
    required this.risk,
    required this.message,
  });
}

class HealthManager {
  final Health _health = Health(); // <-- Ganti HealthFactory() ke Health()

  final StreamController<StrokeSensorData> _controller =
      StreamController.broadcast();
  Stream<StrokeSensorData> get stream => _controller.stream;

  DateTime _lastFetch = DateTime.now().subtract(Duration(minutes: 5));
  Timer? _pollTimer;

  final List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  Future<bool> init() async {
    try {
      // Runtime permission wajib
      await Permission.activityRecognition.request();
      await Permission.location.request();

      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        await _health.installHealthConnect();
      }

      // Baru request health connect
      bool granted = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      return granted;
    } catch (e) {
      return false;
    }
  }

  void start({Duration interval = const Duration(seconds: 5)}) {
    stop();
    _lastFetch = DateTime.now().subtract(Duration(seconds: 10));
    _pollTimer = Timer.periodic(interval, (_) => _pollOnce());
    _pollOnce();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }

  Future<void> _pollOnce() async {
    final now = DateTime.now();
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: _lastFetch,
        endTime: now,
        types: _types,
      );

      _lastFetch = now;

      double? latestHR;
      double? latestSDNN;
      double? latestSys;
      double? latestDia;

      for (final p in data) {
        if (p.type == HealthDataType.HEART_RATE) {
          latestHR = (p.value is num) ? (p.value as num).toDouble() : latestHR;
        } else if (p.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN) {
          latestSDNN = (p.value is num)
              ? (p.value as num).toDouble()
              : latestSDNN;
        } else if (p.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
          latestSys = (p.value is num)
              ? (p.value as num).toDouble()
              : latestSys;
        } else if (p.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
          latestDia = (p.value is num)
              ? (p.value as num).toDouble()
              : latestDia;
        }
      }

      String risk = 'normal';
      String message = 'Tidak ada indikasi kritis saat ini.';

      if (latestSys != null && latestSys >= 180) {
        risk = 'high';
        message =
            'Tekanan darah sangat tinggi — risiko stroke meningkat. Periksa segera.';
      } else if (latestHR != null && (latestHR > 120 || latestHR < 40)) {
        risk = 'warning';
        message =
            'Denyut jantung abnormal (tinggi/rendah). Perhatikan & cek lebih lanjut.';
      } else if (latestSDNN != null && latestSDNN < 20) {
        risk = 'warning';
        message =
            'Variabilitas jantung rendah (stress/arrhythmia kemungkinan).';
      }

      final sensorData = StrokeSensorData(
        heartRate: latestHR,
        hrVariability: latestSDNN,
        systolic: latestSys,
        diastolic: latestDia,
        timestamp: now,
        risk: risk,
        message: message,
      );

      if (!_controller.isClosed) _controller.add(sensorData);
    } catch (e) {
      final sensorData = StrokeSensorData(
        heartRate: null,
        hrVariability: null,
        systolic: null,
        diastolic: null,
        timestamp: DateTime.now(),
        risk: 'normal',
        message: 'Gagal mengambil data sensor: $e',
      );
      if (!_controller.isClosed) _controller.add(sensorData);
    }
  }
}
