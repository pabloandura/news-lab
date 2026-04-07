import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';

/// Compact list-style card: small left thumbnail, title/author/time on the right.
/// Used in trending lists, similar articles, and search results.
class CompactArticleCard extends StatelessWidget {
  final ArticleEntity article;
  final int? rank;
  final void Function(ArticleEntity)? onArticlePressed;

  const CompactArticleCard({
    super.key,
    required this.article,
    this.rank,
    this.onArticlePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isJournalistArticle = article.remoteId?.isNotEmpty == true;

    if (isJournalistArticle) {
      if (article.badgeBias == null) {
        debugPrint(
          '[CompactArticleCard] badgeBias is null for journalist article ${article.remoteId}',
        );
      }
      if (article.badgeFactCheck == null) {
        debugPrint(
          '[CompactArticleCard] badgeFactCheck is null for journalist article ${article.remoteId}',
        );
      }
    }

    return GestureDetector(
      onTap: () => onArticlePressed?.call(article),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rank != null) _RankLabel(rank: rank!),
            _Thumbnail(imageUrl: article.imageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: _TextContent(
                article: article,
                isJournalistArticle: isJournalistArticle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankLabel extends StatelessWidget {
  final int rank;
  const _RankLabel({required this.rank});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  const _Thumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl ?? kDefaultImage,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 72,
          height: 72,
          color: Colors.grey.shade200,
        ),
        errorWidget: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final ArticleEntity article;
  final bool isJournalistArticle;

  const _TextContent({
    required this.article,
    required this.isJournalistArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          article.title ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (article.author != null) ...[
              Text(
                article.author!,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              const Text('·', style: TextStyle(color: Colors.black38)),
              const SizedBox(width: 6),
            ],
            Text(
              formatDate(article.publishedAt),
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        if (isJournalistArticle) ...[
          const SizedBox(height: 4),
          _InlineBadges(
            badgeBias: article.badgeBias,
            badgeFactCheck: article.badgeFactCheck,
          ),
        ],
      ],
    );
  }
}

class _InlineBadges extends StatelessWidget {
  final String? badgeBias;
  final String? badgeFactCheck;

  const _InlineBadges({this.badgeBias, this.badgeFactCheck});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (badgeBias != null) {
      chips.add(_SmallBadge(
        label: _biasLabel(badgeBias!),
        color: _biasColor(badgeBias!),
      ));
    }
    if (badgeFactCheck != null) {
      chips.add(_SmallBadge(
        label: _factCheckLabel(badgeFactCheck!),
        color: _factCheckColor(badgeFactCheck!),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 4, children: chips);
  }

  String _biasLabel(String bias) {
    switch (bias) {
      case 'left':
        return 'Left';
      case 'right':
        return 'Right';
      default:
        return 'Center';
    }
  }

  Color _biasColor(String bias) {
    switch (bias) {
      case 'left':
        return Colors.blue.shade600;
      case 'right':
        return Colors.red.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  String _factCheckLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'disputed':
        return 'Disputed';
      default:
        return 'Unverified';
    }
  }

  Color _factCheckColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green.shade600;
      case 'disputed':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade500;
    }
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
