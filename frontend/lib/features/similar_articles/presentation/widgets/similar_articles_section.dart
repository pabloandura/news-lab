import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_bloc.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_event.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_state.dart';
import 'package:news_lab/features/similar_articles/presentation/widgets/similar_article_tile.dart';

class SimilarArticlesSection extends StatefulWidget {
  final String articleId;

  const SimilarArticlesSection({super.key, required this.articleId});

  @override
  State<SimilarArticlesSection> createState() => _SimilarArticlesSectionState();
}

class _SimilarArticlesSectionState extends State<SimilarArticlesSection> {
  @override
  void initState() {
    super.initState();
    if (widget.articleId.isNotEmpty) {
      context.read<SimilarArticlesBloc>().add(LoadSimilarArticles(widget.articleId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimilarArticlesBloc, SimilarArticlesState>(
      builder: (context, state) {
        return switch (state) {
          SimilarArticlesInitial() => const SizedBox.shrink(),
          SimilarArticlesLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Finding related coverage…',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          SimilarArticlesLoaded(:final results) when results.isEmpty =>
            const SizedBox.shrink(),
          SimilarArticlesLoaded(:final results) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Ionicons.layers_outline,
                        size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 5),
                    Text(
                      'Related coverage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...results.map((a) => SimilarArticleTile(article: a)),
              ],
            ),
          SimilarArticlesError() => const SizedBox.shrink(),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
