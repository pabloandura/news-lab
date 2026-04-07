import 'package:equatable/equatable.dart';

class AuthorStatsEntity extends Equatable {
  final int articleCount;
  final int totalViews;
  final int totalUpvotes;

  const AuthorStatsEntity({
    required this.articleCount,
    required this.totalViews,
    required this.totalUpvotes,
  });

  @override
  List<Object?> get props => [articleCount, totalViews, totalUpvotes];
}
