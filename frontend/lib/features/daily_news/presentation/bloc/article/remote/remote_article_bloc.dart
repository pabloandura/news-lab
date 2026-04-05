import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_article_list_fact_checks_usecase.dart';

class RemoteArticlesBloc
    extends Bloc<RemoteArticlesEvent, RemoteArticlesState> {
  final GetArticleUseCase _getArticleUseCase;
  final GetArticleListFactChecksUseCase _getListFactChecks;

  RemoteArticlesBloc(this._getArticleUseCase, this._getListFactChecks)
      : super(const RemoteArticlesLoading()) {
    on<GetArticles>(onGetArticles);
  }

  void onGetArticles(
      GetArticles event, Emitter<RemoteArticlesState> emit) async {
    emit(const RemoteArticlesLoading());
    switch (await _getArticleUseCase(GetArticlesParams(category: event.category))) {
      case Success(:final data) when data.isNotEmpty:
        // Emit articles immediately so the list appears without waiting for fact checks
        emit(RemoteArticlesDone(data));

        final ids = data
            .map((a) => a.remoteId)
            .whereType<String>()
            .toList();

        if (ids.isNotEmpty) {
          switch (await _getListFactChecks(ids)) {
            case Success(:final data):
              if (!isClosed) emit((state as RemoteArticlesDone).withFactChecks(data));
            case Failure():
              break; // fact checks are non-critical — list stays visible
          }
        }
      case Success():
        emit(const RemoteArticlesDone([]));
      case Failure(:final error):
        emit(RemoteArticlesError(error));
    }
  }
}
