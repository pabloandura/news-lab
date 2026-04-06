import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_fact_check_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/run_bot_check_use_case.dart';
import 'package:news_lab/features/fact_check/domain/usecases/submit_community_vote_usecase.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_state.dart';

// Internal — fires when the Firestore listener receives a botCheck result.
class _BotCheckResultArrived extends FactCheckEvent {
  final BotCheckEntity botCheck;
  final String articleId;

  const _BotCheckResultArrived({required this.botCheck, required this.articleId});
}

// Internal — fires when the 30-second listener timeout elapses.
class _BotCheckTimedOut extends FactCheckEvent {
  const _BotCheckTimedOut();
}

class FactCheckBloc extends Bloc<FactCheckEvent, FactCheckState> {
  final GetFactCheckUseCase _getFactCheck;
  final RunBotCheckUseCase _runBotCheck;
  final SubmitCommunityVoteUseCase _submitVote;
  final FirebaseFirestore _firestore;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _botCheckListener;
  Timer? _botCheckTimeout;

  static const _listenerTimeout = Duration(seconds: 30);

  FactCheckBloc(
    this._getFactCheck,
    this._runBotCheck,
    this._submitVote,
    this._firestore,
  ) : super(const FactCheckInitial()) {
    on<LoadFactCheck>(_onLoad);
    on<RunBotCheck>(_onRunBotCheck);
    on<_BotCheckResultArrived>(_onBotCheckResultArrived);
    on<_BotCheckTimedOut>(_onBotCheckTimedOut);
    on<SubmitVote>(_onSubmitVote);
  }

  // ── Load ─────────────────────────────────────────────────────────────────

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

  // ── Run bot check ─────────────────────────────────────────────────────────

  Future<void> _onRunBotCheck(RunBotCheck event, Emitter<FactCheckState> emit) async {
    // Derive the current entity to carry into the processing state.
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
        _startBotCheckListener(event.articleId, event.userId);
    }
  }

  void _startBotCheckListener(String articleId, String userId) {
    _cancelBotCheckListener();

    _botCheckListener = _firestore
        .collection(factChecksCollection)
        .doc(articleId)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null || data['botCheck'] == null) return;

      final botCheck = _parseBotCheck(data['botCheck'] as Map<String, dynamic>);
      if (botCheck != null) {
        add(_BotCheckResultArrived(botCheck: botCheck, articleId: articleId));
      }
    });

    _botCheckTimeout = Timer(_listenerTimeout, () {
      add(const _BotCheckTimedOut());
    });
  }

  void _onBotCheckTimedOut(
    _BotCheckTimedOut event,
    Emitter<FactCheckState> emit,
  ) {
    _cancelBotCheckListener();
    if (state is FactCheckBotCheckProcessing) {
      emit(const FactCheckError('Analysis timed out. Please try again.'));
    }
  }

  void _onBotCheckResultArrived(
    _BotCheckResultArrived event,
    Emitter<FactCheckState> emit,
  ) {
    _cancelBotCheckListener();

    final current = switch (state) {
      FactCheckBotCheckProcessing(:final current) => current,
      FactCheckLoaded(:final factCheck) => factCheck,
      _ => FactCheckEntity(articleId: event.articleId),
    };

    emit(FactCheckLoaded(current.copyWith(botCheck: event.botCheck)));
  }

  BotCheckEntity? _parseBotCheck(Map<String, dynamic> map) {
    try {
      return BotCheckEntity(
        flaggedSentencesPercent: (map['flaggedSentencesPercent'] as num).toDouble(),
        confidenceScore: (map['confidenceScore'] as num).toDouble(),
        checkedAt: (map['checkedAt'] as Timestamp?)?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }

  void _cancelBotCheckListener() {
    _botCheckListener?.cancel();
    _botCheckListener = null;
    _botCheckTimeout?.cancel();
    _botCheckTimeout = null;
  }

  // ── Vote ─────────────────────────────────────────────────────────────────

  Future<void> _onSubmitVote(SubmitVote event, Emitter<FactCheckState> emit) async {
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
    CommunityCheckEntity current,
    CommunityVote newVote,
  ) {
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

  @override
  Future<void> close() {
    _cancelBotCheckListener();
    return super.close();
  }
}
