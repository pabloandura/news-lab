import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

class BotCheckModel extends BotCheckEntity {
  const BotCheckModel({
    required super.flaggedSentencesPercent,
    required super.confidenceScore,
    super.checkedAt,
  });

  factory BotCheckModel.fromRawData(Map<String, dynamic> map) {
    return BotCheckModel(
      flaggedSentencesPercent: (map['flaggedSentencesPercent'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      checkedAt: (map['checkedAt'] as Timestamp?)?.toDate(),
    );
  }

  BotCheckEntity toEntity() => BotCheckEntity(
        flaggedSentencesPercent: flaggedSentencesPercent,
        confidenceScore: confidenceScore,
        checkedAt: checkedAt,
      );
}

class CommunityCheckModel extends CommunityCheckEntity {
  const CommunityCheckModel({
    required super.accurateVotes,
    required super.inaccurateVotes,
    required super.unsureVotes,
    super.userVote,
  });

  factory CommunityCheckModel.fromRawData(
    Map<String, dynamic> map, {
    CommunityVote? userVote,
  }) {
    return CommunityCheckModel(
      accurateVotes: (map['accurateVotes'] as num?)?.toInt() ?? 0,
      inaccurateVotes: (map['inaccurateVotes'] as num?)?.toInt() ?? 0,
      unsureVotes: (map['unsureVotes'] as num?)?.toInt() ?? 0,
      userVote: userVote,
    );
  }

  CommunityCheckEntity toEntity() => CommunityCheckEntity(
        accurateVotes: accurateVotes,
        inaccurateVotes: inaccurateVotes,
        unsureVotes: unsureVotes,
        userVote: userVote,
      );
}

class FactCheckModel extends FactCheckEntity {
  const FactCheckModel({
    required super.articleId,
    super.botCheck,
    super.communityCheck,
  });

  factory FactCheckModel.fromRawData({
    required String articleId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String? userVoteRaw,
  }) {
    final data = doc.data();

    BotCheckEntity? botCheck;
    if (data != null && data['botCheck'] != null) {
      botCheck = BotCheckModel.fromRawData(data['botCheck'] as Map<String, dynamic>);
    }

    CommunityCheckEntity? communityCheck;
    if (data != null && data['communityCheck'] != null) {
      final userVote = userVoteRaw.toCommunityVote();
      communityCheck = CommunityCheckModel.fromRawData(
        data['communityCheck'] as Map<String, dynamic>,
        userVote: userVote,
      );
    }

    return FactCheckModel(
      articleId: articleId,
      botCheck: botCheck,
      communityCheck: communityCheck,
    );
  }

  FactCheckEntity toEntity() => FactCheckEntity(
        articleId: articleId,
        botCheck: (botCheck as BotCheckModel?)?.toEntity(),
        communityCheck: (communityCheck as CommunityCheckModel?)?.toEntity(),
      );
}

extension CommunityVoteStringExtension on String? {
  CommunityVote? toCommunityVote() {
    switch (this) {
      case 'accurate':
        return CommunityVote.accurate;
      case 'inaccurate':
        return CommunityVote.inaccurate;
      case 'unsure':
        return CommunityVote.unsure;
      default:
        return null;
    }
  }
}

extension CommunityVoteExtension on CommunityVote {
  String toFirestoreString() {
    switch (this) {
      case CommunityVote.accurate:
        return 'accurate';
      case CommunityVote.inaccurate:
        return 'inaccurate';
      case CommunityVote.unsure:
        return 'unsure';
    }
  }

  String get counterField {
    switch (this) {
      case CommunityVote.accurate:
        return 'accurateVotes';
      case CommunityVote.inaccurate:
        return 'inaccurateVotes';
      case CommunityVote.unsure:
        return 'unsureVotes';
    }
  }
}
