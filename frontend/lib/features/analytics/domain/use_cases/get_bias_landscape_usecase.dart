import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/analytics/domain/entities/bias_landscape_entity.dart';
import 'package:news_lab/features/analytics/domain/repository/analytics_repository.dart';

class GetBiasLandscapeUseCase
    implements NoParamsUseCase<BiasLandscapeEntity> {
  final AnalyticsRepository _repository;

  GetBiasLandscapeUseCase(this._repository);

  @override
  Future<BiasLandscapeEntity> call() => _repository.getBiasLandscape();
}
