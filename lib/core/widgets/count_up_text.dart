import 'package:flutter/material.dart';

/// Sayısal değeri 0'dan hedefe animasyonlu sayarak gösteren widget.
class CountUpText extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Explicit `Tween<double>(begin: 0.0, ...)`: `Tween(begin: 0, end: value)`
      // Dart inference'ına göre `Tween<num>` çıkarılabilir; `TweenAnimationBuilder<double>`
      // bunu kabul etmez ve `strict-casts: true` altında derleme hatası
      // riski taşır. Explicit tip defansiftir ve niyeti netleştirir.
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(formatter(animatedValue), style: style);
      },
    );
  }
}
