import 'package:news_lab/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:news_lab/features/auth/domain/entities/user_entity.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> signIn(
          {required String email, required String password}) =>
      _dataSource.signIn(email: email, password: password);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  UserEntity? getCurrentUser() => _dataSource.getCurrentUser();
}
