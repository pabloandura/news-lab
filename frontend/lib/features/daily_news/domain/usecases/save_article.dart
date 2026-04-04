import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';

class SaveArticleUseCase implements UseCase<Result<void>, ArticleEntity> {
  final ArticleRepository _articleRepository;

  SaveArticleUseCase(this._articleRepository);

  @override
  Future<Result<void>> call(ArticleEntity params) {
    return _articleRepository.saveArticle(params);
  }
}
