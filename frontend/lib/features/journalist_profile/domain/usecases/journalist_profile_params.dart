class UpdateArticleParams {
  final String articleId;
  final String title;
  final String description;
  final String content;
  final String? category;
  final String? localImagePath;
  final String existingThumbnailUrl;

  const UpdateArticleParams({
    required this.articleId,
    required this.title,
    required this.description,
    required this.content,
    this.category,
    this.localImagePath,
    required this.existingThumbnailUrl,
  });
}
