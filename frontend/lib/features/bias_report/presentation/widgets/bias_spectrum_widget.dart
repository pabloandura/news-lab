import 'package:flutter/material.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';

/// Horizontal gradient spectrum bar showing political lean with a marker
/// and a "X% confidence" label derived from emotionalLanguageScore.
class BiasSpectrumWidget extends StatelessWidget {
  final BiasReportEntity report;

  const BiasSpectrumWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final confidencePct = (report.emotionalLanguageScore * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Political Lean',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              '$confidencePct% confidence',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SpectrumBar(politicalLean: report.politicalLean),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Left',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Text(
              'Center',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Text(
              'Right',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        if (report.framingNotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...report.framingNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpectrumBar extends StatelessWidget {
  /// -1 = full left, 0 = center, +1 = full right
  final double politicalLean;

  const _SpectrumBar({required this.politicalLean});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        // Clamp to [-1, 1] and map to [0, 1]
        final clamped = politicalLean.clamp(-1.0, 1.0);
        final markerFraction = (clamped + 1) / 2;
        final markerLeft = markerFraction * barWidth - 8;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade600,
                    Colors.grey.shade300,
                    Colors.blue.shade600,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: markerLeft.clamp(0.0, barWidth - 16),
              top: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
