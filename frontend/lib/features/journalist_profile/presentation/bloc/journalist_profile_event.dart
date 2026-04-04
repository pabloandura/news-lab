import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';

abstract class JournalistProfileEvent {
  const JournalistProfileEvent();
}

class LoadJournalistProfile extends JournalistProfileEvent {
  final String authorId;
  const LoadJournalistProfile(this.authorId);
}

class DeleteArticleRequested extends JournalistProfileEvent {
  final String articleId;
  const DeleteArticleRequested(this.articleId);
}

class UpdateArticleRequested extends JournalistProfileEvent {
  final UpdateArticleParams params;
  const UpdateArticleRequested(this.params);
}
