import 'package:equatable/equatable.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';

abstract class ArticleCategoryState extends Equatable {
  const ArticleCategoryState();

  @override
  List<Object?> get props => [];
}

class ArticleCategoryInitial extends ArticleCategoryState {
  const ArticleCategoryInitial();
}

class ArticleCategoryLoading extends ArticleCategoryState {
  const ArticleCategoryLoading();
}

class ArticleCategoryLoaded extends ArticleCategoryState {
  final List<ArticleCategoryEntity> categories;
  final ArticleCategoryEntity? selected; // null = "All"

  const ArticleCategoryLoaded(this.categories, {this.selected});

  ArticleCategoryLoaded copyWith({ArticleCategoryEntity? selected, bool clearSelected = false}) {
    return ArticleCategoryLoaded(
      categories,
      selected: clearSelected ? null : (selected ?? this.selected),
    );
  }

  @override
  List<Object?> get props => [categories, selected];
}

class ArticleCategoryError extends ArticleCategoryState {
  final String message;

  const ArticleCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
