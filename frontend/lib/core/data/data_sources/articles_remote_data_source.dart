import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';

abstract class ArticlesRemoteDataSource {
  Future<void> saveArticle(ArticleEntity article);
  Future<List<ArticleEntity>> getArticles({String? category});
}

class ArticlesRemoteDataSourceImpl implements ArticlesRemoteDataSource {
  final FirebaseFirestore _firestore;

  ArticlesRemoteDataSourceImpl(this._firestore);

  @override
  Future<void> saveArticle(ArticleEntity article) async {
    await _firestore.collection(articlesCollection).add({
      'author': article.author,
      'authorId': article.authorId,
      'title': article.title,
      'description': article.description,
      'content': article.content,
      'thumbnailUrl': article.imageUrl ?? '',
      'category': article.category ?? '',
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<ArticleEntity>> getArticles({String? category}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(articlesCollection)
        .orderBy('publishedAt', descending: true);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();
    return snapshot.docs.map(_docToEntity).toList();
  }

  static ArticleEntity _docToEntity(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final badgeBias = data['badgeBias'] as String?;
    final badgeFactCheck = data['badgeFactCheck'] as String?;
    if (badgeBias == null && data.containsKey('badgeBias')) {
      // field exists but is null — expected for unanalyzed articles
    }
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
      badgeBias: (badgeBias?.isNotEmpty == true) ? badgeBias : null,
      badgeFactCheck: (badgeFactCheck?.isNotEmpty == true) ? badgeFactCheck : null,
    );
  }
}
