import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/analytics/domain/use_cases/get_trending_articles_usecase.dart';
import 'package:news_lab/features/explore/presentation/bloc/trending_articles_event.dart';
import 'package:news_lab/features/explore/presentation/bloc/trending_articles_state.dart';

class TrendingArticlesBloc
    extends Bloc<TrendingArticlesEvent, TrendingArticlesState> {
  final GetTrendingArticlesUseCase _getTrendingArticles;

  TrendingArticlesBloc(this._getTrendingArticles)
      : super(const TrendingArticlesInitial()) {
    on<LoadTrendingArticles>(_onLoad);
  }

  Future<void> _onLoad(
    LoadTrendingArticles event,
    Emitter<TrendingArticlesState> emit,
  ) async {
    emit(const TrendingArticlesLoading());
    try {
      final articles = await _getTrendingArticles();
      emit(TrendingArticlesDone(articles: articles));
    } catch (e) {
      emit(TrendingArticlesError(message: e.toString()));
    }
  }
}
