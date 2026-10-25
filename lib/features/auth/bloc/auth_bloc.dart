import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn;
  static const String _tag = 'AuthBloc';

  AuthBloc({
    required AuthRepository authRepository,
    GoogleSignIn? googleSignIn,
  })  : _authRepository = authRepository,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        super(const AuthState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          errorMessage: null,
        ));
      }
    } catch (e) {
      AppLogger.w(_tag, 'Check auth status failed: $e');
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    }
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Login error: $e');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await _authRepository.register(
        username: event.username,
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Register error: $e');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      String? idToken = event.idToken;
      String? email = event.email;
      String? displayName = event.displayName;
      String? avatarUrl = event.avatarUrl;

      // If native credentials not pre-provided, prompt Google Sign-In SDK
      if (idToken == null && email == null) {
        try {
          final account = await _googleSignIn.signIn();
          if (account == null) {
            // User cancelled Google sign-in dialog
            emit(state.copyWith(status: AuthStatus.unauthenticated));
            return;
          }
          final auth = await account.authentication;
          idToken = auth.idToken;
          email = account.email;
          displayName = account.displayName;
          avatarUrl = account.photoUrl;
        } catch (sdkError) {
          AppLogger.w(_tag, 'Native GoogleSignIn SDK unavailable, using provided claims or demo: $sdkError');
          // If SDK fails in desktop/test environment, throw or fallback to claims
          if (email == null) {
            rethrow;
          }
        }
      }

      final user = await _authRepository.signInWithGoogle(
        idToken: idToken,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      ));
    } catch (e) {
      AppLogger.e(_tag, 'Google sign-in error: $e');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: _extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _authRepository.logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      errorMessage: null,
    ));
  }

  String _extractErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('401') || str.contains('Unauthorized')) {
      return 'Invalid email or password. Please try again.';
    }
    if (str.contains('409') || str.contains('Conflict')) {
      return 'An account with this email or username already exists.';
    }
    return str.replaceAll('Exception:', '').trim();
  }
}
