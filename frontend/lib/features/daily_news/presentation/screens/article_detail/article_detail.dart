import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ionicons/ionicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_bloc.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_event.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_state.dart';
import 'package:news_lab/features/bias_report/presentation/widgets/bias_spectrum_widget.dart';
import 'package:news_lab/features/bias_report/presentation/widgets/polarize_button.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_event.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_bloc.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_event.dart';
import 'package:news_lab/features/fact_check/presentation/widgets/check_article_button.dart';
import 'package:news_lab/features/fact_check/presentation/widgets/fact_check_badges.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_bloc.dart';
import 'package:news_lab/features/similar_articles/presentation/widgets/similar_articles_section.dart';
import 'package:news_lab/features/view_tracking/domain/use_cases/track_article_view_usecase.dart';
import 'package:news_lab/injection_container.dart';

class ArticleDetailsView extends HookWidget {
  final ArticleEntity? article;

  const ArticleDetailsView({super.key, this.article});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    final articleId = article?.remoteId?.isNotEmpty == true
        ? article!.remoteId!
        : article?.url != null
            ? md5.convert(utf8.encode(article!.url!)).toString()
            : '';

    // Track view for journalist-published articles (those with a remoteId)
    useEffect(() {
      final isJournalistArticle =
          article?.remoteId?.isNotEmpty == true && article?.authorId != null;
      if (isJournalistArticle) {
        sl<TrackArticleViewUseCase>().call(
          TrackArticleViewParams(
            articleId: article!.remoteId!,
            authorId: article!.authorId!,
          ),
        );
      }
      return null;
    }, []);

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
        BlocProvider(
          create: (_) {
            final bloc = sl<BiasReportBloc>();
            if (articleId.isNotEmpty) {
              bloc.add(LoadBiasReport(articleId: articleId));
            }
            return bloc;
          },
        ),
        BlocProvider(create: (_) => sl<SimilarArticlesBloc>()),
      ],
      child: BlocListener<BiasReportBloc, BiasReportState>(
        listener: (context, state) {
          if (state is BiasReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context, articleId: articleId, userId: userId),
          floatingActionButton: _buildFab(),
        ),
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
      actions: [
        IconButton(
          icon: const Icon(Ionicons.share_outline, color: Colors.black),
          onPressed: () {
            final text = [
              article?.title ?? '',
              if (article?.url?.isNotEmpty == true) article!.url!,
            ].join('\n');
            Share.share(text);
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context,
      {required String articleId, required String userId}) {
    final hasImage = article?.imageUrl?.isNotEmpty == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            _HeroImageHeader(article: article!)
          else
            _TextHeader(article: article!),
          if (hasImage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: [
                  const Icon(Ionicons.time_outline,
                      size: 14, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(article!.publishedAt),
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              '${article!.description ?? ''}\n\n${article!.content ?? ''}',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
          const Divider(height: 1),
          _FactCheckPanel(
            articleId: articleId,
            userId: userId,
            articleText:
                '${article!.title ?? ''}\n\n${article!.description ?? ''}\n\n${article!.content ?? ''}',
          ),
          _BiasPanel(
            articleId: articleId,
            userId: userId,
            articleText:
                '${article!.title ?? ''}\n\n${article!.description ?? ''}\n\n${article!.content ?? ''}',
          ),
          _SimilarArticlesPanel(articleId: articleId),
          const SizedBox(height: 24),
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

// ── Hero image with gradient overlay ─────────────────────────────────────────

class _HeroImageHeader extends StatelessWidget {
  final ArticleEntity article;
  const _HeroImageHeader({required this.article});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: article.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: Colors.grey.shade300),
            errorWidget: (_, __, ___) =>
                Container(color: Colors.grey.shade300),
          ),
          // Bottom-to-top gradient for text readability
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.95),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Title + author overlaid at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  article.title ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                if (article.author != null) ...[
                  const SizedBox(height: 6),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: article.authorId != null
                          ? () => Navigator.pushNamed(
                                ctx,
                                AppRoutes.journalistProfile,
                                arguments: JournalistProfileArgs(
                                  authorId: article.authorId!,
                                  displayName: article.author!,
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
                            article.author!,
                            style: TextStyle(
                              fontSize: 12,
                              color: article.authorId != null
                                  ? Colors.black87
                                  : Colors.black45,
                              decoration: article.authorId != null
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text header (fallback when no image) ─────────────────────────────────────

class _TextHeader extends StatelessWidget {
  final ArticleEntity article;
  const _TextHeader({required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Ionicons.time_outline, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                formatDate(article.publishedAt),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
          if (article.author != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: article.authorId != null
                  ? () => Navigator.pushNamed(
                        context,
                        AppRoutes.journalistProfile,
                        arguments: JournalistProfileArgs(
                          authorId: article.authorId!,
                          displayName: article.author!,
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
                    article.author!,
                    style: TextStyle(
                      fontSize: 12,
                      color: article.authorId != null
                          ? Colors.black87
                          : Colors.black45,
                      decoration: article.authorId != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Collapsible Fact-Check panel ──────────────────────────────────────────────

class _FactCheckPanel extends StatelessWidget {
  final String articleId;
  final String userId;
  final String articleText;

  const _FactCheckPanel({
    required this.articleId,
    required this.userId,
    required this.articleText,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.fact_check_outlined),
      title: const Text(
        'Fact Check',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FactCheckBadges(articleId: articleId, userId: userId),
              const SizedBox(height: 10),
              CheckArticleButton(
                articleId: articleId,
                userId: userId,
                text: articleText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Collapsible Bias Analysis panel ──────────────────────────────────────────

class _BiasPanel extends StatelessWidget {
  final String articleId;
  final String userId;
  final String articleText;

  const _BiasPanel({
    required this.articleId,
    required this.userId,
    required this.articleText,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      leading: const Icon(Icons.balance_outlined),
      title: const Text(
        'Bias Analysis',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: BlocBuilder<BiasReportBloc, BiasReportState>(
            builder: (context, state) {
              final report = switch (state) {
                BiasReportLoaded(:final report) => report,
                _ => null,
              };
              if (report != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BiasSpectrumWidget(report: report),
                    if (userId.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => context.read<BiasReportBloc>().add(
                              RunPolarize(
                                  articleId: articleId, text: articleText),
                            ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Ionicons.refresh_outline,
                                size: 14, color: Colors.black38),
                            const SizedBox(width: 4),
                            const Text(
                              'Re-analyze',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }
              return PolarizeButton(
                articleId: articleId,
                userId: userId,
                text: articleText,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Collapsible Similar Articles panel ───────────────────────────────────────

class _SimilarArticlesPanel extends StatelessWidget {
  final String articleId;
  const _SimilarArticlesPanel({required this.articleId});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      leading: const Icon(Icons.layers_outlined),
      title: const Text(
        'Similar Articles',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: SimilarArticlesSection(articleId: articleId),
        ),
      ],
    );
  }
}
