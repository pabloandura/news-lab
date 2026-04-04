import 'dart:io';

import 'package:dio/dio.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/resources/data_state.dart';
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

  ArticleRepositoryImpl(this._newsApiService, this._appDatabase, this._firestoreDataSource);

  @override
  Future<DataState<List<ArticleEntity>>> getNewsArticles() async {
    try {
      final results = await Future.wait([
        _newsApiService.getNewsArticles(
          apiKey: newsAPIKey,
          country: countryQuery,
          category: categoryQuery,
        ),
        _firestoreDataSource.getArticles(),
      ]);

      final httpResponse = results[0] as dynamic;
      final firestoreArticles = results[1] as List;

      final firestoreEntities = firestoreArticles.map((a) => ArticleEntity(
            author: a.author,
            title: a.title,
            description: a.description,
            urlToImage: a.thumbnailUrl,
            content: a.content,
            publishedAt: a.publishedAt?.toIso8601String(),
          )).toList();

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        return DataSuccess([...firestoreEntities, ...httpResponse.data]);
      }

      return DataSuccess(firestoreEntities);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<List<ArticleEntity>> getSavedArticles() async {
    return _appDatabase.articleDAO.getArticles();
  }

  @override
  Future<void> saveArticle(ArticleEntity article) {
    return _appDatabase.articleDAO
        .insertArticle(ArticleModel.fromEntity(article));
  }

  @override
  Future<void> removeArticle(ArticleEntity article) {
    return _appDatabase.articleDAO
        .deleteArticle(ArticleModel.fromEntity(article));
  }
}
