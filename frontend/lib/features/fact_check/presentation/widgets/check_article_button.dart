import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_bloc.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_state.dart';

/// Triggers the fact-checker microservice for the current article.
/// Shows a loading indicator while processing and disappears once a
/// botCheck result arrives (the [BotCheckBadge] takes over from there).
///
/// Must be placed inside a [FactCheckBloc] scope.
class CheckArticleButton extends StatelessWidget {
  final String articleId;
  final String userId;
  final String text;

  const CheckArticleButton({
    super.key,
    required this.articleId,
    required this.userId,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FactCheckBloc, FactCheckState>(
      builder: (context, state) {
        // Hide once we have a real bot-check result.
        final hasBotCheck = switch (state) {
          FactCheckLoaded(:final factCheck) => factCheck.botCheck != null,
          FactCheckVoteSubmitting(:final optimistic) => optimistic.botCheck != null,
          FactCheckVoteError(:final reverted) => reverted.botCheck != null,
          _ => false,
        };
        if (hasBotCheck) return const SizedBox.shrink();

        final isProcessing = state is FactCheckBotCheckProcessing;
        final isDisabled = userId.isEmpty || text.length < 50 || isProcessing;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () => context.read<FactCheckBloc>().add(
                    RunBotCheck(
                      articleId: articleId,
                      userId: userId,
                      text: text,
                    ),
                  ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.shade100 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDisabled ? Colors.grey.shade300 : Colors.blue.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isProcessing)
                  SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.blue.shade600,
                    ),
                  )
                else
                  Icon(
                    Ionicons.shield_checkmark_outline,
                    size: 13,
                    color: isDisabled ? Colors.grey : Colors.blue.shade700,
                  ),
                const SizedBox(width: 5),
                Text(
                  isProcessing ? 'Analysing…' : 'Check article',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? Colors.grey : Colors.blue.shade700,
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
