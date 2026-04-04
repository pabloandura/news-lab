import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';

class UpdateArticleUseCase {
  final JournalistProfileRepository _repository;

  UpdateArticleUseCase(this._repository);

  Future<Result<void>> call(UpdateArticleParams params) {
    return _repository.updateArticle(params);
  }
}
