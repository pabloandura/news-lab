import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/author_stats_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/bias_landscape_entity.dart';
import 'package:news_lab/features/analytics/domain/entities/daily_views_entity.dart';

abstract class AnalyticsRemoteDataSource {
  Future<List<ArticleEntity>> getTrendingArticles();
  Future<BiasLandscapeEntity> getBiasLandscape();
  Future<AuthorStatsEntity> getAuthorStats(String authorId);
  Future<List<DailyViewsEntity>> getWeeklyViews(String authorId);
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final FirebaseFirestore _firestore;

  AnalyticsRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<ArticleEntity>> getTrendingArticles() async {
    final viewsSnap = await _firestore
        .collection(articleViewsCollection)
        .orderBy('viewCount', descending: true)
        .limit(10)
        .get();

    if (viewsSnap.docs.isEmpty) return [];

    final articleIds = viewsSnap.docs.map((d) => d.id).toList();
    final articleFutures = articleIds.map(
      (id) => _firestore.collection(articlesCollection).doc(id).get(),
    );
    final articleDocs = await Future.wait(articleFutures);

    final results = <ArticleEntity>[];
    for (final doc in articleDocs) {
      if (!doc.exists) continue;
      final data = doc.data()!;
      results.add(ArticleEntity(
        remoteId: doc.id,
        author: data['author'] as String?,
        authorId: data['authorId'] as String?,
        title: data['title'] as String?,
        description: data['description'] as String?,
        content: data['content'] as String?,
        imageUrl: (data['thumbnailUrl'] as String?)?.isNotEmpty == true
            ? data['thumbnailUrl'] as String
            : null,
        category: (data['category'] as String?)?.isNotEmpty == true
            ? data['category'] as String
            : null,
        publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
        badgeBias: data['badgeBias'] as String?,
        badgeFactCheck: data['badgeFactCheck'] as String?,
      ));
    }
    return results;
  }

  @override
  Future<BiasLandscapeEntity> getBiasLandscape() async {
    final doc = await _firestore
        .collection(statsCollection)
        .doc(biasLandscapeDoc)
        .get();

    if (!doc.exists) {
      return const BiasLandscapeEntity(
          leftCount: 0, centerCount: 0, rightCount: 0, totalCount: 0);
    }
    final data = doc.data()!;
    return BiasLandscapeEntity(
      leftCount: (data['leftCount'] as num?)?.toInt() ?? 0,
      centerCount: (data['centerCount'] as num?)?.toInt() ?? 0,
      rightCount: (data['rightCount'] as num?)?.toInt() ?? 0,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<AuthorStatsEntity> getAuthorStats(String authorId) async {
    final articlesCountQuery = await _firestore
        .collection(articlesCollection)
        .where('authorId', isEqualTo: authorId)
        .count()
        .get();
    final articleCount = articlesCountQuery.count ?? 0;

    final viewsQuery = await _firestore
        .collection(articleViewsCollection)
        .where('authorId', isEqualTo: authorId)
        .get();
    final totalViews = viewsQuery.docs.fold<int>(
      0,
      (acc, doc) => acc + ((doc.data()['viewCount'] as num?)?.toInt() ?? 0),
    );

    // Fetch article IDs for fact_check vote aggregation
    // TODO: denormalize authorId onto fact_checks for O(1) aggregation when author article counts grow large
    final articleIds = viewsQuery.docs.map((d) => d.id).toList();
    int totalUpvotes = 0;
    if (articleIds.isNotEmpty) {
      final factCheckFutures = articleIds.map(
        (id) => _firestore.collection(factChecksCollection).doc(id).get(),
      );
      final factCheckDocs = await Future.wait(factCheckFutures);
      for (final doc in factCheckDocs) {
        if (!doc.exists) continue;
        final data = doc.data()!;
        final community = data['communityCheck'] as Map<String, dynamic>?;
        if (community != null) {
          totalUpvotes +=
              (community['accurateVotes'] as num?)?.toInt() ?? 0;
        }
      }
    }

    return AuthorStatsEntity(
      articleCount: articleCount,
      totalViews: totalViews,
      totalUpvotes: totalUpvotes,
    );
  }

  @override
  Future<List<DailyViewsEntity>> getWeeklyViews(String authorId) async {
    final snap = await _firestore
        .collection(authorDailyViewsCollection)
        .doc(authorId)
        .collection(daysSubcollection)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(7)
        .get();

    return snap.docs
        .map((doc) => DailyViewsEntity(
              date: doc.id,
              count: (doc.data()['count'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }
}
