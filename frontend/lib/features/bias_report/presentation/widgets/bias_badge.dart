import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';

/// Displays a compact political-lean indicator and emotional language score.
/// Must be provided a [BiasReportEntity].
class BiasBadge extends StatelessWidget {
  final BiasReportEntity report;

  const BiasBadge({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _LeanChip(politicalLean: report.politicalLean),
        _EmotionChip(score: report.emotionalLanguageScore),
      ],
    );
  }
}

// ── Political lean chip ───────────────────────────────────────────────────

class _LeanChip extends StatelessWidget {
  final double politicalLean;
  const _LeanChip({required this.politicalLean});

  @override
  Widget build(BuildContext context) {
    final label = _leanLabel(politicalLean);
    final color = _leanColor(politicalLean);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.stats_chart_outline, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _leanLabel(double lean) {
    if (lean <= -0.6) return 'Strong left lean';
    if (lean <= -0.2) return 'Left lean';
    if (lean < 0.2) return 'Neutral';
    if (lean < 0.6) return 'Right lean';
    return 'Strong right lean';
  }

  Color _leanColor(double lean) {
    if (lean <= -0.2) return Colors.blue.shade700;
    if (lean >= 0.2) return Colors.red.shade700;
    return Colors.green.shade700;
  }
}

// ── Emotional language chip ───────────────────────────────────────────────

class _EmotionChip extends StatelessWidget {
  final double score;
  const _EmotionChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final label = _emotionLabel(score);
    final color = _emotionColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.flame_outline, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _emotionLabel(double score) {
    if (score < 0.25) return 'Factual tone';
    if (score < 0.5) return 'Mild emotion';
    if (score < 0.75) return 'Charged language';
    return 'Highly emotional';
  }

  Color _emotionColor(double score) {
    if (score < 0.25) return Colors.green.shade700;
    if (score < 0.5) return Colors.amber.shade700;
    if (score < 0.75) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
