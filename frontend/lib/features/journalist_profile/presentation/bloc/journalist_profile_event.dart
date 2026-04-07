import 'package:news_lab/features/journalist_profile/domain/usecases/journalist_profile_params.dart';

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
