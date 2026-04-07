import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';

/// Full-width hero card for the first/spotlight article in feeds.
/// Displays a full-width image with a bottom-to-top gradient overlay and
/// title, author, category pill, and AI badges overlaid on the image.
class FeaturedArticleCard extends StatelessWidget {
  final ArticleEntity article;
  final void Function(ArticleEntity)? onArticlePressed;

  const FeaturedArticleCard({
    super.key,
    required this.article,
    this.onArticlePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isJournalistArticle = article.remoteId?.isNotEmpty == true;

    if (isJournalistArticle) {
      if (article.badgeBias == null) {
        debugPrint(
          '[FeaturedArticleCard] badgeBias is null for journalist article ${article.remoteId}',
        );
      }
      if (article.badgeFactCheck == null) {
        debugPrint(
          '[FeaturedArticleCard] badgeFactCheck is null for journalist article ${article.remoteId}',
        );
      }
    }

    return GestureDetector(
      onTap: () => onArticlePressed?.call(article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HeroImage(imageUrl: article.imageUrl),
              _GradientOverlay(),
              Positioned(
                left: 12,
                top: 12,
                child: _CategoryPill(category: article.category),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _OverlayContent(
                  article: article,
                  isJournalistArticle: isJournalistArticle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  const _HeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl ?? kDefaultImage,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey.shade300),
      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const [0.45, 1.0],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String? category;
  const _CategoryPill({this.category});

  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category!.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _OverlayContent extends StatelessWidget {
  final ArticleEntity article;
  final bool isJournalistArticle;

  const _OverlayContent({
    required this.article,
    required this.isJournalistArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isJournalistArticle) ...[
          _AiBadgeRow(
            badgeBias: article.badgeBias,
            badgeFactCheck: article.badgeFactCheck,
          ),
          const SizedBox(height: 6),
        ],
        Text(
          article.title ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (article.author != null) ...[
              const Icon(Icons.person_outline, size: 13, color: Colors.white70),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  article.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.access_time, size: 13, color: Colors.white60),
            const SizedBox(width: 3),
            Text(
              formatDate(article.publishedAt),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _AiBadgeRow extends StatelessWidget {
  final String? badgeBias;
  final String? badgeFactCheck;

  const _AiBadgeRow({this.badgeBias, this.badgeFactCheck});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (badgeBias != null) {
      badges.add(_AiBadge(
        label: _biasLabel(badgeBias!),
        color: _biasColor(badgeBias!),
      ));
    }
    if (badgeFactCheck != null) {
      badges.add(_AiBadge(
        label: _factCheckLabel(badgeFactCheck!),
        color: _factCheckColor(badgeFactCheck!),
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, children: badges);
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

class _AiBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AiBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
