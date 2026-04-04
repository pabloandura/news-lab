import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';

abstract class ArticleCategoryRepository {
  Future<List<ArticleCategoryEntity>> getCategories();
}
