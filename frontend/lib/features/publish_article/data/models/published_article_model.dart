import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/features/publish_article/domain/entities/published_article_entity.dart';

class PublishedArticleModel extends PublishedArticleEntity {
  const PublishedArticleModel({
    super.id,
    required super.author,
    required super.authorId,
    required super.title,
    required super.description,
    required super.content,
    required super.thumbnailUrl,
    super.category,
    super.publishedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'author': author,
      'authorId': authorId,
      'title': title,
      'description': description,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'category': category ?? '',
      'publishedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PublishedArticleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PublishedArticleModel(
      id: doc.id,
      author: data['author'] ?? '',
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      category: data['category'],
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }
}
