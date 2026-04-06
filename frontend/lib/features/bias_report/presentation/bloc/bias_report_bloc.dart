import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/domain/usecases/get_bias_report_usecase.dart';
import 'package:news_lab/features/bias_report/domain/usecases/run_polarize_use_case.dart';
import 'package:news_lab/features/bias_report/domain/usecases/watch_bias_report_use_case.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_event.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_state.dart';

class BiasReportBloc extends Bloc<BiasReportEvent, BiasReportState> {
  final GetBiasReportUseCase _getBiasReport;
  final RunPolarizeUseCase _runPolarize;
  final WatchBiasReportUseCase _watchBiasReport;

  static const _listenerTimeout = Duration(seconds: 30);

  BiasReportBloc(this._getBiasReport, this._runPolarize, this._watchBiasReport)
      : super(const BiasReportInitial()) {
    on<LoadBiasReport>(_onLoad);
    on<RunPolarize>(_onRunPolarize);
  }

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
        await emit.forEach<BiasReportEntity>(
          _watchBiasReport(WatchBiasReportParams(articleId: event.articleId))
              .where((entity) => entity != null)
              .cast<BiasReportEntity>()
              .take(1)
              .timeout(
                _listenerTimeout,
                onTimeout: (sink) => sink.addError(
                  Exception('Analysis timed out. Please try again.'),
                ),
              ),
          onData: (entity) => BiasReportLoaded(entity),
          onError: (_, __) =>
              const BiasReportError('Analysis timed out. Please try again.'),
        );
    }
  }
}
