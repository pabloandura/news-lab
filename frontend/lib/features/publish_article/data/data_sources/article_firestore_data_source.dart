import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/features/publish_article/data/models/published_article_model.dart';

abstract class ArticleFirestoreDataSource {
  Future<void> saveArticle(PublishedArticleModel article);
  Future<List<PublishedArticleModel>> getArticles({String? category});
}

class ArticleFirestoreDataSourceImpl implements ArticleFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ArticleFirestoreDataSourceImpl(this._firestore);

  @override
  Future<void> saveArticle(PublishedArticleModel article) async {
    await _firestore
        .collection(articlesCollection)
        .add(article.toFirestore());
  }

  @override
  Future<List<PublishedArticleModel>> getArticles({String? category}) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(articlesCollection)
        .orderBy('publishedAt', descending: true);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PublishedArticleModel.fromFirestore(doc))
        .toList();
  }
}
