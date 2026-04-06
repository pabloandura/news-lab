import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';

class SimilarArticleModel extends SimilarArticleEntity {
  const SimilarArticleModel({
    required super.title,
    required super.source,
    required super.url,
    super.publishedAt,
    super.snippet,
    required super.similarityScore,
  });

  factory SimilarArticleModel.fromJson(Map<String, dynamic> json) {
    return SimilarArticleModel(
      title: json['title'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      publishedAt: json['publishedAt'] as String?,
      snippet: json['snippet'] as String?,
      similarityScore: (json['similarityScore'] as num).toDouble(),
    );
  }

  SimilarArticleEntity toEntity() => SimilarArticleEntity(
        title: title,
        source: source,
        url: url,
        publishedAt: publishedAt,
        snippet: snippet,
        similarityScore: similarityScore,
      );
}
