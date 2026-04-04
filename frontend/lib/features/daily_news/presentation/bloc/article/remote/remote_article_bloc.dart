import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';

class RemoteArticlesBloc
    extends Bloc<RemoteArticlesEvent, RemoteArticlesState> {
  final GetArticleUseCase _getArticleUseCase;

  RemoteArticlesBloc(this._getArticleUseCase)
      : super(const RemoteArticlesLoading()) {
    on<GetArticles>(onGetArticles);
  }

  void onGetArticles(
      GetArticles event, Emitter<RemoteArticlesState> emit) async {
    emit(const RemoteArticlesLoading());
    switch (await _getArticleUseCase.callWithCategory(category: event.category)) {
      case Success(:final data) when data.isNotEmpty:
        emit(RemoteArticlesDone(data));
      case Success():
        emit(const RemoteArticlesDone([]));
      case Failure(:final error):
        emit(RemoteArticlesError(error));
    }
  }
}
