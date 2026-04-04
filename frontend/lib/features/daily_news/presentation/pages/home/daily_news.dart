import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/article_tile.dart';

class DailyNews extends StatelessWidget {
  const DailyNews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily News', style: TextStyle(color: Colors.black)),
        actions: [
          GestureDetector(
            onTap: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.journalistProfile,
                  arguments: JournalistProfileArgs(
                    authorId: authState.user.uid,
                    displayName:
                        authState.user.displayName ?? authState.user.email,
                    email: authState.user.email,
                    isOwner: true,
                  ),
                );
              } else {
                Navigator.pushNamed(context, AppRoutes.login);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.person_outline, color: Colors.black),
            ),
          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            Navigator.pushNamed(context, AppRoutes.uploadArticle);
          } else {
            Navigator.pushNamed(context, AppRoutes.login);
          }
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
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
            itemBuilder: (context, index) => ArticleWidget(
              article: articles[index],
              onArticlePressed: (article) => Navigator.pushNamed(
                  context, AppRoutes.articleDetails,
                  arguments: article),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
