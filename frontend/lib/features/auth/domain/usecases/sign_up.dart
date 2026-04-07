import 'package:news_lab/features/auth/domain/entities/user_entity.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';
import 'package:news_lab/core/usecase/usecase.dart';

class SignUpParams {
  final String email;
  final String password;

  const SignUpParams({required this.email, required this.password});
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  @override
  Future<UserEntity> call(SignUpParams params) =>
      _repository.signUp(email: params.email, password: params.password);
}
