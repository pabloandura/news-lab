import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/auth/domain/usecases/get_current_user.dart';
import 'package:news_lab/features/auth/domain/usecases/sign_in.dart';
import 'package:news_lab/features/auth/domain/usecases/sign_out.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_event.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthBloc(
    this._signInUseCase,
    this._signOutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  void _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) {
    final user = _getCurrentUserUseCase();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
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
