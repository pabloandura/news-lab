import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/features/article_category/data/models/article_category_model.dart';

abstract class ArticleCategoryDataSource {
  Future<List<ArticleCategoryModel>> getCategories();
}

class ArticleCategoryDataSourceImpl implements ArticleCategoryDataSource {
  final FirebaseFirestore _firestore;

  ArticleCategoryDataSourceImpl(this._firestore);

  @override
  Future<List<ArticleCategoryModel>> getCategories() async {
    final snapshot = await _firestore
        .collection('articleCategories')
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => ArticleCategoryModel.fromFirestore(doc))
        .toList();
  }
}
