import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class RunBotCheckParams {
  final String articleId;
  final String text;

  const RunBotCheckParams({required this.articleId, required this.text});
}

class RunBotCheckUseCase implements UseCase<Result<void>, RunBotCheckParams> {
  final FactCheckRepository _repository;

  RunBotCheckUseCase(this._repository);

  @override
  Future<Result<void>> call(RunBotCheckParams params) {
    return _repository.runBotCheck(
      articleId: params.articleId,
      text: params.text,
    );
  }
}
