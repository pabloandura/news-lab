import 'dart:io';

import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/data/data_sources/articles_remote_data_source.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_lab/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_lab/features/daily_news/data/models/article.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final NewsApiService _newsApiService;
  final AppDatabase _appDatabase;
  final ArticlesRemoteDataSource _remoteDataSource;

  ArticleRepositoryImpl(
      this._newsApiService, this._appDatabase, this._remoteDataSource);

  @override
  Future<Result<List<ArticleEntity>>> getNewsArticles(
      {String? category}) async {
    try {
      final httpFuture = _newsApiService.getNewsArticles(
        apiKey: newsAPIKey,
        country: countryQuery,
        category: category ?? categoryQuery,
      );
      final firestoreFuture =
          _remoteDataSource.getArticles(category: category);

      final httpResponse = await httpFuture;
      final firestoreArticles = await firestoreFuture;

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        final apiArticles =
            httpResponse.data.map((m) => m.toEntity()).toList();
        return Success([...firestoreArticles, ...apiArticles]);
      }

      return Success(firestoreArticles);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<List<ArticleEntity>>> getSavedArticles() async {
    try {
      final models = await _appDatabase.articleDAO.getArticles();
      return Success(models.map((m) => m.toEntity()).toList());
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> saveArticle(ArticleEntity article) async {
    try {
      await _appDatabase.articleDAO
          .insertArticle(ArticleModel.fromEntity(article));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> removeArticle(ArticleEntity article) async {
    try {
      await _appDatabase.articleDAO
          .deleteArticle(ArticleModel.fromEntity(article));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
