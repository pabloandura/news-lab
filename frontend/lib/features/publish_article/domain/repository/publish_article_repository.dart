import 'package:news_lab/core/resources/result.dart';

abstract class PublishArticleRepository {
  Future<Result<void>> uploadArticle({
    required String authorId,
    required String author,
    required String title,
    required String description,
    required String content,
    required String localImagePath,
    String? category,
  });
}
