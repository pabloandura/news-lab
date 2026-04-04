import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/domain/repository/article_category_repository.dart';

class GetCategoriesUseCase {
  final ArticleCategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<ArticleCategoryEntity>> call() => _repository.getCategories();
}
