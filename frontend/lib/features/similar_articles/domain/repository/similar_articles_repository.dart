import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';

abstract class SimilarArticlesRepository {
  Future<Result<List<SimilarArticleEntity>>> getSimilarArticles(String articleId);
}
