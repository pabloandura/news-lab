import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/daily_news/domain/entities/article.dart';

abstract class ArticleRepository {
  Future<Result<List<ArticleEntity>>> getNewsArticles({String? category});
  Future<Result<List<ArticleEntity>>> getSavedArticles();
  Future<Result<void>> saveArticle(ArticleEntity article);
  Future<Result<void>> removeArticle(ArticleEntity article);
}
