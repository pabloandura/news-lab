import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_fact_check_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/run_bot_check_use_case.dart';
import 'package:news_lab/features/fact_check/domain/usecases/submit_community_vote_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/watch_bot_check_use_case.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_state.dart';

class FactCheckBloc extends Bloc<FactCheckEvent, FactCheckState> {
  final GetFactCheckUseCase _getFactCheck;
  final RunBotCheckUseCase _runBotCheck;
  final SubmitCommunityVoteUseCase _submitVote;
  final WatchBotCheckUseCase _watchBotCheck;

  static const _listenerTimeout = Duration(seconds: 30);

  FactCheckBloc(
      this._getFactCheck, this._runBotCheck, this._submitVote, this._watchBotCheck)
      : super(const FactCheckInitial()) {
    on<LoadFactCheck>(_onLoad);
    on<RunBotCheck>(_onRunBotCheck);
    on<SubmitVote>(_onSubmitVote);
  }

  Future<void> _onLoad(
      LoadFactCheck event, Emitter<FactCheckState> emit) async {
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

  Future<void> _onRunBotCheck(
      RunBotCheck event, Emitter<FactCheckState> emit) async {
    final current = switch (state) {
      FactCheckLoaded(:final factCheck) => factCheck,
      FactCheckVoteSubmitting(:final optimistic) => optimistic,
      FactCheckVoteError(:final reverted) => reverted,
      _ => FactCheckEntity(articleId: event.articleId),
    };

    final result = await _runBotCheck(
      RunBotCheckParams(articleId: event.articleId, text: event.text),
    );

    switch (result) {
      case Failure():
        emit(FactCheckError(result.message));
        return;
      case Success():
        emit(FactCheckBotCheckProcessing(current));
        await emit.forEach<BotCheckEntity>(
          _watchBotCheck(WatchBotCheckParams(articleId: event.articleId))
              .where((e) => e != null)
              .cast<BotCheckEntity>()
              .take(1)
              .timeout(
                _listenerTimeout,
                onTimeout: (sink) => sink.addError(
                  Exception('Analysis timed out. Please try again.'),
                ),
              ),
          onData: (botCheck) {
            final entity = switch (state) {
              FactCheckBotCheckProcessing(:final current) => current,
              FactCheckLoaded(:final factCheck) => factCheck,
              FactCheckVoteSubmitting(:final optimistic) => optimistic,
              FactCheckVoteError(:final reverted) => reverted,
              _ => FactCheckEntity(articleId: event.articleId),
            };
            return FactCheckLoaded(entity.copyWith(botCheck: botCheck));
          },
          onError: (_, __) =>
              const FactCheckError('Analysis timed out. Please try again.'),
        );
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
    if (currentEntity == null) return;

    final previous = currentEntity.communityCheck ??
        const CommunityCheckEntity(
          accurateVotes: 0,
          inaccurateVotes: 0,
          unsureVotes: 0,
        );
    final optimistic = _applyOptimisticVote(previous, event.vote);
    emit(FactCheckVoteSubmitting(currentEntity.copyWith(communityCheck: optimistic)));

    final result = await _submitVote(SubmitVoteParams(
      articleId: event.articleId,
      userId: event.userId,
      vote: event.vote,
    ));
    switch (result) {
      case Success<void>():
        emit(FactCheckLoaded(currentEntity.copyWith(communityCheck: optimistic)));
      case Failure<void>():
        emit(FactCheckVoteError(reverted: currentEntity, message: result.message));
    }
  }

  CommunityCheckEntity _applyOptimisticVote(
      CommunityCheckEntity current, CommunityVote newVote) {
    var accurate = current.accurateVotes;
    var inaccurate = current.inaccurateVotes;
    var unsure = current.unsureVotes;

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

    if (current.userVote != newVote) {
      switch (newVote) {
        case CommunityVote.accurate: accurate++;
        case CommunityVote.inaccurate: inaccurate++;
        case CommunityVote.unsure: unsure++;
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
