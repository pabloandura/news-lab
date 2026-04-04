import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/daily_news/domain/usecases/get_saved_article.dart';
import 'package:news_lab/features/daily_news/domain/usecases/remove_article.dart';
import 'package:news_lab/features/daily_news/domain/usecases/save_article.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_state.dart';

class LocalArticleBloc extends Bloc<LocalArticlesEvent, LocalArticlesState> {
  final GetSavedArticleUseCase _getSavedArticleUseCase;
  final SaveArticleUseCase _saveArticleUseCase;
  final RemoveArticleUseCase _removeArticleUseCase;

  LocalArticleBloc(
    this._getSavedArticleUseCase,
    this._saveArticleUseCase,
    this._removeArticleUseCase,
  ) : super(const LocalArticlesLoading()) {
    on<GetSavedArticles>(onGetSavedArticles);
    on<SaveArticle>(onSaveArticle);
    on<RemoveArticle>(onRemoveArticle);
  }

  void onGetSavedArticles(
      GetSavedArticles event, Emitter<LocalArticlesState> emit) async {
    emit(const LocalArticlesLoading());
    switch (await _getSavedArticleUseCase()) {
      case Success(:final data):
        emit(LocalArticlesDone(data));
      case Failure(:final message):
        emit(LocalArticlesError(message));
    }
  }

  void onSaveArticle(
      SaveArticle event, Emitter<LocalArticlesState> emit) async {
    switch (await _saveArticleUseCase(params: event.article)) {
      case Success():
        switch (await _getSavedArticleUseCase()) {
          case Success(:final data):
            emit(LocalArticlesDone(data));
          case Failure(:final message):
            emit(LocalArticlesError(message));
        }
      case Failure(:final message):
        final current = state.articles;
        emit(LocalArticlesError(message, articles: current));
    }
  }

  void onRemoveArticle(
      RemoveArticle event, Emitter<LocalArticlesState> emit) async {
    switch (await _removeArticleUseCase(params: event.article)) {
      case Success():
        switch (await _getSavedArticleUseCase()) {
          case Success(:final data):
            emit(LocalArticlesDone(data));
          case Failure(:final message):
            emit(LocalArticlesError(message));
        }
      case Failure(:final message):
        final current = state.articles;
        emit(LocalArticlesError(message, articles: current));
    }
  }
}
