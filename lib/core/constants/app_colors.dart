import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1565C0);
  static const background = Color(0xFFF5F5F5);

  // Kar/zarar renkleri — her iki temada okunabilir tonlar
  static const profit = Color(0xFF2E7D32);
  static const profitDark = Color(0xFF66BB6A);
  static const loss = Color(0xFFC62828);
  static const lossDark = Color(0xFFEF5350);

  static Color profitColor(Brightness brightness) =>
      brightness == Brightness.dark ? profitDark : profit;

  static Color lossColor(Brightness brightness) =>
      brightness == Brightness.dark ? lossDark : loss;

  /// Portföy pasta grafiği için döngüsel renk paleti.
  static const portfolioColors = [
    Color(0xFF1565C0), // mavi
    Color(0xFF2E7D32), // yeşil
    Color(0xFFE65100), // turuncu
    Color(0xFF6A1B9A), // mor
    Color(0xFF00838F), // teal
    Color(0xFFC62828), // kırmızı
    Color(0xFF558B2F), // açık yeşil
    Color(0xFF4527A0), // lacivert
  ];
}
