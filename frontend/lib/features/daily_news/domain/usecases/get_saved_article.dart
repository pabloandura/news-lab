import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';

class GetSavedArticleUseCase
    implements NoParamsUseCase<Result<List<ArticleEntity>>> {
  final ArticleRepository _articleRepository;

  GetSavedArticleUseCase(this._articleRepository);

  @override
  Future<Result<List<ArticleEntity>>> call() {
    return _articleRepository.getSavedArticles();
  }
}
