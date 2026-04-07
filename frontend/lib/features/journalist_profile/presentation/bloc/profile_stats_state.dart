import 'package:equatable/equatable.dart';
import 'package:news_lab/features/analytics/domain/entities/author_stats_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/daily_views_entity.dart';

abstract class ProfileStatsState extends Equatable {
  const ProfileStatsState();

  @override
  List<Object?> get props => [];
}

class ProfileStatsInitial extends ProfileStatsState {
  const ProfileStatsInitial();
}

class ProfileStatsLoading extends ProfileStatsState {
  const ProfileStatsLoading();
}

class ProfileStatsLoaded extends ProfileStatsState {
  final AuthorStatsEntity stats;
  final List<DailyViewsEntity> weeklyViews;

  const ProfileStatsLoaded(this.stats, this.weeklyViews);

  @override
  List<Object?> get props => [stats, weeklyViews];
}

class ProfileStatsError extends ProfileStatsState {
  final String message;
  const ProfileStatsError(this.message);

  @override
  List<Object?> get props => [message];
}
