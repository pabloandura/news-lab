import 'package:equatable/equatable.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

sealed class FactCheckState extends Equatable {
  const FactCheckState();

  @override
  List<Object?> get props => [];
}

class FactCheckInitial extends FactCheckState {
  const FactCheckInitial();
}

class FactCheckLoading extends FactCheckState {
  const FactCheckLoading();
}

class FactCheckLoaded extends FactCheckState {
  final FactCheckEntity factCheck;

  const FactCheckLoaded(this.factCheck);

  @override
  List<Object?> get props => [factCheck];
}

class FactCheckError extends FactCheckState {
  final String message;

  const FactCheckError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted while a vote is in flight. Carries the optimistic entity so the UI
/// can update immediately without waiting for Firestore.
class FactCheckVoteSubmitting extends FactCheckState {
  final FactCheckEntity optimistic;

  const FactCheckVoteSubmitting(this.optimistic);

  @override
  List<Object?> get props => [optimistic];
}

/// Emitted after a vote fails. Carries the pre-vote entity so the UI reverts.
class FactCheckVoteError extends FactCheckState {
  final FactCheckEntity reverted;
  final String message;

  const FactCheckVoteError({required this.reverted, required this.message});

  @override
  List<Object?> get props => [reverted, message];
}

/// Emitted after RunBotCheck is dispatched and the 202 is received.
/// The UI shows a spinner; when the Firestore listener fires, transitions to [FactCheckLoaded].
class FactCheckBotCheckProcessing extends FactCheckState {
  final FactCheckEntity current;

  const FactCheckBotCheckProcessing(this.current);

  @override
  List<Object?> get props => [current];
}
