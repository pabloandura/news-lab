import 'package:equatable/equatable.dart';

class AuthorStatsEntity extends Equatable {
  final int articleCount;
  final int totalViews;
  final int totalUpvotes;
  final int totalVotes;
  final double? averagePoliticalLean;

  const AuthorStatsEntity({
    required this.articleCount,
    required this.totalViews,
    required this.totalUpvotes,
    this.totalVotes = 0,
    this.averagePoliticalLean,
  });

  @override
  List<Object?> get props =>
      [articleCount, totalViews, totalUpvotes, totalVotes, averagePoliticalLean];
}
