import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/publish_article/domain/usecases/upload_article.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_event.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_state.dart';

class UploadArticleBloc
    extends Bloc<UploadArticleEvent, UploadArticleState> {
  final UploadArticleUseCase _uploadArticleUseCase;

  UploadArticleBloc(this._uploadArticleUseCase)
      : super(const UploadArticleInitial()) {
    on<UploadArticleRequested>(_onUploadRequested);
  }

  void _onUploadRequested(
      UploadArticleRequested event, Emitter<UploadArticleState> emit) async {
    emit(const UploadArticleLoading());
    try {
      await _uploadArticleUseCase(UploadArticleParams(
        authorId: event.authorId,
        author: event.author,
        title: event.title,
        description: event.description,
        content: event.content,
        localImagePath: event.localImagePath,
        category: event.category,
      ));
      emit(const UploadArticleSuccess());
    } catch (e) {
      emit(UploadArticleError(e.toString()));
    }
  }
}
