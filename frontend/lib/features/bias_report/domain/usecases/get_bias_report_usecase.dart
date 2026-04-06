import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/domain/repository/bias_report_repository.dart';

class GetBiasReportParams {
  final String articleId;
  const GetBiasReportParams({required this.articleId});
}

class GetBiasReportUseCase
    implements UseCase<Result<BiasReportEntity?>, GetBiasReportParams> {
  final BiasReportRepository _repository;
  const GetBiasReportUseCase(this._repository);

  @override
  Future<Result<BiasReportEntity?>> call(GetBiasReportParams params) =>
      _repository.getBiasReport(articleId: params.articleId);
}
