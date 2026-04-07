import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

class ArticleWidget extends StatelessWidget {
  final ArticleEntity? article;
  final FactCheckEntity? factCheck;
  final BiasReportEntity? biasReport;
  final bool? isRemovable;
  final void Function(ArticleEntity article)? onRemove;
  final void Function(ArticleEntity article)? onArticlePressed;

  const ArticleWidget({
    super.key,
    this.article,
    this.factCheck,
    this.biasReport,
    this.onArticlePressed,
    this.isRemovable = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const thumbSize = 88.0;
    final isJournalistArticle = article!.remoteId?.isNotEmpty == true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 14, end: 14, bottom: 7, top: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: chips + title + description + meta ──────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category / journalist chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (article!.category != null)
                        _CategoryChip(label: article!.category!),
                      if (isJournalistArticle)
                        _JournalistChip(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article!.title ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article!.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.black38),
                      const SizedBox(width: 3),
                      Text(
                        formatDate(article!.publishedAt),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38),
                      ),
                    ],
                  ),
                  if (article!.badgeBias != null ||
                      article!.badgeFactCheck != null ||
                      (factCheck?.communityCheck?.totalVotes ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    _TileBadges(
                      badgeBias: article!.badgeBias,
                      badgeFactCheck: article!.badgeFactCheck,
                      communityCheck: factCheck?.communityCheck,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Right: thumbnail ──────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: article!.imageUrl ?? kDefaultImage,
                    width: thumbSize,
                    height: thumbSize,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: thumbSize,
                      height: thumbSize,
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: thumbSize,
                      height: thumbSize,
                      color: Colors.black.withValues(alpha: 0.07),
                      child: const Icon(Icons.broken_image_outlined,
                          size: 20, color: Colors.black26),
                    ),
                  ),
                ),
                _buildRemovableArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableArea() {
    if (isRemovable!) {
      return GestureDetector(
        onTap: _onRemove,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.remove_circle_outline, color: Colors.red),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _onTap() => onArticlePressed?.call(article!);
  void _onRemove() => onRemove?.call(article!);
}

// ── Category / journalist chips ──────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _JournalistChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8621A)),
      ),
      child: const Text(
        'YOUR ARTICLE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8621A),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Tile badge row ────────────────────────────────────────────────────────────

class _TileBadges extends StatelessWidget {
  final String? badgeBias;
  final String? badgeFactCheck;
  final CommunityCheckEntity? communityCheck;

  const _TileBadges({this.badgeBias, this.badgeFactCheck, this.communityCheck});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (badgeBias != null) {
      chips.add(_SmallChip(
        label: _biasLabel(badgeBias!),
        color: _biasColor(badgeBias!),
      ));
    }
    if (badgeFactCheck != null) {
      chips.add(_SmallChip(
        label: _factCheckLabel(badgeFactCheck!),
        color: _factCheckColor(badgeFactCheck!),
        icon: _factCheckIcon(badgeFactCheck!),
      ));
    }
    final cc = communityCheck;
    if (cc != null && cc.totalVotes > 0) {
      final moreAccurate = cc.accurateVotes >= cc.inaccurateVotes;
      chips.add(_SmallChip(
        label:
            '${moreAccurate ? cc.accurateVotes : cc.inaccurateVotes} ${moreAccurate ? 'accurate' : 'disputed'}',
        color: moreAccurate ? const Color(0xFF22C55E) : Colors.orange.shade400,
        icon: moreAccurate
            ? Icons.thumb_up_alt_outlined
            : Icons.thumb_down_alt_outlined,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 4, runSpacing: 4, children: chips);
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

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _SmallChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
