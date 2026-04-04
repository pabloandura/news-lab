import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';
import 'package:news_lab/features/publish_article/domain/entities/published_article_entity.dart';

class GetJournalistArticlesUseCase {
  final JournalistProfileRepository _repository;

  GetJournalistArticlesUseCase(this._repository);

  Future<Result<List<PublishedArticleEntity>>> call(String authorId) {
    return _repository.getArticlesByAuthor(authorId);
  }
}
