import 'package:equatable/equatable.dart';

enum CommunityVote { accurate, inaccurate, unsure }

class BotCheckEntity extends Equatable {
  final double flaggedSentencesPercent;
  final double confidenceScore;
  final DateTime? checkedAt;

  const BotCheckEntity({
    required this.flaggedSentencesPercent,
    required this.confidenceScore,
    this.checkedAt,
  });

  @override
  List<Object?> get props => [flaggedSentencesPercent, confidenceScore, checkedAt];
}

class CommunityCheckEntity extends Equatable {
  final int accurateVotes;
  final int inaccurateVotes;
  final int unsureVotes;
  final CommunityVote? userVote;

  const CommunityCheckEntity({
    required this.accurateVotes,
    required this.inaccurateVotes,
    required this.unsureVotes,
    this.userVote,
  });

  int get totalVotes => accurateVotes + inaccurateVotes + unsureVotes;

  CommunityCheckEntity copyWith({
    int? accurateVotes,
    int? inaccurateVotes,
    int? unsureVotes,
    CommunityVote? userVote,
    bool clearUserVote = false,
  }) {
    return CommunityCheckEntity(
      accurateVotes: accurateVotes ?? this.accurateVotes,
      inaccurateVotes: inaccurateVotes ?? this.inaccurateVotes,
      unsureVotes: unsureVotes ?? this.unsureVotes,
      userVote: clearUserVote ? null : (userVote ?? this.userVote),
    );
  }

  @override
  List<Object?> get props => [accurateVotes, inaccurateVotes, unsureVotes, userVote];
}

class FactCheckEntity extends Equatable {
  final String articleId;
  final BotCheckEntity? botCheck;
  final CommunityCheckEntity? communityCheck;

  const FactCheckEntity({
    required this.articleId,
    this.botCheck,
    this.communityCheck,
  });

  FactCheckEntity copyWith({
    BotCheckEntity? botCheck,
    CommunityCheckEntity? communityCheck,
  }) {
    return FactCheckEntity(
      articleId: articleId,
      botCheck: botCheck ?? this.botCheck,
      communityCheck: communityCheck ?? this.communityCheck,
    );
  }

  @override
  List<Object?> get props => [articleId, botCheck, communityCheck];
}
