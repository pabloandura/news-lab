import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';
import 'package:news_lab/features/similar_articles/domain/repository/similar_articles_repository.dart';

class GetSimilarArticlesUseCase
    implements UseCase<Result<List<SimilarArticleEntity>>, String> {
  final SimilarArticlesRepository _repository;

  GetSimilarArticlesUseCase(this._repository);

  @override
  Future<Result<List<SimilarArticleEntity>>> call(String articleId) {
    return _repository.getSimilarArticles(articleId);
  }
}
