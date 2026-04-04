import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';

class GetJournalistArticlesUseCase
    implements UseCase<Result<List<ArticleEntity>>, String> {
  final JournalistProfileRepository _repository;

  GetJournalistArticlesUseCase(this._repository);

  @override
  Future<Result<List<ArticleEntity>>> call(String params) {
    return _repository.getArticlesByAuthor(params);
  }
}
