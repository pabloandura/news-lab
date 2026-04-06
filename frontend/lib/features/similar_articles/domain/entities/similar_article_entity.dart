import 'package:equatable/equatable.dart';

class SimilarArticleEntity extends Equatable {
  final String title;
  final String source;
  final String url;
  final String? publishedAt;
  final String? snippet;
  final double similarityScore;

  const SimilarArticleEntity({
    required this.title,
    required this.source,
    required this.url,
    this.publishedAt,
    this.snippet,
    required this.similarityScore,
  });

  @override
  List<Object?> get props => [title, source, url, publishedAt, snippet, similarityScore];
}
