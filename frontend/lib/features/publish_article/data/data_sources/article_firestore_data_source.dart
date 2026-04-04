import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/features/publish_article/data/models/published_article_model.dart';

abstract class ArticleFirestoreDataSource {
  Future<void> saveArticle(PublishedArticleModel article);
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
}
