import 'package:news_lab/core/usecase/usecase.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';

class ForgotPasswordUseCase implements UseCase<void, String> {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  @override
  Future<void> call(String email) =>
      _repository.sendPasswordResetEmail(email: email);
}
