import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';

class SignOutUseCase implements NoParamsUseCase<void> {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  @override
  Future<void> call() => _authRepository.signOut();
}
