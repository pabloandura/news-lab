abstract class RemoteArticlesEvent {
  const RemoteArticlesEvent();
}

class GetArticles extends RemoteArticlesEvent {
  final String? category; // null = all
  const GetArticles({this.category});
}

/// Re-fetches fact checks and bias reports for the currently loaded articles,
/// without reloading the article list itself.
class RefreshFactChecks extends RemoteArticlesEvent {
  const RefreshFactChecks();
}
