import 'package:equatable/equatable.dart';
import 'package:news_lab/features/analytics/domain/entities/bias_landscape_entity.dart';

abstract class BiasLandscapeState extends Equatable {
  const BiasLandscapeState();

  @override
  List<Object?> get props => [];
}

class BiasLandscapeInitial extends BiasLandscapeState {
  const BiasLandscapeInitial();
}

class BiasLandscapeLoading extends BiasLandscapeState {
  const BiasLandscapeLoading();
}

class BiasLandscapeLoaded extends BiasLandscapeState {
  final BiasLandscapeEntity landscape;

  const BiasLandscapeLoaded({required this.landscape});

  @override
  List<Object?> get props => [landscape];
}

class BiasLandscapeError extends BiasLandscapeState {
  final String message;

  const BiasLandscapeError({required this.message});

  @override
  List<Object?> get props => [message];
}
