import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/bias_report/data/data_sources/bias_report_remote_data_source.dart';
import 'package:news_lab/features/bias_report/data/data_sources/polarize_api_data_source.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/domain/repository/bias_report_repository.dart';

class BiasReportRepositoryImpl implements BiasReportRepository {
  final BiasReportRemoteDataSource _dataSource;
  final PolarizeApiDataSource _polarizeApi;

  const BiasReportRepositoryImpl(this._dataSource, this._polarizeApi);

  @override
  Future<Result<BiasReportEntity?>> getBiasReport(
      {required String articleId}) async {
    try {
      final model = await _dataSource.getBiasReport(articleId: articleId);
      return Success(model?.toEntity());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> runPolarize({
    required String articleId,
    required String text,
  }) async {
    try {
      await _polarizeApi.runPolarize(articleId: articleId, text: text);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Stream<BiasReportEntity?> watchBiasReport({required String articleId}) {
    return _dataSource
        .watchBiasReport(articleId: articleId)
        .map((model) => model?.toEntity());
  }
}
