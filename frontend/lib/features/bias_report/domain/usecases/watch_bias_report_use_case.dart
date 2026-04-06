import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/domain/repository/bias_report_repository.dart';

class WatchBiasReportParams {
  final String articleId;
  const WatchBiasReportParams({required this.articleId});
}

class WatchBiasReportUseCase {
  final BiasReportRepository _repository;
  const WatchBiasReportUseCase(this._repository);

  Stream<BiasReportEntity?> call(WatchBiasReportParams params) =>
      _repository.watchBiasReport(articleId: params.articleId);
}
