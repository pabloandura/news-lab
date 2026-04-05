import 'package:equatable/equatable.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
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

  const RemoteArticlesDone(
    List<ArticleEntity> articles, {
    this.factChecks = const {},
  }) : super(articles: articles);

  RemoteArticlesDone withFactChecks(Map<String, FactCheckEntity> factChecks) {
    return RemoteArticlesDone(articles!, factChecks: factChecks);
  }

  @override
  List<Object?> get props => [articles, factChecks];
}

class RemoteArticlesError extends RemoteArticlesState {
  const RemoteArticlesError(Exception error) : super(error: error);
}
