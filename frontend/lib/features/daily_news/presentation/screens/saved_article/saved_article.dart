import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_state.dart';
import 'package:news_lab/features/daily_news/presentation/widgets/article_tile.dart';
import 'package:news_lab/injection_container.dart';
import 'package:news_lab/shared/widgets/empty_state_widget.dart';

class SavedArticles extends StatefulWidget {
  const SavedArticles({super.key});

  @override
  State<SavedArticles> createState() => _SavedArticlesState();
}

class _SavedArticlesState extends State<SavedArticles> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<ArticleEntity> _items = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LocalArticleBloc>()..add(const GetSavedArticles()),
      child: BlocConsumer<LocalArticleBloc, LocalArticlesState>(
        listener: (context, state) {
          if (state is LocalArticlesDone) {
            final newItems = state.articles ?? [];
            if (!_initialized) {
              setState(() {
                _items = newItems.toList();
                _initialized = true;
              });
              return;
            }
            // Animate removals
            for (int i = _items.length - 1; i >= 0; i--) {
              final item = _items[i];
              if (!newItems.any((a) => a.id == item.id)) {
                final removed = item;
                final removedIndex = i;
                _listKey.currentState?.removeItem(
                  removedIndex,
                  (ctx, animation) =>
                      _buildAnimatedItem(removed, animation, null),
                  duration: const Duration(milliseconds: 300),
                );
                setState(() => _items.removeAt(i));
              }
            }
          }
        },
        builder: (context, state) {
          if (state is LocalArticlesLoading || !_initialized) {
            return Scaffold(
              appBar: _appBar(context),
              body: const Center(child: CupertinoActivityIndicator()),
            );
          }
          if (state is LocalArticlesError) {
            return Scaffold(
              appBar: _appBar(context),
              body: Center(
                child: Text(state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54)),
              ),
            );
          }
          return Scaffold(
            appBar: _appBar(context),
            body: _items.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.bookmark_border_outlined,
                    message: 'No saved articles',
                    hint: 'Articles you bookmark will appear here',
                  )
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _items.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _items.length) return const SizedBox.shrink();
                      final article = _items[index];
                      return _buildAnimatedItem(
                          article, animation, context.read<LocalArticleBloc>());
                    },
                  ),
          );
        },
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: const Icon(Ionicons.chevron_back, color: Colors.black),
      ),
      title: const Text('Saved Articles',
          style: TextStyle(color: Colors.black)),
    );
  }

  Widget _buildAnimatedItem(
    ArticleEntity article,
    Animation<double> animation,
    LocalArticleBloc? bloc,
  ) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: animation,
        child: ArticleWidget(
          article: article,
          isRemovable: true,
          onRemove: bloc != null
              ? (a) => bloc.add(RemoveArticle(a))
              : null,
          onArticlePressed: (a) => Navigator.pushNamed(
            context,
            AppRoutes.articleDetails,
            arguments: a,
          ),
        ),
      ),
    );
  }
}
