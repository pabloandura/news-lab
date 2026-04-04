import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';

class ArticleCategoryModel extends ArticleCategoryEntity {
  const ArticleCategoryModel({required super.slug, required super.name});

  factory ArticleCategoryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ArticleCategoryModel(
      slug: data['slug'] ?? doc.id,
      name: data['name'] ?? doc.id,
    );
  }
}
