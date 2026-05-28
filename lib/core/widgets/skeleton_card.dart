import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Hesaplama sırasında sonuç kartının yerine gösterilen skeleton loader.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  _box(28, 28, circular: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(120, 20),
                        const SizedBox(height: 6),
                        _box(200, 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Grafik alanı
              _box(double.infinity, 96),
              const SizedBox(height: 16),
              // Metrik satırları
              _metricRow(),
              const SizedBox(height: 10),
              _metricRow(),
              const SizedBox(height: 10),
              _metricRow(),
              const SizedBox(height: 10),
              _metricRow(),
              const SizedBox(height: 16),
              // Detay satırları
              _metricRow(valueWidth: 80),
              const SizedBox(height: 10),
              _metricRow(valueWidth: 80),
              const SizedBox(height: 10),
              _metricRow(valueWidth: 60),
              const SizedBox(height: 10),
              _metricRow(valueWidth: 50),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _box(double width, double height, {bool circular = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: circular ? null : BorderRadius.circular(4),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }

  static Widget _metricRow({double valueWidth = 100}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_box(100, 14), _box(valueWidth, 14)],
    );
  }
}
