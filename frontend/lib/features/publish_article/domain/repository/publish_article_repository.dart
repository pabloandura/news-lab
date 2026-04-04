abstract class PublishArticleRepository {
  Future<void> uploadArticle({
    required String authorId,
    required String author,
    required String title,
    required String description,
    required String content,
    required String localImagePath,
    String? category,
  });
}
