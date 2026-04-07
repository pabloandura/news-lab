import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/analytics/domain/entities/author_stats_entity.dart';
import 'package:news_lab/features/analytics/domain/repository/analytics_repository.dart';

class GetAuthorStatsUseCase implements UseCase<AuthorStatsEntity, String> {
  final AnalyticsRepository _repository;

  GetAuthorStatsUseCase(this._repository);

  @override
  Future<AuthorStatsEntity> call(String authorId) =>
      _repository.getAuthorStats(authorId);
}
