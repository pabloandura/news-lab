import 'package:equatable/equatable.dart';

abstract class TrendingArticlesEvent extends Equatable {
  const TrendingArticlesEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendingArticles extends TrendingArticlesEvent {
  const LoadTrendingArticles();
}
