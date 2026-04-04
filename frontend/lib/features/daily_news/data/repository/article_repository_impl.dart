import 'dart:io';

import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/resources/result.dart';
import 'package:news_lab/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_lab/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_lab/features/daily_news/data/models/article.dart';
import 'package:news_lab/features/daily_news/domain/entities/article.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_lab/features/publish_article/data/data_sources/article_firestore_data_source.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final NewsApiService _newsApiService;
  final AppDatabase _appDatabase;
  final ArticleFirestoreDataSource _firestoreDataSource;

  ArticleRepositoryImpl(
      this._newsApiService, this._appDatabase, this._firestoreDataSource);

  @override
  Future<Result<List<ArticleEntity>>> getNewsArticles(
      {String? category}) async {
    try {
      final results = await Future.wait([
        _newsApiService.getNewsArticles(
          apiKey: newsAPIKey,
          country: countryQuery,
          category: category ?? categoryQuery,
        ),
        _firestoreDataSource.getArticles(category: category),
      ]);

      final httpResponse = results[0] as dynamic;
      final firestoreArticles = results[1] as List;

      final firestoreEntities = firestoreArticles
          .map((a) => ArticleEntity(
                author: a.author,
                authorId: a.authorId,
                title: a.title,
                description: a.description,
                urlToImage: a.thumbnailUrl,
                content: a.content,
                publishedAt: a.publishedAt?.toIso8601String(),
              ))
          .toList();

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        return Success([...firestoreEntities, ...httpResponse.data]);
      }

      return Success(firestoreEntities);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<List<ArticleEntity>>> getSavedArticles() async {
    try {
      final articles = await _appDatabase.articleDAO.getArticles();
      return Success(articles);
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
