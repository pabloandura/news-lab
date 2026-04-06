import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';
import 'package:news_lab/features/similar_articles/domain/usecases/get_similar_articles_usecase.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_event.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_state.dart';

class SimilarArticlesBloc
    extends Bloc<SimilarArticlesEvent, SimilarArticlesState> {
  final GetSimilarArticlesUseCase _getSimilarArticles;

  SimilarArticlesBloc(this._getSimilarArticles)
      : super(const SimilarArticlesInitial()) {
    on<LoadSimilarArticles>(_onLoad);
  }

  Future<void> _onLoad(
      LoadSimilarArticles event, Emitter<SimilarArticlesState> emit) async {
    emit(const SimilarArticlesLoading());
    final result = await _getSimilarArticles(event.articleId);
    switch (result) {
      case Success<List<SimilarArticleEntity>>():
        emit(SimilarArticlesLoaded(result.data));
      case Failure<List<SimilarArticleEntity>>():
        emit(SimilarArticlesError(result.message));
    }
  }
}
