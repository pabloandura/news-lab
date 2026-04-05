import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/fact_check/data/data_sources/fact_check_remote_data_source.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class FactCheckRepositoryImpl implements FactCheckRepository {
  final FactCheckRemoteDataSource _dataSource;

  FactCheckRepositoryImpl(this._dataSource);

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
