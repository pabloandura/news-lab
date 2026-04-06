import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/similar_articles/data/data_sources/sensemaker_api_data_source.dart';
import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';
import 'package:news_lab/features/similar_articles/domain/repository/similar_articles_repository.dart';

class SimilarArticlesRepositoryImpl implements SimilarArticlesRepository {
  final SensemakerApiDataSource _dataSource;

  SimilarArticlesRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<SimilarArticleEntity>>> getSimilarArticles(
      String articleId) async {
    try {
      final models = await _dataSource.getSimilarArticles(articleId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
