import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_lab/core/constants/constants.dart' show sensemakerBaseUrl;
import 'package:news_lab/features/similar_articles/data/models/similar_article_model.dart';

abstract class SensemakerApiDataSource {
  Future<List<SimilarArticleModel>> getSimilarArticles(String articleId);
}

class SensemakerApiDataSourceImpl implements SensemakerApiDataSource {
  final Dio _dio;
  final FirebaseAuth _auth;

  SensemakerApiDataSourceImpl(this._dio, this._auth);

  @override
  Future<List<SimilarArticleModel>> getSimilarArticles(String articleId) async {
    final token = await _auth.currentUser?.getIdToken();

    final response = await _dio.post(
      '$sensemakerBaseUrl/similar',
      data: {'articleId': articleId},
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final List<dynamic> results = response.data['results'] as List<dynamic>;
    return results
        .map((e) => SimilarArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
