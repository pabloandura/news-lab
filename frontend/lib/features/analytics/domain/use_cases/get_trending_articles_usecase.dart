import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/analytics/domain/repository/analytics_repository.dart';

class GetTrendingArticlesUseCase
    implements NoParamsUseCase<List<ArticleEntity>> {
  final AnalyticsRepository _repository;

  GetTrendingArticlesUseCase(this._repository);

  @override
  Future<List<ArticleEntity>> call() => _repository.getTrendingArticles();
}
