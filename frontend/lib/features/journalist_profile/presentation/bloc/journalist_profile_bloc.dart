import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/delete_article_usecase.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/get_journalist_articles_usecase.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/update_article_usecase.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_state.dart';

class JournalistProfileBloc
    extends Bloc<JournalistProfileEvent, JournalistProfileState> {
  final GetJournalistArticlesUseCase _getArticles;
  final DeleteArticleUseCase _deleteArticle;
  final UpdateArticleUseCase _updateArticle;

  JournalistProfileBloc(
    this._getArticles,
    this._deleteArticle,
    this._updateArticle,
  ) : super(const JournalistProfileInitial()) {
    on<LoadJournalistProfile>(_onLoad);
    on<DeleteArticleRequested>(_onDelete);
    on<UpdateArticleRequested>(_onUpdate);
  }

  Future<void> _onLoad(
      LoadJournalistProfile event, Emitter<JournalistProfileState> emit) async {
    emit(const JournalistProfileLoading());
    switch (await _getArticles(event.authorId)) {
      case Success(:final data):
        emit(JournalistProfileLoaded(data));
      case Failure(:final message):
        emit(JournalistProfileError(message));
    }
  }

  Future<void> _onDelete(DeleteArticleRequested event,
      Emitter<JournalistProfileState> emit) async {
    final current = _currentArticles();
    if (current == null) return;

    emit(JournalistProfileLoaded(current, pendingDeleteId: event.articleId));
    switch (await _deleteArticle(event.articleId)) {
      case Success():
        final updated =
            current.where((a) => a.remoteId != event.articleId).toList();
        emit(JournalistProfileLoaded(updated));
      case Failure(:final message):
        emit(ArticleActionError(current, message));
    }
  }

  Future<void> _onUpdate(UpdateArticleRequested event,
      Emitter<JournalistProfileState> emit) async {
    final current = _currentArticles();
    if (current == null) return;

    emit(JournalistProfileLoaded(current,
        pendingUpdateId: event.params.articleId));
    switch (await _updateArticle(event.params)) {
      case Success():
        final updated = current.map((a) {
          if (a.remoteId != event.params.articleId) return a;
          return a.copyWith(
            title: event.params.title,
            description: event.params.description,
            content: event.params.content,
            imageUrl: event.params.localImagePath != null
                ? a.imageUrl
                : event.params.existingThumbnailUrl,
            category: event.params.category,
          );
        }).toList();
        emit(ArticleUpdateSuccess(updated));
      case Failure(:final message):
        emit(ArticleActionError(current, message));
    }
  }

  List<ArticleEntity>? _currentArticles() {
    final s = state;
    if (s is JournalistProfileLoaded) return s.articles;
    if (s is ArticleActionError) return s.articles;
    if (s is ArticleUpdateSuccess) return s.articles;
    return null;
  }
}
