import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/constants/brand_colors.dart';

double _relativeLuminance(Color color) {
  final argb = color.toARGB32();
  double linearize(int channel) {
    final value = channel / 255;
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize((argb >> 16) & 0xFF) +
      0.7152 * linearize((argb >> 8) & 0xFF) +
      0.0722 * linearize(argb & 0xFF);
}

double _contrast(Color foreground, Color background) {
  final light = math.max(
    _relativeLuminance(foreground),
    _relativeLuminance(background),
  );
  final dark = math.min(
    _relativeLuminance(foreground),
    _relativeLuminance(background),
  );
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  test('share card text tokens meet WCAG AA on every light surface', () {
    const surfaces = <Color>[
      ShareCardColors.canvas,
      ShareCardColors.surfaceSubtle,
      ShareCardColors.surfaceRaised,
      ShareCardColors.brandSurface,
    ];

    for (final surface in surfaces) {
      expect(
        _contrast(ShareCardColors.textPrimary, surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(ShareCardColors.textSecondary, surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('approved brand palette values stay pinned', () {
    expect(BrandColors.navy.toARGB32(), 0xFF0B1D34);
    expect(BrandColors.teal.toARGB32(), 0xFF2CB1B8);
    expect(BrandColors.offWhite.toARGB32(), 0xFFF5F6F7);
  });
}
