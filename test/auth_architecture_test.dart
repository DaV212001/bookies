import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/auth_repository.dart';
import 'package:bookies/features/auth/bloc/auth_bloc.dart';
import 'package:bookies/features/auth/views/login_view.dart';
import 'package:bookies/features/auth/views/register_view.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? _currentUser;
  final StreamController<UserEntity?> _controller =
      StreamController<UserEntity?>.broadcast();

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  Future<UserEntity?> getCurrentUser() async => _currentUser;

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    _currentUser = UserEntity(
      id: 'test-user-1',
      username: 'testreader',
      displayName: 'Test Reader',
      email: email,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    _currentUser = UserEntity(
      id: 'test-user-2',
      username: username,
      displayName: displayName,
      email: email,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserEntity> signInWithGoogle({
    String? idToken,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    _currentUser = UserEntity(
      id: 'google-user-123',
      username: (email?.split('@').first ?? 'google_reader'),
      displayName: displayName ?? 'Google Reader',
      email: email ?? 'google@bookies.app',
      avatarUrl: avatarUrl,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<String?> getAccessToken() async => 'mock-jwt-token';
}

void main() {
  group('Auth Clean Architecture & Bloc Tests', () {
    late MockAuthRepository mockAuthRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthStatus.initial', () {
      expect(authBloc.state.status, equals(AuthStatus.initial));
      expect(authBloc.state.isAuthenticated, isFalse);
    });

    test('CheckAuthStatusEvent emits unauthenticated when no stored session', () async {
      authBloc.add(const CheckAuthStatusEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(status: AuthStatus.unauthenticated),
        ]),
      );
    });

    test('LoginWithEmailEvent emits loading then authenticated', () async {
      authBloc.add(const LoginWithEmailEvent(
        email: 'alice@bookies.app',
        password: 'password123',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          predicate<AuthState>((state) {
            return state.status == AuthStatus.authenticated &&
                state.user?.email == 'alice@bookies.app';
          }),
        ]),
      );
    });

    test('SignInWithGoogleEvent emits authenticated with Google claims', () async {
      authBloc.add(const SignInWithGoogleEvent(
        email: 'google_reader@bookies.app',
        displayName: 'Google Reader',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          predicate<AuthState>((state) {
            return state.status == AuthStatus.authenticated &&
                state.user?.displayName == 'Google Reader';
          }),
        ]),
      );
    });

    test('LogoutEvent clears authenticated session', () async {
      // First login
      await mockAuthRepository.login(email: 'alice@bookies.app', password: '123');

      authBloc.add(const LogoutEvent());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(status: AuthStatus.unauthenticated, user: null),
        ]),
      );
    });
  });

  group('Auth UI Rendering Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    testWidgets('LoginView renders editorial header, form fields, and Google button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthBloc(authRepository: mockAuthRepository),
            child: const LoginView(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Quick Login as Alice (Book Club Creator)'), findsOneWidget);
    });

    testWidgets('RegisterView renders full name, username, email, and Google Sign Up',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => AuthBloc(authRepository: mockAuthRepository),
            child: const RegisterView(),
          ),
        ),
      );

      expect(find.text('Join Bookies'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, User, Email, Pass
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign Up with Google'), findsOneWidget);
    });
  });
}
