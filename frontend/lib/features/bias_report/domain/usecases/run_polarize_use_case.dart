import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/bias_report/domain/repository/bias_report_repository.dart';

class RunPolarizeParams {
  final String articleId;
  final String text;
  const RunPolarizeParams({required this.articleId, required this.text});
}

class RunPolarizeUseCase implements UseCase<Result<void>, RunPolarizeParams> {
  final BiasReportRepository _repository;
  const RunPolarizeUseCase(this._repository);

  @override
  Future<Result<void>> call(RunPolarizeParams params) =>
      _repository.runPolarize(
        articleId: params.articleId,
        text: params.text,
      );
}
