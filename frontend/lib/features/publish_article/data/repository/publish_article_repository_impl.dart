import 'package:news_lab/core/data/data_sources/articles_remote_data_source.dart';
import 'package:news_lab/core/data/data_sources/articles_storage_data_source.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/publish_article/domain/repository/publish_article_repository.dart';

class PublishArticleRepositoryImpl implements PublishArticleRepository {
  final ArticlesStorageDataSource _storageDataSource;
  final ArticlesRemoteDataSource _remoteDataSource;

  PublishArticleRepositoryImpl(
      this._storageDataSource, this._remoteDataSource);

  @override
  Future<Result<void>> uploadArticle({
    required String authorId,
    required String author,
    required String title,
    required String description,
    required String content,
    required String localImagePath,
    String? category,
  }) async {
    try {
      final thumbnailUrl =
          await _storageDataSource.uploadThumbnail(localImagePath);

      await _remoteDataSource.saveArticle(ArticleEntity(
        authorId: authorId,
        author: author,
        title: title,
        description: description,
        content: content,
        imageUrl: thumbnailUrl,
        category: category,
      ));

      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
