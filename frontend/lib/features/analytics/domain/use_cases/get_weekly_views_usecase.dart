import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/analytics/domain/entities/daily_views_entity.dart';
import 'package:news_lab/features/analytics/domain/repository/analytics_repository.dart';

class GetWeeklyViewsUseCase
    implements UseCase<List<DailyViewsEntity>, String> {
  final AnalyticsRepository _repository;

  GetWeeklyViewsUseCase(this._repository);

  @override
  Future<List<DailyViewsEntity>> call(String authorId) =>
      _repository.getWeeklyViews(authorId);
}
