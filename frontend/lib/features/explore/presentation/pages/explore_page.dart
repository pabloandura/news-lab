import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/pages/home/daily_news.dart';
import 'package:news_lab/injection_container.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const _categoryIcons = <String, IconData>{
    'business': Icons.business_center_outlined,
    'entertainment': Icons.movie_outlined,
    'general': Icons.newspaper_outlined,
    'health': Icons.favorite_outline,
    'science': Icons.science_outlined,
    'sports': Icons.sports_soccer_outlined,
    'technology': Icons.computer_outlined,
  };

  static const _categoryColors = <String, Color>{
    'business': Color(0xFF1565C0),
    'entertainment': Color(0xFF6A1B9A),
    'general': Color(0xFF37474F),
    'health': Color(0xFFC62828),
    'science': Color(0xFF00695C),
    'sports': Color(0xFF2E7D32),
    'technology': Color(0xFF4527A0),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(color: Colors.black)),
      ),
      body: BlocBuilder<ArticleCategoryCubit, ArticleCategoryState>(
        builder: (context, state) {
          if (state is ArticleCategoryLoading || state is ArticleCategoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ArticleCategoryError) {
            return Center(child: Text(state.message));
          }
          if (state is ArticleCategoryLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return _CategoryCard(
                  category: category,
                  icon: _categoryIcons[category.slug] ?? Icons.article_outlined,
                  color: _categoryColors[category.slug] ?? Colors.blueGrey,
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ArticleCategoryEntity category;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<RemoteArticlesBloc>()
              ..add(GetArticles(category: category.slug)),
            child: _CategoryFeedPage(category: category),
          ),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFeedPage extends StatelessWidget {
  final ArticleCategoryEntity category;

  const _CategoryFeedPage({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name, style: const TextStyle(color: Colors.black)),
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const ArticleListBody(),
    );
  }
}
