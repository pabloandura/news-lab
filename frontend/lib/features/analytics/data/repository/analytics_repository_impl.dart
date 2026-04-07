import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/analytics/data/data_sources/analytics_remote_data_source.dart';
import 'package:news_lab/features/analytics/domain/entities/author_stats_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/bias_landscape_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/daily_views_entity.dart';
import 'package:news_lab/features/analytics/domain/repository/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource _dataSource;

  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<List<ArticleEntity>> getTrendingArticles() =>
      _dataSource.getTrendingArticles();

  @override
  Future<BiasLandscapeEntity> getBiasLandscape() =>
      _dataSource.getBiasLandscape();

  @override
  Future<AuthorStatsEntity> getAuthorStats(String authorId) =>
      _dataSource.getAuthorStats(authorId);

  @override
  Future<List<DailyViewsEntity>> getWeeklyViews(String authorId) =>
      _dataSource.getWeeklyViews(authorId);
}
