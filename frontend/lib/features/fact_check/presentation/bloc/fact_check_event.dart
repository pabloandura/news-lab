import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

abstract class FactCheckEvent {
  const FactCheckEvent();
}

class LoadFactCheck extends FactCheckEvent {
  final String articleId;
  final String userId;

  const LoadFactCheck({required this.articleId, required this.userId});
}

class SubmitVote extends FactCheckEvent {
  final String articleId;
  final String userId;
  final CommunityVote vote;

  const SubmitVote({
    required this.articleId,
    required this.userId,
    required this.vote,
  });
}
