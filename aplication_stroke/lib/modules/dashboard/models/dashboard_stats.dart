/// Model DashboardStats
/// 
/// Menyimpan data statistik yang ditampilkan di dashboard,
/// seperti nilai detak jantung (heart rate).
class DashboardStats {
  final String heartRate;

  const DashboardStats({required this.heartRate});

  /// Mengembalikan state kosong/default jika data belum tersedia
  factory DashboardStats.empty() => const DashboardStats(heartRate: '—');
}
