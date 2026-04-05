import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_fact_check_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/submit_community_vote_usecase.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_state.dart';

class FactCheckBloc extends Bloc<FactCheckEvent, FactCheckState> {
  final GetFactCheckUseCase _getFactCheck;
  final SubmitCommunityVoteUseCase _submitVote;

  FactCheckBloc(this._getFactCheck, this._submitVote)
      : super(const FactCheckInitial()) {
    on<LoadFactCheck>(_onLoad);
    on<SubmitVote>(_onSubmitVote);
  }

  Future<void> _onLoad(LoadFactCheck event, Emitter<FactCheckState> emit) async {
    emit(const FactCheckLoading());
    final result = await _getFactCheck(
      GetFactCheckParams(articleId: event.articleId, userId: event.userId),
    );
    switch (result) {
      case Success<FactCheckEntity>():
        emit(FactCheckLoaded(result.data));
      case Failure<FactCheckEntity>():
        emit(FactCheckError(result.message));
    }
  }

  Future<void> _onSubmitVote(
      SubmitVote event, Emitter<FactCheckState> emit) async {
    if (state is FactCheckVoteSubmitting) return;

    final current = state;
    final currentEntity = switch (current) {
      FactCheckLoaded() => current.factCheck,
      FactCheckVoteError() => current.reverted,
      _ => null,
    };

    if (currentEntity == null || currentEntity.communityCheck == null) return;

    final previous = currentEntity.communityCheck!;
    final optimistic = _applyOptimisticVote(previous, event.vote);

    emit(FactCheckVoteSubmitting(
      currentEntity.copyWith(communityCheck: optimistic),
    ));

    final result = await _submitVote(SubmitVoteParams(
      articleId: event.articleId,
      userId: event.userId,
      vote: event.vote,
    ));

    switch (result) {
      case Success<void>():
        emit(FactCheckLoaded(
          currentEntity.copyWith(communityCheck: optimistic),
        ));
      case Failure<void>():
        emit(FactCheckVoteError(
          reverted: currentEntity,
          message: result.message,
        ));
    }
  }

  CommunityCheckEntity _applyOptimisticVote(
    CommunityCheckEntity current,
    CommunityVote newVote,
  ) {
    var accurate = current.accurateVotes;
    var inaccurate = current.inaccurateVotes;
    var unsure = current.unsureVotes;

    // Decrement the previous vote if the user had one
    if (current.userVote != null && current.userVote != newVote) {
      switch (current.userVote!) {
        case CommunityVote.accurate:
          accurate = (accurate - 1).clamp(0, double.maxFinite.toInt());
        case CommunityVote.inaccurate:
          inaccurate = (inaccurate - 1).clamp(0, double.maxFinite.toInt());
        case CommunityVote.unsure:
          unsure = (unsure - 1).clamp(0, double.maxFinite.toInt());
      }
    }

    // Increment the new vote (only if not re-voting the same option)
    if (current.userVote != newVote) {
      switch (newVote) {
        case CommunityVote.accurate:
          accurate++;
        case CommunityVote.inaccurate:
          inaccurate++;
        case CommunityVote.unsure:
          unsure++;
      }
    }

    return current.copyWith(
      accurateVotes: accurate,
      inaccurateVotes: inaccurate,
      unsureVotes: unsure,
      userVote: newVote,
    );
  }
}
