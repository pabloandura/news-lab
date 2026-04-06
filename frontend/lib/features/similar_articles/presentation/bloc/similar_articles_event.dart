import 'package:equatable/equatable.dart';

abstract class SimilarArticlesEvent extends Equatable {
  const SimilarArticlesEvent();

  @override
  List<Object?> get props => [];
}

class LoadSimilarArticles extends SimilarArticlesEvent {
  final String articleId;

  const LoadSimilarArticles(this.articleId);

  @override
  List<Object?> get props => [articleId];
}
