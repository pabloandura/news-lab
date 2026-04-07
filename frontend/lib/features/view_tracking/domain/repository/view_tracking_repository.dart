abstract class ViewTrackingRepository {
  Future<void> trackView({
    required String articleId,
    required String authorId,
  });
}
