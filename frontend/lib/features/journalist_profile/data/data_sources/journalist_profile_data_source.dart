import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/features/journalist_profile/data/models/journalist_article_model.dart';

abstract class JournalistProfileDataSource {
  Future<List<JournalistArticleModel>> getArticlesByAuthor(String authorId);
  Future<void> deleteArticle(String articleId);
  Future<void> updateArticle(
    String articleId, {
    required String title,
    required String description,
    required String content,
    String? category,
    required String thumbnailUrl,
  });
}

class JournalistProfileDataSourceImpl implements JournalistProfileDataSource {
  final FirebaseFirestore _firestore;

  JournalistProfileDataSourceImpl(this._firestore);

  @override
  Future<List<JournalistArticleModel>> getArticlesByAuthor(String authorId) async {
    final snapshot = await _firestore
        .collection(articlesCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('publishedAt', descending: true)
        .get();
    return snapshot.docs.map(JournalistArticleModel.fromRawData).toList();
  }

  @override
  Future<void> deleteArticle(String articleId) async {
    await _firestore
        .collection(articlesCollection)
        .doc(articleId)
        .delete();
  }

  @override
  Future<void> updateArticle(
    String articleId, {
    required String title,
    required String description,
    required String content,
    String? category,
    required String thumbnailUrl,
  }) async {
    await _firestore
        .collection(articlesCollection)
        .doc(articleId)
        .update({
      'title': title,
      'description': description,
      'content': content,
      'category': category ?? '',
      'thumbnailUrl': thumbnailUrl,
    });
  }
}
