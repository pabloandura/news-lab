import 'package:equatable/equatable.dart';
import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';

abstract class SimilarArticlesState extends Equatable {
  const SimilarArticlesState();

  @override
  List<Object?> get props => [];
}

class SimilarArticlesInitial extends SimilarArticlesState {
  const SimilarArticlesInitial();
}

class SimilarArticlesLoading extends SimilarArticlesState {
  const SimilarArticlesLoading();
}

class SimilarArticlesLoaded extends SimilarArticlesState {
  final List<SimilarArticleEntity> results;

  const SimilarArticlesLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class SimilarArticlesError extends SimilarArticlesState {
  final String message;

  const SimilarArticlesError(this.message);

  @override
  List<Object?> get props => [message];
}
