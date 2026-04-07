import 'package:flutter/material.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';

/// Dark-card bias widget: header row, gradient spectrum bar, description notes.
class BiasSpectrumWidget extends StatelessWidget {
  final BiasReportEntity report;

  const BiasSpectrumWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final confidencePct = (report.emotionalLanguageScore * 100).round();
    final leanLabel = _leanLabel(report.politicalLean);
    final leanDirection =
        report.politicalLean < -0.1 ? '◄' : report.politicalLean > 0.1 ? '►' : '●';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dark red analysis card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF5A1020),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI BIAS ANALYSIS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE57A8A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '$leanDirection $leanLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SpectrumBar(politicalLean: report.politicalLean),
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LEFT',
                      style: TextStyle(fontSize: 10, color: Colors.white38)),
                  Text('CENTER',
                      style: TextStyle(fontSize: 10, color: Colors.white38)),
                  Text('RIGHT',
                      style: TextStyle(fontSize: 10, color: Colors.white38)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Confidence: $confidencePct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE57A8A),
                ),
              ),
            ],
          ),
        ),
        // Framing notes below the card
        if (report.framingNotes.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...report.framingNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _leanLabel(double lean) {
    if (lean < -0.3) return 'Left';
    if (lean > 0.3) return 'Right';
    return 'Center';
  }
}

class _SpectrumBar extends StatelessWidget {
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
