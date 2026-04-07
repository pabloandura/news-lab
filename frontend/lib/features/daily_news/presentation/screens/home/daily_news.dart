import 'dart:convert';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/featured_article_card.dart';
import 'package:news_lab/shared/widgets/empty_state_widget.dart';

String _articleKey(ArticleEntity article) {
  if (article.remoteId != null && article.remoteId!.isNotEmpty) {
    return article.remoteId!;
  }
  if (article.url != null && article.url!.isNotEmpty) {
    return md5.convert(utf8.encode(article.url!)).toString();
  }
  return '';
}

class DailyNews extends HookWidget {
  const DailyNews({super.key});

  @override
  Widget build(BuildContext context) {
    final searchActive = useState(false);
    final searchQuery = useState('');
    final searchController = useTextEditingController();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
            title: searchActive.value
                ? TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search articles...',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (v) => searchQuery.value = v,
                  )
                : const Text('Daily News',
                    style: TextStyle(color: Colors.black)),
            actions: [
              if (searchActive.value)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    searchActive.value = false;
                    searchQuery.value = '';
                    searchController.clear();
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () => searchActive.value = true,
                ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(ctx, AppRoutes.savedArticles),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.bookmark, color: Colors.black),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _CategoryFilterBar()),
          SliverToBoxAdapter(child: _BreakingNewsTicker()),
        ],
        body: ArticleListBody(
          searchQuery: searchQuery.value,
          showFeatured: true,
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCategoryCubit, ArticleCategoryState>(
      builder: (context, state) {
        if (state is! ArticleCategoryLoaded) return const SizedBox.shrink();
        final categories = state.categories;
        final selected = state.selected;
        final allCategories = [null, ...categories];
        return SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: allCategories.map((category) {
                final isSelected = category == null
                    ? selected == null
                    : selected?.slug == category.slug;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: category == null ? 'All' : category.name,
                    selected: isSelected,
                    onTap: () => _onChipTap(context, category),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _onChipTap(BuildContext context, ArticleCategoryEntity? category) {
    context.read<ArticleCategoryCubit>().select(category);
    context
        .read<RemoteArticlesBloc>()
        .add(GetArticles(category: category?.slug));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.black : Colors.black26),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Reusable article list — reads RemoteArticlesBloc from context.
class ArticleListBody extends StatelessWidget {
  final String searchQuery;
  final bool showFeatured;

  const ArticleListBody({
    super.key,
    this.searchQuery = '',
    this.showFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RemoteArticlesBloc, RemoteArticlesState>(
      builder: (context, state) {
        if (state is RemoteArticlesLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is RemoteArticlesError) {
          return const Center(child: Icon(Icons.refresh));
        }
        if (state is RemoteArticlesDone) {
          var articles = state.articles ?? [];
          if (searchQuery.isNotEmpty) {
            articles = articles
                .where((a) => (a.title ?? '')
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();
          }
          if (articles.isEmpty) {
            return EmptyStateWidget(
              icon: searchQuery.isNotEmpty
                  ? Icons.search_off_outlined
                  : Icons.newspaper_outlined,
              message: searchQuery.isNotEmpty
                  ? 'No results for "$searchQuery"'
                  : 'No articles yet',
              hint: searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Check back soon for the latest news',
            );
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              final key = _articleKey(article);
              if (showFeatured && index == 0) {
                return FeaturedArticleCard(
                  article: article,
                  onArticlePressed: (a) {
                    final bloc = context.read<RemoteArticlesBloc>();
                    Navigator.pushNamed(context, AppRoutes.articleDetails,
                            arguments: a)
                        .then((_) => bloc.add(const RefreshFactChecks()));
                  },
                );
              }
              return ArticleWidget(
                article: article,
                factCheck: key.isNotEmpty ? state.factChecks[key] : null,
                biasReport: key.isNotEmpty ? state.biasReports[key] : null,
                onArticlePressed: (article) {
                  final bloc = context.read<RemoteArticlesBloc>();
                  Navigator.pushNamed(context, AppRoutes.articleDetails,
                          arguments: article)
                      .then((_) => bloc.add(const RefreshFactChecks()));
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Breaking news ticker — shows the title of the most recent article
/// with a horizontal auto-scroll animation.
class _BreakingNewsTicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RemoteArticlesBloc, RemoteArticlesState>(
      builder: (context, state) {
        if (state is! RemoteArticlesDone) return const SizedBox.shrink();
        final articles = state.articles ?? [];
        if (articles.isEmpty) return const SizedBox.shrink();
        final latest = articles.first;
        return _TickerBanner(
          title: latest.title ?? '',
          onTap: () {
            final bloc = context.read<RemoteArticlesBloc>();
            Navigator.pushNamed(context, AppRoutes.articleDetails,
                    arguments: latest)
                .then((_) => bloc.add(const RefreshFactChecks()));
          },
        );
      },
    );
  }
}

class _TickerBanner extends HookWidget {
  final String title;
  final VoidCallback onTap;

  const _TickerBanner({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    useEffect(() {
      bool active = true;

      Future<void> loop() async {
        // Initial delay before starting to scroll
        await Future.delayed(const Duration(seconds: 2));
        while (active) {
          if (!scrollController.hasClients) {
            await Future.delayed(const Duration(milliseconds: 200));
            continue;
          }
          final maxExtent = scrollController.position.maxScrollExtent;
          if (maxExtent <= 0) {
            // Text fits — no scrolling needed
            await Future.delayed(const Duration(seconds: 5));
            continue;
          }
          // Scroll to end at a reading pace (~40ms per pixel)
          await scrollController.animateTo(
            maxExtent,
            duration: Duration(milliseconds: (maxExtent * 40).round()),
            curve: Curves.linear,
          );
          await Future.delayed(const Duration(seconds: 1));
          if (!active || !scrollController.hasClients) break;
          // Jump back to start
          scrollController.jumpTo(0);
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      loop();
      return () {
        active = false;
      };
    }, []);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.red.shade700,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'BREAKING',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
