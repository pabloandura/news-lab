import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

abstract class FactCheckRepository {
  Future<Result<void>> runBotCheck({
    required String articleId,
    required String text,
  });

  Future<Result<FactCheckEntity>> getFactCheck({
    required String articleId,
    required String userId,
  });

  Future<Result<Map<String, FactCheckEntity>>> batchGetFactChecks(
      List<String> articleIds);

  Future<Result<void>> submitVote({
    required String articleId,
    required String userId,
    required CommunityVote vote,
  });
  Stream<BotCheckEntity?> watchBotCheck({required String articleId});
}
