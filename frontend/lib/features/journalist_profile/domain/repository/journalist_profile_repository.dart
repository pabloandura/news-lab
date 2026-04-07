import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/journalist_profile_params.dart';

abstract class JournalistProfileRepository {
  Future<Result<List<ArticleEntity>>> getArticlesByAuthor(String authorId);
  Future<Result<void>> deleteArticle(String articleId);
  Future<Result<void>> updateArticle(UpdateArticleParams params);
}
