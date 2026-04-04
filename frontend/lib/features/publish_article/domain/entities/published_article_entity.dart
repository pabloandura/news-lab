import 'package:equatable/equatable.dart';

class PublishedArticleEntity extends Equatable {
  final String? id;
  final String author;
  final String authorId;
  final String title;
  final String description;
  final String content;
  final String thumbnailUrl;
  final String? category;
  final DateTime? publishedAt;

  const PublishedArticleEntity({
    this.id,
    required this.author,
    required this.authorId,
    required this.title,
    required this.description,
    required this.content,
    required this.thumbnailUrl,
    this.category,
    this.publishedAt,
  });

  @override
  List<Object?> get props =>
      [id, author, authorId, title, description, content, thumbnailUrl, category, publishedAt];
}
