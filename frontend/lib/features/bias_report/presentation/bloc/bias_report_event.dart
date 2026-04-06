import 'package:equatable/equatable.dart';

abstract class BiasReportEvent extends Equatable {
  const BiasReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadBiasReport extends BiasReportEvent {
  final String articleId;
  const LoadBiasReport({required this.articleId});

  @override
  List<Object?> get props => [articleId];
}

class RunPolarize extends BiasReportEvent {
  final String articleId;
  final String text;

  const RunPolarize({required this.articleId, required this.text});

  @override
  List<Object?> get props => [articleId, text];
}
