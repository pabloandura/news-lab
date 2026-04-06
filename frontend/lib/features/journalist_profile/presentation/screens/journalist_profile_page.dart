import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_state.dart';
import 'package:news_lab/features/journalist_profile/presentation/screens/edit_article_page.dart';

class JournalistProfilePage extends StatelessWidget {
  final JournalistProfileArgs args;

  const JournalistProfilePage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: BlocConsumer<JournalistProfileBloc, JournalistProfileState>(
        listener: (context, state) {
          if (state is ArticleActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is JournalistProfileLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (state is JournalistProfileError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            );
          }

          final articles = _articlesFrom(state);
          final pendingDeleteId =
              state is JournalistProfileLoaded ? state.pendingDeleteId : null;
          final pendingUpdateId =
              state is JournalistProfileLoaded ? state.pendingUpdateId : null;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _ProfileHeader(args: args)),
              if (articles != null && articles.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No articles published yet.',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ),
                )
              else if (articles != null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = articles[index];
                      return _ArticleRow(
                        article: article,
                        isOwner: args.isOwner,
                        isPendingDelete: pendingDeleteId == article.remoteId,
                        isPendingUpdate: pendingUpdateId == article.remoteId,
                        onDelete: () => context
                            .read<JournalistProfileBloc>()
                            .add(DeleteArticleRequested(article.remoteId!)),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<JournalistProfileBloc>(),
                              child: EditArticlePage(article: article),
                            ),
                          ),
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.articleDetails,
                          arguments: article,
                        ),
                      );
                    },
                    childCount: articles.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<ArticleEntity>? _articlesFrom(JournalistProfileState state) {
    if (state is JournalistProfileLoaded) return state.articles;
    if (state is ArticleActionError) return state.articles;
    if (state is ArticleUpdateSuccess) return state.articles;
    return null;
  }

}

// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final JournalistProfileArgs args;

  const _ProfileHeader({required this.args});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.black12,
            child: Text(
              args.displayName.isNotEmpty
                  ? args.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  args.displayName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (args.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    args.email!,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54),
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

class _ArticleRow extends StatelessWidget {
  final ArticleEntity article;
  final bool isOwner;
  final bool isPendingDelete;
  final bool isPendingUpdate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ArticleRow({
    required this.article,
    required this.isOwner,
    required this.isPendingDelete,
    required this.isPendingUpdate,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = isPendingDelete || isPendingUpdate;
    return Opacity(
      opacity: isPending ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: isPending ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          height: MediaQuery.of(context).size.width / 2.4,
          child: Row(
            children: [
              _Thumbnail(url: article.imageUrl),
              const SizedBox(width: 12),
              Expanded(child: _ArticleInfo(article: article)),
              if (isOwner)
                _OwnerActions(
                  isPending: isPending,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url ?? '',
        width: MediaQuery.of(context).size.width / 3.2,
        height: double.maxFinite,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.black12,
          child: const CupertinoActivityIndicator(),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _ArticleInfo extends StatelessWidget {
  final ArticleEntity article;
  const _ArticleInfo({required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              article.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          if (article.publishedAt != null)
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  formatDateISO(article.publishedAt!),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
        ],
      ),
    );
  }

}

class _OwnerActions extends StatelessWidget {
  final bool isPending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OwnerActions({
    required this.isPending,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onEdit,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.edit_outlined, size: 20, color: Colors.black54),
          ),
        ),
        GestureDetector(
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
          ),
        ),
      ],
    );
  }
}
