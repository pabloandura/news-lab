import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_lab/core/constants/constants.dart' show factCheckerBaseUrl;

abstract class BotCheckApiDataSource {
  /// Triggers the fact-checker Cloud Run service for [articleId].
  /// Returns immediately — result is written to Firestore asynchronously.
  Future<void> runBotCheck({
    required String articleId,
    required String text,
  });
}

class BotCheckApiDataSourceImpl implements BotCheckApiDataSource {
  final Dio _dio;
  final FirebaseAuth _auth;

  BotCheckApiDataSourceImpl(this._dio, this._auth);

  @override
  Future<void> runBotCheck({
    required String articleId,
    required String text,
  }) async {
    final token = await _auth.currentUser?.getIdToken();

    await _dio.post(
      '$factCheckerBaseUrl/fact-check',
      data: {'articleId': articleId, 'text': text},
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}
