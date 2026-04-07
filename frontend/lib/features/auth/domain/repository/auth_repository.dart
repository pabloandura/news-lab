import 'package:news_lab/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn({required String email, required String password});
  Future<UserEntity> signUp({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  UserEntity? getCurrentUser();
  Stream<UserEntity?> watchAuthState();
}
