import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/utils/date_formatter.dart';

abstract class ViewTrackingRemoteDataSource {
  Future<void> trackView({
    required String articleId,
    required String authorId,
  });
}

class ViewTrackingRemoteDataSourceImpl implements ViewTrackingRemoteDataSource {
  final FirebaseFirestore _firestore;

  ViewTrackingRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> trackView({
    required String articleId,
    required String authorId,
  }) async {
    final today = formatDateISO(DateTime.now());
    final batch = _firestore.batch();

    final articleViewRef =
        _firestore.collection(articleViewsCollection).doc(articleId);
    batch.set(
      articleViewRef,
      {
        'authorId': authorId,
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final dailyViewRef = articleViewRef
        .collection(dailyViewsSubcollection)
        .doc(today);
    batch.set(
      dailyViewRef,
      {'count': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    final authorDailyRef = _firestore
        .collection(authorDailyViewsCollection)
        .doc(authorId)
        .collection(daysSubcollection)
        .doc(today);
    batch.set(
      authorDailyRef,
      {'count': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
