import 'package:flutter/foundation.dart';
import 'package:news_lab/core/data/data_sources/view_tracking_remote_data_source.dart';
import 'package:news_lab/features/view_tracking/domain/repository/view_tracking_repository.dart';

class ViewTrackingRepositoryImpl implements ViewTrackingRepository {
  final ViewTrackingRemoteDataSource _dataSource;
  final _trackedThisSession = <String>{};

  ViewTrackingRepositoryImpl(this._dataSource);

  @override
  Future<void> trackView({
    required String articleId,
    required String authorId,
  }) async {
    if (_trackedThisSession.contains(articleId)) return;
    _trackedThisSession.add(articleId);
    try {
      await _dataSource.trackView(articleId: articleId, authorId: authorId);
    } on Exception catch (e) {
      debugPrint('[ViewTrackingRepository] Failed to track view: $e');
      _trackedThisSession.remove(articleId);
    }
  }
}
