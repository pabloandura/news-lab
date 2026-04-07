import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';

const _kDarkCard = Color(0xFF1E2B38);
const _kOrange = Color(0xFFE8621A);

/// Full-width hero card: image on top, dark info card below.
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

    return GestureDetector(
      onTap: () => onArticlePressed?.call(article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _kDarkCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageSection(article: article),
              _InfoSection(
                article: article,
                isJournalistArticle: isJournalistArticle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image with category pill + source badge ───────────────────────────────────

class _ImageSection extends StatelessWidget {
  final ArticleEntity article;
  const _ImageSection({required this.article});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: article.imageUrl ?? kDefaultImage,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: const Color(0xFF2A3A4A)),
            errorWidget: (_, __, ___) =>
                Container(color: const Color(0xFF2A3A4A)),
          ),
          // Subtle scrim so image blends into dark card
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x881E2B38)],
                stops: [0.5, 1.0],
              ),
            ),
          ),
          if (article.category != null)
            Positioned(
              left: 12,
              top: 12,
              child: _CategoryPill(category: article.category!),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: _SourceBadge(
                isOriginal: article.remoteId?.isNotEmpty == true),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
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

class _SourceBadge extends StatelessWidget {
  final bool isOriginal;
  const _SourceBadge({required this.isOriginal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_outlined, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            isOriginal ? 'Original' : 'News API',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark info card ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final ArticleEntity article;
  final bool isJournalistArticle;

  const _InfoSection({
    required this.article,
    required this.isJournalistArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (article.description != null) ...[
            const SizedBox(height: 4),
            Text(
              article.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (article.author != null) ...[
                _AuthorAvatar(name: article.author!),
                const SizedBox(width: 8),
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
              ] else
                const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white30,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatDate(article.publishedAt),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          if (isJournalistArticle &&
              (article.badgeBias != null || article.badgeFactCheck != null)) ...[
            const SizedBox(height: 10),
            _AiBadgeRow(
              badgeBias: article.badgeBias,
              badgeFactCheck: article.badgeFactCheck,
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String name;
  const _AuthorAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF3A4F63),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── AI badge row ───────────────────────────────────────────────────────────────

class _AiBadgeRow extends StatelessWidget {
  final String? badgeBias;
  final String? badgeFactCheck;

  const _AiBadgeRow({this.badgeBias, this.badgeFactCheck});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (badgeBias != null) {
      final color = _biasColor(badgeBias!);
      badges.add(_AiBadge(
        dotColor: color,
        label: _biasLabel(badgeBias!),
        textColor: color,
      ));
    }
    if (badgeFactCheck != null) {
      final color = _factCheckColor(badgeFactCheck!);
      badges.add(_AiBadge(
        dotColor: color,
        label: _factCheckLabel(badgeFactCheck!, color),
        textColor: color,
        icon: _factCheckIcon(badgeFactCheck!),
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, children: badges);
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
        return Colors.blue.shade300;
      case 'right':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade400;
    }
  }

  String _factCheckLabel(String status, Color color) {
    switch (status) {
      case 'verified':
        return 'Credible';
      case 'disputed':
        return 'Disputed';
      default:
        return 'Unverified';
    }
  }

  Color _factCheckColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF22C55E);
      case 'disputed':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData? _factCheckIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.shield_outlined;
      case 'disputed':
        return Icons.warning_amber_outlined;
      default:
        return null;
    }
  }
}

class _AiBadge extends StatelessWidget {
  final Color dotColor;
  final String label;
  final Color textColor;
  final IconData? icon;

  const _AiBadge({
    required this.dotColor,
    required this.label,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

