import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/auth/domain/entities/user_entity.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});
}

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  @override
  Future<UserEntity> call(SignInParams params) {
    return _authRepository.signIn(
        email: params.email, password: params.password);
  }
}
