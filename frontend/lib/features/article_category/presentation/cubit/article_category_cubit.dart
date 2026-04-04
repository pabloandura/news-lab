import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/domain/usecases/get_categories_usecase.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';

class ArticleCategoryCubit extends Cubit<ArticleCategoryState> {
  final GetCategoriesUseCase _getCategoriesUseCase;

  ArticleCategoryCubit(this._getCategoriesUseCase)
      : super(const ArticleCategoryInitial());

  Future<void> load() async {
    emit(const ArticleCategoryLoading());
    try {
      final categories = await _getCategoriesUseCase();
      emit(ArticleCategoryLoaded(categories));
    } catch (e) {
      emit(ArticleCategoryError(e.toString()));
    }
  }

  void select(ArticleCategoryEntity? category) {
    final current = state;
    if (current is ArticleCategoryLoaded) {
      emit(current.copyWith(selected: category));
    }
  }
}
