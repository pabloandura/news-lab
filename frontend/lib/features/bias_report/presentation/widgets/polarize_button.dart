import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_bloc.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_event.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_state.dart';

/// Triggers the polarizer microservice for the current article.
/// Hides once a biasReport result is available (the [BiasBadge] takes over).
///
/// Must be placed inside a [BiasReportBloc] scope.
class PolarizeButton extends StatelessWidget {
  final String articleId;
  final String userId;
  final String text;

  const PolarizeButton({
    super.key,
    required this.articleId,
    required this.userId,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BiasReportBloc, BiasReportState>(
      builder: (context, state) {
        // Hide once a report exists.
        final hasReport = switch (state) {
          BiasReportLoaded(:final report) => report != null,
          _ => false,
        };
        if (hasReport) return const SizedBox.shrink();

        final isProcessing = state is BiasReportProcessing;
        final isDisabled = userId.isEmpty || articleId.isEmpty || text.length < 50 || isProcessing;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () => context.read<BiasReportBloc>().add(
                    RunPolarize(articleId: articleId, text: text),
                  ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade600,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isProcessing)
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  )
                else
                  Icon(
                    Ionicons.stats_chart_outline,
                    size: 15,
                    color: isDisabled
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                const SizedBox(width: 8),
                Text(
                  isProcessing ? 'Analysing…' : 'Run Bias Analysis',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
