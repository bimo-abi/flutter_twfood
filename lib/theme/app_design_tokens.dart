import 'package:flutter/material.dart';

/// Token ukuran dan bentuk agar komponen Pelanggan dan Mitra konsisten.
class AppDesignTokens {
  AppDesignTokens._();

  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusPill = 999;

  static const double iconSmall = 18;
  static const double iconMedium = 22;
  static const double iconLarge = 28;

  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
  );
}
