import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Warna identitas TWFOOD (sama dengan website)
  static const Color primary = Color(0xFFE31E24); // merah
  static const Color secondary = Color(0xFFF7941D); // oranye
  static const Color accent = Color(0xFFF6D65A); // kuning

  // Warna dasar
  static const Color background = Color(0xFFFFF8ED);
  static const Color surface = Color(0xFFFFFFFF);

  // Warna teks
  static const Color textPrimary = Color(0xFF2B2622);
  static const Color textSecondary = Color(0xFF7A736B);

  // Warna pendukung
  static const Color border = Color(0xFFECE4D9);
  static const Color success = Color(0xFF1B8A4B);
  static const Color warning = Color(0xFFF7941D);
  static const Color error = Color(0xFFE31E24);

  // Varian lembut untuk latar ikon, badge, dan item terpilih
  static const Color primarySoft = Color(0xFFFDECEC);
  static const Color secondarySoft = Color(0xFFFFF1DC);
  static const Color accentSoft = Color(0xFFFFF6D6);

  // Gradasi banner (merah -> oranye, sama seperti dashboard admin)
  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE31E24), Color(0xFFF7941D)],
  );

  // Bayangan halus untuk kartu
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0F2B2622),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];
}