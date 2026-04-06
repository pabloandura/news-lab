import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/domain/usecases/get_bias_report_usecase.dart';
import 'package:news_lab/features/bias_report/domain/usecases/run_polarize_use_case.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_event.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_state.dart';

// Internal — fires when the Firestore listener receives a biasReport result.
class _BiasReportResultArrived extends BiasReportEvent {
  final BiasReportEntity report;
  const _BiasReportResultArrived(this.report);
}

// Internal — fires when the 30-second listener timeout elapses.
class _BiasReportTimedOut extends BiasReportEvent {
  const _BiasReportTimedOut();
}

class BiasReportBloc extends Bloc<BiasReportEvent, BiasReportState> {
  final GetBiasReportUseCase _getBiasReport;
  final RunPolarizeUseCase _runPolarize;
  final FirebaseFirestore _firestore;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _listener;
  Timer? _timeout;

  static const _listenerTimeout = Duration(seconds: 30);

  BiasReportBloc(this._getBiasReport, this._runPolarize, this._firestore)
      : super(const BiasReportInitial()) {
    on<LoadBiasReport>(_onLoad);
    on<RunPolarize>(_onRunPolarize);
    on<_BiasReportResultArrived>(_onResultArrived);
    on<_BiasReportTimedOut>(_onTimedOut);
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      LoadBiasReport event, Emitter<BiasReportState> emit) async {
    emit(const BiasReportLoading());
    final result =
        await _getBiasReport(GetBiasReportParams(articleId: event.articleId));
    switch (result) {
      case Success<BiasReportEntity?>():
        emit(BiasReportLoaded(result.data));
      case Failure<BiasReportEntity?>():
        emit(BiasReportError(result.message));
    }
  }

  // ── Run polarize ──────────────────────────────────────────────────────────

  Future<void> _onRunPolarize(
      RunPolarize event, Emitter<BiasReportState> emit) async {
    final current = switch (state) {
      BiasReportLoaded(:final report) => report,
      BiasReportProcessing(:final current) => current,
      _ => null,
    };

    final result = await _runPolarize(
      RunPolarizeParams(articleId: event.articleId, text: event.text),
    );

    switch (result) {
      case Failure():
        emit(BiasReportError(result.message));
        return;
      case Success():
        emit(BiasReportProcessing(current));
        _startListener(event.articleId);
    }
  }

  void _startListener(String articleId) {
    _cancel();

    _listener = _firestore
        .collection(articlesCollection)
        .doc(articleId)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null || data['biasReport'] == null) return;

      final report = _parseReport(data['biasReport'] as Map<String, dynamic>);
      if (report != null) add(_BiasReportResultArrived(report));
    });

    _timeout = Timer(_listenerTimeout, () => add(const _BiasReportTimedOut()));
  }

  void _onResultArrived(
      _BiasReportResultArrived event, Emitter<BiasReportState> emit) {
    _cancel();
    emit(BiasReportLoaded(event.report));
  }

  void _onTimedOut(
      _BiasReportTimedOut event, Emitter<BiasReportState> emit) {
    _cancel();
    if (state is BiasReportProcessing) {
      emit(const BiasReportError('Analysis timed out. Please try again.'));
    }
  }

  BiasReportEntity? _parseReport(Map<String, dynamic> map) {
    try {
      return BiasReportEntity(
        politicalLean: (map['politicalLean'] as num).toDouble(),
        emotionalLanguageScore:
            (map['emotionalLanguageScore'] as num).toDouble(),
        framingNotes: (map['framingNotes'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        analyzedAt: (map['analyzedAt'] as Timestamp?)?.toDate(),
      );
    } catch (_) {
      return null;
    }
  }

  void _cancel() {
    _listener?.cancel();
    _listener = null;
    _timeout?.cancel();
    _timeout = null;
  }

  @override
  Future<void> close() {
    _cancel();
    return super.close();
  }
}
