import 'package:news_lab/features/fact_check/domain/entities/fact_check_entity.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';

class WatchBotCheckParams {
  final String articleId;
  const WatchBotCheckParams({required this.articleId});
}

class WatchBotCheckUseCase {
  final FactCheckRepository _repository;
  const WatchBotCheckUseCase(this._repository);

  Stream<BotCheckEntity?> call(WatchBotCheckParams params) =>
      _repository.watchBotCheck(articleId: params.articleId);
}
