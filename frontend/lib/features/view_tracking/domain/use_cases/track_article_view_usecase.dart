import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/view_tracking/domain/repository/view_tracking_repository.dart';

class TrackArticleViewParams {
  final String articleId;
  final String authorId;

  const TrackArticleViewParams({
    required this.articleId,
    required this.authorId,
  });
}

class TrackArticleViewUseCase
    implements UseCase<void, TrackArticleViewParams> {
  final ViewTrackingRepository _repository;

  TrackArticleViewUseCase(this._repository);

  @override
  Future<void> call(TrackArticleViewParams params) {
    return _repository.trackView(
      articleId: params.articleId,
      authorId: params.authorId,
    );
  }
}
