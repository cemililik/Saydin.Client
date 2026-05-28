import 'package:flutter/material.dart';

/// Sayısal değeri animasyonlu sayarak gösteren widget.
///
/// İlk render'da 0'dan [value]'ya, sonraki [value] değişimlerinde ise
/// önceki değerden yeni değere animasyon yapar. Önceki davranışta her
/// parent rebuild [Tween.begin] sıfırdan başlatıldığı için sayı görsel
/// olarak sıçrıyordu (`MaterialApp` rebuild veya BLoC state emit'lerinde).
class CountUpText extends StatefulWidget {
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
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  late double _begin;

  @override
  void initState() {
    super.initState();
    // İlk gösterimde 0'dan başla; sonraki güncellemelerde önceki value'dan.
    _begin = 0.0;
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _begin = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Explicit `Tween<double>(...)`: `Tween(begin: 0, end: value)`
      // Dart inference'ına göre `Tween<num>` çıkarılabilir;
      // `TweenAnimationBuilder<double>` bunu kabul etmez ve
      // `strict-casts: true` altında derleme hatası riski taşır.
      tween: Tween<double>(begin: _begin, end: widget.value),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(widget.formatter(animatedValue), style: widget.style);
      },
    );
  }
}
