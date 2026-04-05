import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';

class ArticleWidget extends StatelessWidget {
  final ArticleEntity? article;
  final FactCheckEntity? factCheck;
  final bool? isRemovable;
  final void Function(ArticleEntity article)? onRemove;
  final void Function(ArticleEntity article)? onArticlePressed;

  const ArticleWidget({
    super.key,
    this.article,
    this.factCheck,
    this.onArticlePressed,
    this.isRemovable = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidth = MediaQuery.of(context).size.width / 3;
    const imageHeight = 140.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 14, end: 14, bottom: 7, top: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: CachedNetworkImage(
                imageUrl: article!.imageUrl ?? kDefaultImage,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: imageWidth,
                  height: imageHeight,
                  color: Colors.black.withValues(alpha: 0.08),
                  child: const CupertinoActivityIndicator(),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: imageWidth,
                  height: imageHeight,
                  color: Colors.black.withValues(alpha: 0.08),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article!.title ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article!.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  if (factCheck != null) ...[
                    const SizedBox(height: 6),
                    _FactCheckBadgeRow(factCheck: factCheck!),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(article!.publishedAt),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildRemovableArea(),
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

/// Read-only badge row for list tiles. No BLoC, no voting controls.
/// Tapping the tile navigates to detail where the full interactive version lives.
class _FactCheckBadgeRow extends StatelessWidget {
  final FactCheckEntity factCheck;

  const _FactCheckBadgeRow({required this.factCheck});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (factCheck.botCheck != null)
          _Badge(
            icon: Icons.smart_toy_outlined,
            label: 'Bot checked',
            color: Colors.orange,
          ),
        if (factCheck.communityCheck != null &&
            factCheck.communityCheck!.totalVotes > 0)
          _Badge(
            icon: Icons.people_outline,
            label: '${factCheck.communityCheck!.totalVotes} votes',
            color: Colors.blue,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
