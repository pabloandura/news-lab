import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class GetFactCheckParams {
  final String articleId;
  final String userId;

  const GetFactCheckParams({required this.articleId, required this.userId});
}

class GetFactCheckUseCase
    implements UseCase<Result<FactCheckEntity>, GetFactCheckParams> {
  final FactCheckRepository _repository;

  GetFactCheckUseCase(this._repository);

  @override
  Future<Result<FactCheckEntity>> call(GetFactCheckParams params) {
    return _repository.getFactCheck(
      articleId: params.articleId,
      userId: params.userId,
    );
  }
}
