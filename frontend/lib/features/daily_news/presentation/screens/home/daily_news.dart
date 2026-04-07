import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';

String _articleKey(ArticleEntity article) {
  if (article.remoteId != null && article.remoteId!.isNotEmpty) {
    return article.remoteId!;
  }
  if (article.url != null && article.url!.isNotEmpty) {
    return md5.convert(utf8.encode(article.url!)).toString();
  }
  return '';
}

class DailyNews extends StatelessWidget {
  const DailyNews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily News', style: TextStyle(color: Colors.black)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.savedArticles),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.bookmark, color: Colors.black),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _CategoryFilterBar(),
        ),
      ),
      body: const ArticleListBody(),
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
  const ArticleListBody({super.key});

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
          final articles = state.articles ?? [];
          if (articles.isEmpty) {
            return const Center(child: Text('No articles found.'));
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              final key = _articleKey(article);
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
