import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

abstract class FactCheckEvent {
  const FactCheckEvent();
}

class LoadFactCheck extends FactCheckEvent {
  final String articleId;
  final String userId;

  const LoadFactCheck({required this.articleId, required this.userId});
}

/// Triggers the fact-checker microservice for this article.
/// The BLoC fires an HTTP POST, then opens a Firestore listener;
/// when the result arrives the listener emits [_BotCheckResultArrived].
class RunBotCheck extends FactCheckEvent {
  final String articleId;
  final String userId;
  final String text;

  const RunBotCheck({
    required this.articleId,
    required this.userId,
    required this.text,
  });
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

