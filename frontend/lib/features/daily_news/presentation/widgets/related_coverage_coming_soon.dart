import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

/// Placeholder for the Phase 4 "Find related coverage" feature (sensemaker).
/// Replace this widget with the real SimilarArticlesSection once sensemaker
/// is implemented.
class RelatedCoverageComingSoon extends StatelessWidget {
  const RelatedCoverageComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.layers_outline, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Text(
            'Related coverage — coming soon',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
