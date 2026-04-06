import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/domain/repository/bias_report_repository.dart';

class GetArticleListBiasReportsUseCase
    implements UseCase<Result<Map<String, BiasReportEntity>>, List<String>> {
  final BiasReportRepository _repository;

  GetArticleListBiasReportsUseCase(this._repository);

  @override
  Future<Result<Map<String, BiasReportEntity>>> call(List<String> articleIds) {
    return _repository.batchGetBiasReports(articleIds);
  }
}
