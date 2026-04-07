import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/analytics/domain/use_cases/get_author_stats_usecase.dart';
import 'package:news_lab/features/analytics/domain/use_cases/get_weekly_views_usecase.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/profile_stats_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/profile_stats_state.dart';

class ProfileStatsBloc extends Bloc<ProfileStatsEvent, ProfileStatsState> {
  final GetAuthorStatsUseCase _getAuthorStats;
  final GetWeeklyViewsUseCase _getWeeklyViews;

  ProfileStatsBloc(this._getAuthorStats, this._getWeeklyViews)
      : super(const ProfileStatsInitial()) {
    on<LoadProfileStats>(_onLoad);
  }

  Future<void> _onLoad(
    LoadProfileStats event,
    Emitter<ProfileStatsState> emit,
  ) async {
    emit(const ProfileStatsLoading());
    try {
      // Start both futures concurrently
      final statsF = _getAuthorStats(event.authorId);
      final viewsF = _getWeeklyViews(event.authorId);
      final stats = await statsF;
      final views = await viewsF;
      emit(ProfileStatsLoaded(stats, views));
    } catch (e) {
      emit(ProfileStatsError(e.toString()));
    }
  }
}
