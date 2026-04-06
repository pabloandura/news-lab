import 'package:equatable/equatable.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

abstract class FactCheckEvent extends Equatable {
  const FactCheckEvent();
  @override
  List<Object?> get props => [];
}

class LoadFactCheck extends FactCheckEvent {
  final String articleId;
  final String userId;
  const LoadFactCheck({required this.articleId, required this.userId});
  @override
  List<Object?> get props => [articleId, userId];
}

class RunBotCheck extends FactCheckEvent {
  final String articleId;
  final String userId;
  final String text;
  const RunBotCheck(
      {required this.articleId, required this.userId, required this.text});
  @override
  List<Object?> get props => [articleId, userId, text];
}

class SubmitVote extends FactCheckEvent {
  final String articleId;
  final String userId;
  final CommunityVote vote;
  const SubmitVote(
      {required this.articleId, required this.userId, required this.vote});
  @override
  List<Object?> get props => [articleId, userId, vote];
}
