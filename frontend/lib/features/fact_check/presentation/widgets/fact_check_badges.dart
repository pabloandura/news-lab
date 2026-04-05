import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_bloc.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_state.dart';
import 'package:news_lab/features/fact_check/presentation/widgets/bot_check_badge.dart';
import 'package:news_lab/features/fact_check/presentation/widgets/community_check_badge.dart';

/// Orchestrates both fact-check badges. Renders nothing if no data is present.
/// Must be placed inside a [FactCheckBloc] scope.
class FactCheckBadges extends StatelessWidget {
  final String articleId;
  final String userId;

  const FactCheckBadges({
    super.key,
    required this.articleId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FactCheckBloc, FactCheckState>(
      builder: (context, state) {
        if (state is FactCheckLoading) {
          return _SkeletonBadges();
        }

        final factCheck = switch (state) {
          FactCheckLoaded() => state.factCheck,
          FactCheckVoteSubmitting() => state.optimistic,
          FactCheckVoteError() => state.reverted,
          _ => null,
        };

        if (factCheck == null) return const SizedBox.shrink();

        final hasBotCheck = factCheck.botCheck != null;
        final hasCommunityCheck = factCheck.communityCheck != null;

        if (!hasBotCheck && !hasCommunityCheck) return const SizedBox.shrink();

        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (hasBotCheck)
              BotCheckBadge(botCheck: factCheck.botCheck!),
            if (hasCommunityCheck)
              CommunityCheckBadge(
                communityCheck: factCheck.communityCheck!,
                articleId: articleId,
                userId: userId,
              ),
          ],
        );
      },
    );
  }
}

class _SkeletonBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _SkeletonChip(width: 90),
        _SkeletonChip(width: 120),
      ],
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  final double width;

  const _SkeletonChip({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
