import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_bloc.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/widgets/fact_check_badges.dart';
import 'package:news_lab/injection_container.dart';

class ArticleDetailsView extends HookWidget {
  final ArticleEntity? article;

  const ArticleDetailsView({super.key, this.article});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    final articleId = article?.remoteId ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<LocalArticleBloc>()),
        BlocProvider(
          create: (_) {
            final bloc = sl<FactCheckBloc>();
            if (articleId.isNotEmpty) {
              bloc.add(LoadFactCheck(articleId: articleId, userId: userId));
            }
            return bloc;
          },
        ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context, articleId: articleId, userId: userId),
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

  Widget _buildBody(BuildContext context,
      {required String articleId, required String userId}) {
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
                      formatDate(article!.publishedAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
                if (article!.author != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: article!.authorId != null
                        ? () => Navigator.pushNamed(
                              context,
                              AppRoutes.journalistProfile,
                              arguments: JournalistProfileArgs(
                                authorId: article!.authorId!,
                                displayName: article!.author!,
                                isOwner: false,
                              ),
                            )
                        : null,
                    child: Row(
                      children: [
                        const Icon(Ionicons.person_outline,
                            size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          article!.author!,
                          style: TextStyle(
                            fontSize: 12,
                            color: article!.authorId != null
                                ? Colors.black87
                                : Colors.black45,
                            decoration: article!.authorId != null
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FactCheckBadges(articleId: articleId, userId: userId),
              ],
            ),
          ),
          if (article!.imageUrl != null)
            SizedBox(
              width: double.maxFinite,
              height: 250,
              child: Image.network(article!.imageUrl!, fit: BoxFit.cover),
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
