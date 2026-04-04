import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';

class GetArticlesParams {
  final String? category;
  const GetArticlesParams({this.category});
}

class GetArticleUseCase
    implements UseCase<Result<List<ArticleEntity>>, GetArticlesParams> {
  final ArticleRepository _articleRepository;

  GetArticleUseCase(this._articleRepository);

  @override
  Future<Result<List<ArticleEntity>>> call(GetArticlesParams params) {
    return _articleRepository.getNewsArticles(category: params.category);
  }
}
