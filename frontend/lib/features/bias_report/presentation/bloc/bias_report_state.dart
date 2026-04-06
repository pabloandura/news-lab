import 'package:equatable/equatable.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';

sealed class BiasReportState extends Equatable {
  const BiasReportState();

  @override
  List<Object?> get props => [];
}

class BiasReportInitial extends BiasReportState {
  const BiasReportInitial();
}

class BiasReportLoading extends BiasReportState {
  const BiasReportLoading();
}

class BiasReportLoaded extends BiasReportState {
  final BiasReportEntity? report;
  const BiasReportLoaded(this.report);

  @override
  List<Object?> get props => [report];
}

/// Fired after POST /polarize — waiting for Firestore update.
class BiasReportProcessing extends BiasReportState {
  final BiasReportEntity? current;
  const BiasReportProcessing(this.current);

  @override
  List<Object?> get props => [current];
}

class BiasReportError extends BiasReportState {
  final String message;
  const BiasReportError(this.message);

  @override
  List<Object?> get props => [message];
}
