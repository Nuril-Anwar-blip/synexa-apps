import 'package:flutter/material.dart';

/// Palet warna utama aplikasi.
/// Digunakan agar konsisten di semua halaman.
class AppColor {
  const AppColor._();

  // Warna Utama (Brand Colors)
  static const MaterialColor primary = Colors.teal;
  static const Color onPrimary = Colors.white;

  // Warna Latar Belakang & Teks
  static const Color background = Color(0xFFF8FAFB);
  static const Color text = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6C757D);

  // Warna Status & Aksi
  static const Color outlined = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF1976D2);

  // Warna Khusus Tema Gelap (Dark Theme)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
}

