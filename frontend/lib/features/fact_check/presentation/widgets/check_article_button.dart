import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.shade300
                    : const Color(0xFFE8621A),
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
                      color: const Color(0xFFE8621A),
                    ),
                  )
                else
                  Text(
                    '✦',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled
                          ? Colors.grey.shade400
                          : const Color(0xFFE8621A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  isProcessing ? 'Analysing…' : 'Run AI Fact-Check',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? Colors.grey.shade400
                        : const Color(0xFFE8621A),
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
