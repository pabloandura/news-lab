import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_state.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_lab/injection_container.dart';

class SavedArticles extends HookWidget {
  const SavedArticles({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LocalArticleBloc>()..add(const GetSavedArticles()),
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Icon(Ionicons.chevron_back, color: Colors.black),
          ),
          title: const Text('Saved Articles',
              style: TextStyle(color: Colors.black)),
        ),
        body: BlocBuilder<LocalArticleBloc, LocalArticlesState>(
          builder: (context, state) {
            if (state is LocalArticlesLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (state is LocalArticlesError) {
              return Center(
                child: Text(state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54)),
              );
            }
            if (state is LocalArticlesDone) {
              return _buildList(context, state.articles!);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ArticleEntity> articles) {
    if (articles.isEmpty) {
      return const Center(
        child: Text('No saved articles yet.',
            style: TextStyle(color: Colors.black54)),
      );
    }
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) => ArticleWidget(
        article: articles[index],
        isRemovable: true,
        onRemove: (article) => BlocProvider.of<LocalArticleBloc>(context)
            .add(RemoveArticle(article)),
        onArticlePressed: (article) => Navigator.pushNamed(
            context, AppRoutes.articleDetails,
            arguments: article),
      ),
    );
  }
}
