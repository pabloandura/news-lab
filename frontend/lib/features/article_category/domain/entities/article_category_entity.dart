import 'package:equatable/equatable.dart';

class ArticleCategoryEntity extends Equatable {
  final String slug; // matches NewsAPI category param
  final String name;

  const ArticleCategoryEntity({required this.slug, required this.name});

  @override
  List<Object?> get props => [slug, name];
}
