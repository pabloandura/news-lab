import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/daily_news/domain/entities/article.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';

class GetArticleUseCase
    implements UseCase<Result<List<ArticleEntity>>, void> {
  final ArticleRepository _articleRepository;

  GetArticleUseCase(this._articleRepository);

  @override
  Future<Result<List<ArticleEntity>>> call({void params}) {
    return _articleRepository.getNewsArticles();
  }

  Future<Result<List<ArticleEntity>>> callWithCategory({String? category}) {
    return _articleRepository.getNewsArticles(category: category);
  }
}
