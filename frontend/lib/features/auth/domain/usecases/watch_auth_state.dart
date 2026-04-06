import 'package:news_lab/features/auth/domain/entities/user_entity.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';

class WatchAuthStateUseCase {
  final AuthRepository _authRepository;

  WatchAuthStateUseCase(this._authRepository);

  Stream<UserEntity?> call() => _authRepository.watchAuthState();
}
