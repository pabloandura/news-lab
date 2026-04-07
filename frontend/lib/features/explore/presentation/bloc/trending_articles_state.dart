import 'package:equatable/equatable.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';

abstract class TrendingArticlesState extends Equatable {
  const TrendingArticlesState();

  @override
  List<Object?> get props => [];
}

class TrendingArticlesInitial extends TrendingArticlesState {
  const TrendingArticlesInitial();
}

class TrendingArticlesLoading extends TrendingArticlesState {
  const TrendingArticlesLoading();
}

class TrendingArticlesDone extends TrendingArticlesState {
  final List<ArticleEntity> articles;

  const TrendingArticlesDone({required this.articles});

  @override
  List<Object?> get props => [articles];
}

class TrendingArticlesError extends TrendingArticlesState {
  final String message;

  const TrendingArticlesError({required this.message});

  @override
  List<Object?> get props => [message];
}
