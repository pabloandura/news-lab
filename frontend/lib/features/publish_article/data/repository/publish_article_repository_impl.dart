import 'package:news_lab/features/publish_article/data/data_sources/article_firestore_data_source.dart';
import 'package:news_lab/features/publish_article/data/data_sources/article_storage_data_source.dart';
import 'package:news_lab/features/publish_article/data/models/published_article_model.dart';
import 'package:news_lab/features/publish_article/domain/repository/publish_article_repository.dart';

class PublishArticleRepositoryImpl implements PublishArticleRepository {
  final ArticleStorageDataSource _storageDataSource;
  final ArticleFirestoreDataSource _firestoreDataSource;

  PublishArticleRepositoryImpl(
      this._storageDataSource, this._firestoreDataSource);

  @override
  Future<void> uploadArticle({
    required String authorId,
    required String author,
    required String title,
    required String description,
    required String content,
    required String localImagePath,
    String? category,
  }) async {
    final thumbnailUrl =
        await _storageDataSource.uploadThumbnail(localImagePath);

    final article = PublishedArticleModel(
      author: author,
      authorId: authorId,
      title: title,
      description: description,
      content: content,
      thumbnailUrl: thumbnailUrl,
      category: category,
    );

    await _firestoreDataSource.saveArticle(article);
  }
}
