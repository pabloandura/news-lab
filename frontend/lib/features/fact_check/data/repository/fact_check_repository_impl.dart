import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/fact_check/data/data_sources/bot_check_api_data_source.dart';
import 'package:news_lab/features/fact_check/data/data_sources/fact_check_remote_data_source.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class FactCheckRepositoryImpl implements FactCheckRepository {
  final FactCheckRemoteDataSource _dataSource;
  final BotCheckApiDataSource _botCheckApi;

  FactCheckRepositoryImpl(this._dataSource, this._botCheckApi);

  @override
  Future<Result<void>> runBotCheck({
    required String articleId,
    required String text,
  }) async {
    try {
      await _botCheckApi.runBotCheck(articleId: articleId, text: text);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<FactCheckEntity>> getFactCheck({
    required String articleId,
    required String userId,
  }) async {
    try {
      final model = await _dataSource.getFactCheck(
        articleId: articleId,
        userId: userId,
      );
      return Success(model.toEntity());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<Map<String, FactCheckEntity>>> batchGetFactChecks(
      List<String> articleIds) async {
    try {
      final models = await _dataSource.batchGetFactChecks(articleIds);
      return Success(models.map((id, m) => MapEntry(id, m.toEntity())));
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> submitVote({
    required String articleId,
    required String userId,
    required CommunityVote vote,
  }) async {
    try {
      await _dataSource.submitVote(
        articleId: articleId,
        userId: userId,
        vote: vote,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
