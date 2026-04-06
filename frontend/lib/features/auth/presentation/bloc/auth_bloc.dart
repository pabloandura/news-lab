import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/auth/domain/entities/user_entity.dart';
import 'package:news_lab/features/auth/domain/usecases/sign_in.dart';
import 'package:news_lab/features/auth/domain/usecases/sign_out.dart';
import 'package:news_lab/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_event.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final WatchAuthStateUseCase _watchAuthState;

  AuthBloc(
    this._signInUseCase,
    this._signOutUseCase,
    this._watchAuthState,
  ) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    await emit.forEach<UserEntity?>(
      _watchAuthState(),
      onData: (user) =>
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
    );
  }

  void _onSignInRequested(
      SignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _signInUseCase(
          SignInParams(email: event.email, password: event.password));
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    await _signOutUseCase();
    emit(const AuthUnauthenticated());
  }
}
