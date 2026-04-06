import 'package:equatable/equatable.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

abstract class RemoteArticlesState extends Equatable {
  final List<ArticleEntity>? articles;
  final Exception? error;

  const RemoteArticlesState({this.articles, this.error});

  @override
  List<Object?> get props => [articles, error];
}

class RemoteArticlesLoading extends RemoteArticlesState {
  const RemoteArticlesLoading();
}

class RemoteArticlesDone extends RemoteArticlesState {
  final Map<String, FactCheckEntity> factChecks;
  final Map<String, BiasReportEntity> biasReports;

  const RemoteArticlesDone(
    List<ArticleEntity> articles, {
    this.factChecks = const {},
    this.biasReports = const {},
  }) : super(articles: articles);

  RemoteArticlesDone withResults({
    Map<String, FactCheckEntity>? factChecks,
    Map<String, BiasReportEntity>? biasReports,
  }) {
    return RemoteArticlesDone(
      articles!,
      factChecks: factChecks ?? this.factChecks,
      biasReports: biasReports ?? this.biasReports,
    );
  }

  /// Keep for backward compat.
  RemoteArticlesDone withFactChecks(Map<String, FactCheckEntity> factChecks) =>
      withResults(factChecks: factChecks);

  @override
  List<Object?> get props => [articles, factChecks, biasReports];
}

class RemoteArticlesError extends RemoteArticlesState {
  const RemoteArticlesError(Exception error) : super(error: error);
}
