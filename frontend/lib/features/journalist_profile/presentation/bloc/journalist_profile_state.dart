import 'package:equatable/equatable.dart';
import 'package:news_lab/features/publish_article/domain/entities/published_article_entity.dart';

abstract class JournalistProfileState extends Equatable {
  const JournalistProfileState();

  @override
  List<Object?> get props => [];
}

class JournalistProfileInitial extends JournalistProfileState {
  const JournalistProfileInitial();
}

class JournalistProfileLoading extends JournalistProfileState {
  const JournalistProfileLoading();
}

class JournalistProfileLoaded extends JournalistProfileState {
  final List<PublishedArticleEntity> articles;
  final String? pendingDeleteId;
  final String? pendingUpdateId;

  const JournalistProfileLoaded(
    this.articles, {
    this.pendingDeleteId,
    this.pendingUpdateId,
  });

  @override
  List<Object?> get props => [articles, pendingDeleteId, pendingUpdateId];
}

class JournalistProfileError extends JournalistProfileState {
  final String message;
  const JournalistProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Keeps the article list visible but surfaces an error (e.g. delete/update failed).
class ArticleActionError extends JournalistProfileState {
  final List<PublishedArticleEntity> articles;
  final String message;

  const ArticleActionError(this.articles, this.message);

  @override
  List<Object?> get props => [articles, message];
}

/// Signals the edit page to pop and carries the refreshed list.
class ArticleUpdateSuccess extends JournalistProfileState {
  final List<PublishedArticleEntity> articles;

  const ArticleUpdateSuccess(this.articles);

  @override
  List<Object?> get props => [articles];
}
