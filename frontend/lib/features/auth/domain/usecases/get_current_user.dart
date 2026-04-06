import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/auth/domain/entities/user_entity.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';

class GetCurrentUserUseCase implements SyncNoParamsUseCase<UserEntity?> {
  final AuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  @override
  UserEntity? call() => _authRepository.getCurrentUser();
}
