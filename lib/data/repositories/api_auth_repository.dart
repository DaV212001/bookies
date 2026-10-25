import 'dart:async';
import 'package:bookies/core/network/api_client.dart';
import 'package:bookies/core/utils/app_logger.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  static const String _tag = 'ApiAuthRepository';

  ApiAuthRepository(this._apiClient);

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = await _apiClient.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        final user = _mapJsonToUser(response.data);
        _authStateController.add(user);
        return user;
      }
    } catch (e) {
      AppLogger.w(_tag, 'Failed to fetch current user profile: $e');
    }
    return null;
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final token = response.data['accessToken'] as String;
      await _apiClient.saveToken(token);

      final user = _mapJsonToUser(response.data['user']);
      _authStateController.add(user);
      AppLogger.i(_tag, 'User logged in: ${user.email} (${user.id})');
      return user;
    } catch (e) {
      AppLogger.e(_tag, 'Login failed', e);
      rethrow;
    }
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'username': username.trim().toLowerCase(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'displayName': displayName.trim(),
        },
      );

      final token = response.data['accessToken'] as String;
      await _apiClient.saveToken(token);

      final user = _mapJsonToUser(response.data['user']);
      _authStateController.add(user);
      AppLogger.i(_tag, 'User registered: ${user.email} (${user.id})');
      return user;
    } catch (e) {
      AppLogger.e(_tag, 'Registration failed', e);
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithGoogle({
    String? idToken,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/google',
        data: {
          if (idToken != null) 'idToken': idToken,
          if (email != null) 'email': email.trim().toLowerCase(),
          if (displayName != null) 'displayName': displayName,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );

      final token = response.data['accessToken'] as String;
      await _apiClient.saveToken(token);

      final user = _mapJsonToUser(response.data['user']);
      _authStateController.add(user);
      AppLogger.i(_tag, 'Google Sign-In successful: ${user.email} (${user.id})');
      return user;
    } catch (e) {
      AppLogger.e(_tag, 'Google Sign-In failed', e);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _apiClient.clearToken();
    _authStateController.add(null);
    AppLogger.i(_tag, 'User logged out and tokens cleared');
  }

  @override
  Future<String?> getAccessToken() async {
    return await _apiClient.getToken();
  }

  UserEntity _mapJsonToUser(dynamic json) {
    return UserEntity(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Reader',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  void dispose() {
    _authStateController.close();
  }
}
