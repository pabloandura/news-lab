import 'package:flutter/material.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

class BotCheckBadge extends StatelessWidget {
  final BotCheckEntity botCheck;

  const BotCheckBadge({super.key, required this.botCheck});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 13, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Bot checked',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BotCheckBottomSheet(botCheck: botCheck),
    );
  }
}

class _BotCheckBottomSheet extends StatelessWidget {
  final BotCheckEntity botCheck;

  const _BotCheckBottomSheet({required this.botCheck});

  @override
  Widget build(BuildContext context) {
    final flaggedPct = (botCheck.flaggedSentencesPercent * 100).round();
    final confidencePct = (botCheck.confidenceScore * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Bot Fact Check',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Automated analysis by our fact-checking algorithm.',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 20),
          _StatRow(
            icon: Icons.flag_outlined,
            label: 'Sentences flagged',
            value: '$flaggedPct%',
            color: flaggedPct > 50 ? Colors.red.shade400 : Colors.orange.shade600,
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.analytics_outlined,
            label: 'Confidence score',
            value: '$confidencePct%',
            color: Colors.black87,
          ),
          if (botCheck.checkedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Checked on ${formatDate(botCheck.checkedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ],
      ),
    );
  }

}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
