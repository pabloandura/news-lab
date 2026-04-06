import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';

abstract class BiasReportRepository {
  Future<Result<BiasReportEntity?>> getBiasReport({required String articleId});
  Future<Result<Map<String, BiasReportEntity>>> batchGetBiasReports(List<String> articleIds);
  Future<Result<void>> runPolarize({
    required String articleId,
    required String text,
  });
  Stream<BiasReportEntity?> watchBiasReport({required String articleId});
}
