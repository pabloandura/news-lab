import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/bias_report/domain/usecases/get_article_list_bias_reports_usecase.dart';
import 'package:news_lab/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_article_list_fact_checks_usecase.dart';

String _articleId(ArticleEntity article) {
  if (article.remoteId != null && article.remoteId!.isNotEmpty) {
    return article.remoteId!;
  }
  if (article.url != null && article.url!.isNotEmpty) {
    return md5.convert(utf8.encode(article.url!)).toString();
  }
  return '';
}

class RemoteArticlesBloc
    extends Bloc<RemoteArticlesEvent, RemoteArticlesState> {
  final GetArticleUseCase _getArticleUseCase;
  final GetArticleListFactChecksUseCase _getListFactChecks;
  final GetArticleListBiasReportsUseCase _getListBiasReports;

  RemoteArticlesBloc(
      this._getArticleUseCase, this._getListFactChecks, this._getListBiasReports)
      : super(const RemoteArticlesLoading()) {
    on<GetArticles>(onGetArticles);
    on<RefreshFactChecks>(onRefreshFactChecks);
  }

  void onGetArticles(
      GetArticles event, Emitter<RemoteArticlesState> emit) async {
    emit(const RemoteArticlesLoading());
    switch (await _getArticleUseCase(
        GetArticlesParams(category: event.category))) {
      case Success(:final data) when data.isNotEmpty:
        emit(RemoteArticlesDone(data));
        await _fetchAndEmitResults(data.map(_articleId).where((id) => id.isNotEmpty).toList(), emit);
      case Success():
        emit(const RemoteArticlesDone([]));
      case Failure(:final error):
        emit(RemoteArticlesError(error));
    }
  }

  Future<void> onRefreshFactChecks(
      RefreshFactChecks event, Emitter<RemoteArticlesState> emit) async {
    final current = state;
    if (current is! RemoteArticlesDone) return;
    final ids = current.articles!
        .map(_articleId)
        .where((id) => id.isNotEmpty)
        .toList();
    await _fetchAndEmitResults(ids, emit);
  }

  Future<void> _fetchAndEmitResults(
      List<String> ids, Emitter<RemoteArticlesState> emit) async {
    if (ids.isEmpty || isClosed) return;
    final current = state;
    if (current is! RemoteArticlesDone) return;

    final factCheckResult = await _getListFactChecks(ids);
    final biasResult = await _getListBiasReports(ids);

    if (isClosed) return;
    emit(current.withResults(
      factChecks: switch (factCheckResult) {
        Success(:final data) => data,
        Failure() => current.factChecks,
      },
      biasReports: switch (biasResult) {
        Success(:final data) => data,
        Failure() => current.biasReports,
      },
    ));
  }
}
