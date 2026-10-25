import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Get currently authenticated user or null
  Future<UserEntity?> getCurrentUser();

  /// Stream auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Login with email & password
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  /// Sign in with Google account (native OAuth ID token or profile claims)
  Future<UserEntity> signInWithGoogle({
    String? idToken,
    String? email,
    String? displayName,
    String? avatarUrl,
  });

  /// Register new reader account
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  });

  /// Log out and invalidate local tokens
  Future<void> logout();

  /// Retrieve the current JWT access token for API / Socket.IO handshake
  Future<String?> getAccessToken();
}
