import 'package:flutter/material.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/similar_articles/domain/entities/similar_article_entity.dart';

class SimilarArticleTile extends StatelessWidget {
  final SimilarArticleEntity article;

  const SimilarArticleTile({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        final entity = ArticleEntity(
          title: article.title,
          author: article.source,
          description: article.snippet,
          content: article.snippet,
          url: article.url,
          publishedAt: article.publishedAt != null
              ? DateTime.tryParse(article.publishedAt!)
              : null,
        );
        Navigator.pushNamed(context, AppRoutes.articleDetails,
            arguments: entity);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.source,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
