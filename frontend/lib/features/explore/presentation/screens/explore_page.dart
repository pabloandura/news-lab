import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/screens/home/daily_news.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/compact_article_card.dart';
import 'package:news_lab/features/explore/presentation/bloc/trending_articles_bloc.dart';
import 'package:news_lab/features/explore/presentation/bloc/trending_articles_event.dart';
import 'package:news_lab/features/explore/presentation/bloc/trending_articles_state.dart';
import 'package:news_lab/features/explore/presentation/cubit/bias_landscape_cubit.dart';
import 'package:news_lab/features/explore/presentation/cubit/bias_landscape_state.dart';
import 'package:news_lab/injection_container.dart';
import 'package:news_lab/shared/widgets/empty_state_widget.dart';

class ExplorePage extends HookWidget {
  const ExplorePage({super.key});

  // Color-coded per AC 7.1: warm tones for Business/Health, cool for Tech/Science
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
    'business': Color(0xFFE65100), // warm orange
    'entertainment': Color(0xFF6A1B9A),
    'general': Color(0xFF37474F),
    'health': Color(0xFFC62828), // warm red
    'science': Color(0xFF00695C), // cool teal
    'sports': Color(0xFF2E7D32),
    'technology': Color(0xFF1565C0), // cool blue
  };

  @override
  Widget build(BuildContext context) {
    final searchQuery = useState('');
    final searchController = useTextEditingController();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<TrendingArticlesBloc>()
            ..add(const LoadTrendingArticles()),
        ),
        BlocProvider(
          create: (_) => sl<BiasLandscapeCubit>()..load(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore', style: TextStyle(color: Colors.black)),
        ),
        body: ListView(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search trending articles...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();
                            searchQuery.value = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => searchQuery.value = v,
              ),
            ),

            // Category grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Categories',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            _CategoryGrid(
              icons: _categoryIcons,
              colors: _categoryColors,
            ),

            // Bias breakdown
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Bias Landscape',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const _BiasBreakdownSection(),

            // Trending articles
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Trending',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            _TrendingSection(searchQuery: searchQuery.value),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Category grid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final Map<String, IconData> icons;
  final Map<String, Color> colors;

  const _CategoryGrid({required this.icons, required this.colors});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCategoryCubit, ArticleCategoryState>(
      builder: (context, state) {
        if (state is ArticleCategoryLoading || state is ArticleCategoryInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (state is ArticleCategoryLoaded) {
          final categories = state.categories;
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                icon: icons[category.slug] ?? Icons.article_outlined,
                color: colors[category.slug] ?? Colors.blueGrey,
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
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

// ── Bias breakdown section ────────────────────────────────────────────────────

class _BiasBreakdownSection extends StatelessWidget {
  const _BiasBreakdownSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BiasLandscapeCubit, BiasLandscapeState>(
      builder: (context, state) {
        if (state is BiasLandscapeLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        if (state is BiasLandscapeLoaded) {
          final landscape = state.landscape;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _BiasBar(
                  label: 'Left',
                  value: landscape.leftPercent,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 8),
                _BiasBar(
                  label: 'Center',
                  value: landscape.centerPercent,
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 8),
                _BiasBar(
                  label: 'Right',
                  value: landscape.rightPercent,
                  color: Colors.red.shade600,
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BiasBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _BiasBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

// ── Trending section ──────────────────────────────────────────────────────────

class _TrendingSection extends StatelessWidget {
  final String searchQuery;

  const _TrendingSection({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrendingArticlesBloc, TrendingArticlesState>(
      builder: (context, state) {
        if (state is TrendingArticlesLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (state is TrendingArticlesDone) {
          var articles = state.articles;
          if (searchQuery.isNotEmpty) {
            articles = articles
                .where((a) => (a.title ?? '')
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();
          }
          if (articles.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: EmptyStateWidget(
                icon: searchQuery.isNotEmpty
                    ? Icons.search_off_outlined
                    : Icons.trending_up_outlined,
                message: searchQuery.isNotEmpty
                    ? 'No results for "$searchQuery"'
                    : 'No trending articles',
                hint: searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Check back later for trending stories',
              ),
            );
          }
          return Column(
            children: articles.asMap().entries.map((entry) {
              return CompactArticleCard(
                article: entry.value,
                rank: entry.key + 1,
                onArticlePressed: (article) => Navigator.pushNamed(
                  context,
                  AppRoutes.articleDetails,
                  arguments: article,
                ),
              );
            }).toList(),
          );
        }
        if (state is TrendingArticlesError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load trending: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Category feed page (push route) ──────────────────────────────────────────

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
