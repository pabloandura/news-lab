import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';

abstract class JournalistProfileDataSource {
  Future<List<ArticleEntity>> getArticlesByAuthor(String authorId);
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
  Future<List<ArticleEntity>> getArticlesByAuthor(String authorId) async {
    final snapshot = await _firestore
        .collection(articlesCollection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('publishedAt', descending: true)
        .get();
    return snapshot.docs.map(_docToEntity).toList();
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

  static ArticleEntity _docToEntity(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ArticleEntity(
      remoteId: doc.id,
      author: data['author'] as String?,
      authorId: data['authorId'] as String?,
      title: data['title'] as String?,
      description: data['description'] as String?,
      content: data['content'] as String?,
      imageUrl: (data['thumbnailUrl'] as String?)?.isNotEmpty == true
          ? data['thumbnailUrl'] as String
          : null,
      category: (data['category'] as String?)?.isNotEmpty == true
          ? data['category'] as String
          : null,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }
}
