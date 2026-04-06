import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';

class JournalistArticleModel extends ArticleEntity {
  const JournalistArticleModel({
    super.id,
    super.remoteId,
    super.authorId,
    super.author,
    super.title,
    super.description,
    super.content,
    super.imageUrl,
    super.url,
    super.category,
    super.publishedAt,
  });

  factory JournalistArticleModel.fromRawData(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return JournalistArticleModel(
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

  ArticleEntity toEntity() => ArticleEntity(
        id: id,
        remoteId: remoteId,
        authorId: authorId,
        author: author,
        title: title,
        description: description,
        content: content,
        imageUrl: imageUrl,
        url: url,
        category: category,
        publishedAt: publishedAt,
      );
}
