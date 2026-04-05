import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class SubmitVoteParams {
  final String articleId;
  final String userId;
  final CommunityVote vote;

  const SubmitVoteParams({
    required this.articleId,
    required this.userId,
    required this.vote,
  });
}

class SubmitCommunityVoteUseCase
    implements UseCase<Result<void>, SubmitVoteParams> {
  final FactCheckRepository _repository;

  SubmitCommunityVoteUseCase(this._repository);

  @override
  Future<Result<void>> call(SubmitVoteParams params) {
    return _repository.submitVote(
      articleId: params.articleId,
      userId: params.userId,
      vote: params.vote,
    );
  }
}
