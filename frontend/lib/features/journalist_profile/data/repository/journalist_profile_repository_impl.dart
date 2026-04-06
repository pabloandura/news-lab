import 'package:news_lab/core/data/data_sources/articles_storage_data_source.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/journalist_profile/data/data_sources/journalist_profile_data_source.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';

class JournalistProfileRepositoryImpl implements JournalistProfileRepository {
  final JournalistProfileDataSource _dataSource;
  final ArticlesStorageDataSource _storageDataSource;

  JournalistProfileRepositoryImpl(this._dataSource, this._storageDataSource);

  @override
  Future<Result<List<ArticleEntity>>> getArticlesByAuthor(
      String authorId) async {
    try {
      final models = await _dataSource.getArticlesByAuthor(authorId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> deleteArticle(String articleId) async {
    try {
      await _dataSource.deleteArticle(articleId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateArticle(UpdateArticleParams params) async {
    try {
      final String thumbnailUrl;
      if (params.localImagePath != null) {
        thumbnailUrl =
            await _storageDataSource.uploadThumbnail(params.localImagePath!);
      } else {
        thumbnailUrl = params.existingThumbnailUrl;
      }

      await _dataSource.updateArticle(
        params.articleId,
        title: params.title,
        description: params.description,
        content: params.content,
        category: params.category,
        thumbnailUrl: thumbnailUrl,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
