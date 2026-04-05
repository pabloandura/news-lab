import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/features/fact_check/data/models/fact_check_model.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

abstract class FactCheckRemoteDataSource {
  Future<FactCheckModel> getFactCheck({
    required String articleId,
    required String userId,
  });

  /// Fetches fact-check data for multiple articles in a single Firestore read.
  /// Returns only the documents that exist; missing articleIds are absent from the map.
  Future<Map<String, FactCheckModel>> batchGetFactChecks(List<String> articleIds);

  Future<void> submitVote({
    required String articleId,
    required String userId,
    required CommunityVote vote,
  });
}

class FactCheckRemoteDataSourceImpl implements FactCheckRemoteDataSource {
  final FirebaseFirestore _firestore;

  FactCheckRemoteDataSourceImpl(this._firestore);

  @override
  Future<Map<String, FactCheckModel>> batchGetFactChecks(
      List<String> articleIds) async {
    if (articleIds.isEmpty) return {};

    // whereIn supports up to 30 values; chunk if needed
    final results = <String, FactCheckModel>{};
    const chunkSize = 30;
    for (var i = 0; i < articleIds.length; i += chunkSize) {
      final chunk = articleIds.skip(i).take(chunkSize).toList();
      final snapshot = await _firestore
          .collection(factChecksCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        results[doc.id] = FactCheckModel.fromFirestore(
          articleId: doc.id,
          doc: doc,
          userVoteRaw: null, // list view is read-only; user vote loaded on detail
        );
      }
    }
    return results;
  }

  @override
  Future<FactCheckModel> getFactCheck({
    required String articleId,
    required String userId,
  }) async {
    final docRef = _firestore.collection(factChecksCollection).doc(articleId);

    final factCheckDoc = await docRef.get();

    String? userVoteRaw;
    if (userId.isNotEmpty) {
      final voteDoc = await docRef.collection(votesSubcollection).doc(userId).get();
      userVoteRaw = voteDoc.data()?['vote'] as String?;
    }

    return FactCheckModel.fromFirestore(
      articleId: articleId,
      doc: factCheckDoc,
      userVoteRaw: userVoteRaw,
    );
  }

  @override
  Future<void> submitVote({
    required String articleId,
    required String userId,
    required CommunityVote vote,
  }) async {
    final docRef = _firestore.collection(factChecksCollection).doc(articleId);
    final voteRef = docRef.collection(votesSubcollection).doc(userId);

    await _firestore.runTransaction((transaction) async {
      final voteSnap = await transaction.get(voteRef);

      if (voteSnap.exists) {
        final previousVoteRaw = voteSnap.data()?['vote'] as String?;
        final previousVote = previousVoteRaw.toCommunityVote();
        if (previousVote == vote) return; // same vote — no-op
        if (previousVote != null) {
          transaction.update(docRef, {
            'communityCheck.${previousVote.counterField}':
                FieldValue.increment(-1),
          });
        }
      }

      transaction.set(
        docRef,
        {
          'communityCheck': {
            vote.counterField: FieldValue.increment(1),
          }
        },
        SetOptions(merge: true),
      );

      transaction.set(voteRef, {
        'vote': vote.toFirestoreString(),
        'votedAt': FieldValue.serverTimestamp(),
      });
    });
  }

}
