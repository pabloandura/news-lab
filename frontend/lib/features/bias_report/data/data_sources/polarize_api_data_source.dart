import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_lab/core/constants/constants.dart';

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
    final token = await _auth.currentUser?.getIdToken();
    await _dio.post(
      '$microservicesBaseUrl/polarize',
      data: {'articleId': articleId, 'text': text},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
