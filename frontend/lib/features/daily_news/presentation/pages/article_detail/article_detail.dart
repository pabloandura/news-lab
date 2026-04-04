import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/features/daily_news/domain/entities/article.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_lab/injection_container.dart';

class ArticleDetailsView extends HookWidget {
  final ArticleEntity? article;

  const ArticleDetailsView({super.key, this.article});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LocalArticleBloc>(),
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: const Icon(Ionicons.chevron_back, color: Colors.black),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article!.title ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Ionicons.time_outline,
                        size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      article!.publishedAt ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (article!.urlToImage != null)
            SizedBox(
              width: double.maxFinite,
              height: 250,
              child: Image.network(article!.urlToImage!, fit: BoxFit.cover),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Text(
              '${article!.description ?? ''}\n\n${article!.content ?? ''}',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Builder(
      builder: (context) => FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          BlocProvider.of<LocalArticleBloc>(context).add(SaveArticle(article!));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.black,
              content: Text('Article saved successfully.'),
            ),
          );
        },
        child: const Icon(Ionicons.bookmark, color: Colors.white),
      ),
    );
  }
}
