import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';

abstract class ArticleRepository {
  Future<Result<List<ArticleEntity>>> getNewsArticles({String? category});
  Future<Result<List<ArticleEntity>>> getSavedArticles();
  Future<Result<void>> saveArticle(ArticleEntity article);
  Future<Result<void>> removeArticle(ArticleEntity article);
}
