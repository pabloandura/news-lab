import 'package:news_lab/features/publish_article/domain/repository/publish_article_repository.dart';

class UploadArticleParams {
  final String authorId;
  final String author;
  final String title;
  final String description;
  final String content;
  final String localImagePath;
  final String? category;

  const UploadArticleParams({
    required this.authorId,
    required this.author,
    required this.title,
    required this.description,
    required this.content,
    required this.localImagePath,
    this.category,
  });
}

class UploadArticleUseCase {
  final PublishArticleRepository _repository;

  UploadArticleUseCase(this._repository);

  Future<void> call(UploadArticleParams params) {
    return _repository.uploadArticle(
      authorId: params.authorId,
      author: params.author,
      title: params.title,
      description: params.description,
      content: params.content,
      localImagePath: params.localImagePath,
      category: params.category,
    );
  }
}
