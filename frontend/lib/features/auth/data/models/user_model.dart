import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_lab/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
  });

  factory UserModel.fromFirebaseUser(User user) {
    final email = user.email ?? '';
    return UserModel(
      uid: user.uid,
      email: email,
      displayName: user.displayName?.isNotEmpty == true
          ? user.displayName
          : email.isNotEmpty
              ? email.split('@').first
              : null,
    );
  }

  UserEntity toEntity() => UserEntity(
        uid: uid,
        email: email,
        displayName: displayName,
      );
}
