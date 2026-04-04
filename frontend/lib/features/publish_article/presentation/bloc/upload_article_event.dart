abstract class UploadArticleEvent {
  const UploadArticleEvent();
}

class UploadArticleRequested extends UploadArticleEvent {
  final String authorId;
  final String author;
  final String title;
  final String description;
  final String content;
  final String localImagePath;
  final String? category;

  const UploadArticleRequested({
    required this.authorId,
    required this.author,
    required this.title,
    required this.description,
    required this.content,
    required this.localImagePath,
    this.category,
  });
}
