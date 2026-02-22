import 'package:flutter/material.dart';

/// Widget GreetingWithHeartRate
/// 
/// Widget ini menampilkan sapaan kepada pengguna dan indikator detak jantung realtime.
/// Menggunakan desain gradient premium dengan efek shadow.
class GreetingWithHeartRate extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String heartRate;
  final String status;
  final bool isDark;

  const GreetingWithHeartRate({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.heartRate,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.9),
            Colors.teal.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Pengguna
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.9),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Icon(Icons.person, color: theme.primaryColor, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Pengguna
                Text(
                  'Halo, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apa yang Anda rasakan hari ini?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                // Indikator Detak Jantung
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      heartRate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Status Detak Jantung (Normal/Rendah/Tinggi)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
