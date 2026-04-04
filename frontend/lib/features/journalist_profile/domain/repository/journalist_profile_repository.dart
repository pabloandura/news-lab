import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';

abstract class JournalistProfileRepository {
  Future<Result<List<ArticleEntity>>> getArticlesByAuthor(String authorId);
  Future<Result<void>> deleteArticle(String articleId);
  Future<Result<void>> updateArticle(UpdateArticleParams params);
}

class UpdateArticleParams {
  final String articleId;
  final String title;
  final String description;
  final String content;
  final String? category;
  final String? localImagePath;
  final String existingThumbnailUrl;

  const UpdateArticleParams({
    required this.articleId,
    required this.title,
    required this.description,
    required this.content,
    this.category,
    this.localImagePath,
    required this.existingThumbnailUrl,
  });
}
