import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_bloc.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_state.dart';

class CommunityCheckBadge extends StatelessWidget {
  final CommunityCheckEntity communityCheck;
  final String articleId;
  final String userId;

  const CommunityCheckBadge({
    super.key,
    required this.communityCheck,
    required this.articleId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 13, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(
              '${communityCheck.totalVotes} community votes',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    final bloc = context.read<FactCheckBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _CommunityCheckBottomSheet(
          initial: communityCheck,
          articleId: articleId,
          userId: userId,
        ),
      ),
    );
  }
}

class _CommunityCheckBottomSheet extends StatelessWidget {
  final CommunityCheckEntity initial;
  final String articleId;
  final String userId;

  const _CommunityCheckBottomSheet({
    required this.initial,
    required this.articleId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FactCheckBloc, FactCheckState>(
      builder: (context, state) {
        final community = switch (state) {
          FactCheckLoaded() => state.factCheck.communityCheck ?? initial,
          FactCheckVoteSubmitting() =>
            state.optimistic.communityCheck ?? initial,
          FactCheckVoteError() => state.reverted.communityCheck ?? initial,
          _ => initial,
        };

        final isSubmitting = state is FactCheckVoteSubmitting;
        final hasError = state is FactCheckVoteError;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Community Fact Check',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Voted on by ${community.totalVotes} reader${community.totalVotes == 1 ? '' : 's'}.',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 20),
              _VoteBar(
                label: 'Accurate',
                votes: community.accurateVotes,
                total: community.totalVotes,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 10),
              _VoteBar(
                label: 'Inaccurate',
                votes: community.inaccurateVotes,
                total: community.totalVotes,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 10),
              _VoteBar(
                label: 'Unsure',
                votes: community.unsureVotes,
                total: community.totalVotes,
                color: Colors.grey.shade400,
              ),
              if (hasError) ...[
                const SizedBox(height: 12),
                Text(
                  'Failed to submit vote. Please try again.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ],
              const SizedBox(height: 24),
              if (userId.isEmpty)
                const Text(
                  'Sign in to cast your vote.',
                  style: TextStyle(fontSize: 13, color: Colors.black38),
                )
              else ...[
              Text(
                community.userVote != null
                    ? 'Change your vote:'
                    : 'Cast your vote:',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _VoteButton(
                    label: 'Accurate',
                    icon: Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    isSelected: community.userVote == CommunityVote.accurate,
                    isLoading: isSubmitting,
                    onTap: () => context.read<FactCheckBloc>().add(SubmitVote(
                          articleId: articleId,
                          userId: userId,
                          vote: CommunityVote.accurate,
                        )),
                  ),
                  const SizedBox(width: 8),
                  _VoteButton(
                    label: 'Inaccurate',
                    icon: Icons.cancel_outlined,
                    color: Colors.red.shade600,
                    isSelected: community.userVote == CommunityVote.inaccurate,
                    isLoading: isSubmitting,
                    onTap: () => context.read<FactCheckBloc>().add(SubmitVote(
                          articleId: articleId,
                          userId: userId,
                          vote: CommunityVote.inaccurate,
                        )),
                  ),
                  const SizedBox(width: 8),
                  _VoteButton(
                    label: 'Unsure',
                    icon: Icons.help_outline,
                    color: Colors.grey.shade600,
                    isSelected: community.userVote == CommunityVote.unsure,
                    isLoading: isSubmitting,
                    onTap: () => context.read<FactCheckBloc>().add(SubmitVote(
                          articleId: articleId,
                          userId: userId,
                          vote: CommunityVote.unsure,
                        )),
                  ),
                ],
              ),
              ], // end else voting controls
            ],
          ),
        );
      },
    );
  }
}

class _VoteBar extends StatelessWidget {
  final String label;
  final int votes;
  final int total;
  final Color color;

  const _VoteBar({
    required this.label,
    required this.votes,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : votes / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ),
            Text(
              '$votes (${(pct * 100).round()}%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.black.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.black.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              isLoading && isSelected
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  : Icon(icon, size: 18, color: isSelected ? color : Colors.black45),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? color : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
