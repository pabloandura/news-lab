import 'package:equatable/equatable.dart';

class ArticleEntity extends Equatable {
  final int? id;
  final String? remoteId;
  final String? authorId;
  final String? author;
  final String? title;
  final String? description;
  final String? content;
  final String? imageUrl;
  final String? url;
  final String? category;
  final DateTime? publishedAt;

  const ArticleEntity({
    this.id,
    this.remoteId,
    this.authorId,
    this.author,
    this.title,
    this.description,
    this.content,
    this.imageUrl,
    this.url,
    this.category,
    this.publishedAt,
  });

  ArticleEntity copyWith({
    int? id,
    String? remoteId,
    String? authorId,
    String? author,
    String? title,
    String? description,
    String? content,
    String? imageUrl,
    String? url,
    String? category,
    DateTime? publishedAt,
  }) {
    return ArticleEntity(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      authorId: authorId ?? this.authorId,
      author: author ?? this.author,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        remoteId,
        authorId,
        author,
        title,
        description,
        content,
        imageUrl,
        url,
        category,
        publishedAt,
      ];
}
