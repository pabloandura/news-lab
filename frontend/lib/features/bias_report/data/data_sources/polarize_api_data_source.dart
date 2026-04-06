import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_lab/core/constants/constants.dart' show polarizerBaseUrl;

abstract class PolarizeApiDataSource {
  Future<void> runPolarize({
    required String articleId,
    required String text,
  });
}

class PolarizeApiDataSourceImpl implements PolarizeApiDataSource {
  final Dio _dio;
  final FirebaseAuth _auth;

  const PolarizeApiDataSourceImpl(this._dio, this._auth);

  @override
  Future<void> runPolarize({
    required String articleId,
    required String text,
  }) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      await _dio.post(
        '$polarizerBaseUrl/polarize',
        data: {'articleId': articleId, 'text': text},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Bias analysis service is unavailable. Please try again later.');
      }
      rethrow;
    }
  }
}
