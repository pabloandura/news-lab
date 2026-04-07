import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/author_stats_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/bias_landscape_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/daily_views_entity.dart';

abstract class AnalyticsRepository {
  Future<List<ArticleEntity>> getTrendingArticles();
  Future<BiasLandscapeEntity> getBiasLandscape();
  Future<AuthorStatsEntity> getAuthorStats(String authorId);
  Future<List<DailyViewsEntity>> getWeeklyViews(String authorId);
}
