import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';

class DeleteArticleUseCase implements UseCase<Result<void>, String> {
  final JournalistProfileRepository _repository;

  DeleteArticleUseCase(this._repository);

  @override
  Future<Result<void>> call(String params) {
    return _repository.deleteArticle(params);
  }
}
