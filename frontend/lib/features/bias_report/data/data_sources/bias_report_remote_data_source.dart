import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/features/bias_report/data/models/bias_report_model.dart';

abstract class BiasReportRemoteDataSource {
  Future<BiasReportModel?> getBiasReport({required String articleId});
  Stream<BiasReportModel?> watchBiasReport({required String articleId});
}

class BiasReportRemoteDataSourceImpl implements BiasReportRemoteDataSource {
  final FirebaseFirestore _firestore;

  const BiasReportRemoteDataSourceImpl(this._firestore);

  @override
  Future<BiasReportModel?> getBiasReport({required String articleId}) async {
    final doc = await _firestore
        .collection(articlesCollection)
        .doc(articleId)
        .get();

    final data = doc.data();
    if (data == null || data['biasReport'] == null) return null;

    return BiasReportModel.fromRawData(data['biasReport'] as Map<String, dynamic>);
  }

  @override
  Stream<BiasReportModel?> watchBiasReport({required String articleId}) {
    return _firestore
        .collection(articlesCollection)
        .doc(articleId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null || data['biasReport'] == null) return null;
      return BiasReportModel.fromRawData(
          data['biasReport'] as Map<String, dynamic>);
    });
  }
}
