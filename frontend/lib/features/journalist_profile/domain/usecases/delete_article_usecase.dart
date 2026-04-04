import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';

class DeleteArticleUseCase {
  final JournalistProfileRepository _repository;

  DeleteArticleUseCase(this._repository);

  Future<Result<void>> call(String articleId) {
    return _repository.deleteArticle(articleId);
  }
}
