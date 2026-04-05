import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class GetArticleListFactChecksUseCase
    implements UseCase<Result<Map<String, FactCheckEntity>>, List<String>> {
  final FactCheckRepository _repository;

  GetArticleListFactChecksUseCase(this._repository);

  @override
  Future<Result<Map<String, FactCheckEntity>>> call(List<String> articleIds) {
    return _repository.batchGetFactChecks(articleIds);
  }
}
