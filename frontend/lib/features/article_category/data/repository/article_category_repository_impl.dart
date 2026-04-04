import 'package:news_lab/features/article_category/data/data_sources/article_category_data_source.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/domain/repository/article_category_repository.dart';

class ArticleCategoryRepositoryImpl implements ArticleCategoryRepository {
  final ArticleCategoryDataSource _dataSource;

  ArticleCategoryRepositoryImpl(this._dataSource);

  @override
  Future<List<ArticleCategoryEntity>> getCategories() =>
      _dataSource.getCategories();
}
