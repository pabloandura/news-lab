import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
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

    final newFactChecks = switch (factCheckResult) {
      Success(:final data) => data,
      Failure() => current.factChecks,
    };

    final newBiasReports = switch (biasResult) {
      Success(:final data) => data,
      Failure() => current.biasReports,
    };

    // Patch articles with derived badges so the list shows them immediately
    // without waiting for a full article reload.
    final patchedArticles = current.articles!.map((a) {
      final id = _articleId(a);
      String? badgeFactCheck = a.badgeFactCheck;
      String? badgeBias = a.badgeBias;

      final botCheck = newFactChecks[id]?.botCheck;
      if (botCheck != null) {
        badgeFactCheck =
            botCheck.flaggedSentencesPercent >= 0.3 ? 'disputed' : 'verified';
      }

      final biasReport = newBiasReports[id];
      if (biasReport != null) {
        badgeBias = _biasLabel(biasReport);
      }

      if (badgeFactCheck == a.badgeFactCheck && badgeBias == a.badgeBias) {
        return a;
      }
      return a.copyWith(badgeFactCheck: badgeFactCheck, badgeBias: badgeBias);
    }).toList();

    emit(RemoteArticlesDone(
      patchedArticles,
      factChecks: newFactChecks,
      biasReports: newBiasReports,
    ));
  }

  static String _biasLabel(BiasReportEntity report) {
    if (report.politicalLean < -0.33) return 'left';
    if (report.politicalLean > 0.33) return 'right';
    return 'center';
  }
}
