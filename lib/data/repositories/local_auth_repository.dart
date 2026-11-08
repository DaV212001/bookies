import 'dart:async';
import 'package:bookies/core/network/api_client.dart';
import 'package:bookies/data/models/user.dart';
import 'package:bookies/data/providers/local_data_service.dart';
import 'package:bookies/domain/entities/user_entity.dart';
import 'package:bookies/domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  final LocalDataService _localDataService;
  final ApiClient _apiClient;
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  LocalAuthRepository(this._localDataService, this._apiClient);

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _localDataService.currentUser.toDomain();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    // In local mode, authenticated as current user
    final user = _localDataService.currentUser.toDomain();
    await _apiClient.saveToken('mock_jwt_token_${user.id}');
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserEntity> signInWithGoogle({
    required String idToken,
    String? displayName,
    String? avatarUrl,
  }) async {
    final googleUser = User(
      id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
      username: 'google_reader_${DateTime.now().millisecondsSinceEpoch % 1000}',
      displayName: displayName ?? 'Google Reader',
    );
    _localDataService.currentUser = googleUser;
    final entity = googleUser.toDomain();
    await _apiClient.saveToken('mock_jwt_token_${googleUser.id}');
    _authStateController.add(entity);
    return entity;
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      displayName: displayName,
    );
    _localDataService.currentUser = newUser;
    final entity = newUser.toDomain();
    await _apiClient.saveToken('mock_jwt_token_${newUser.id}');
    _authStateController.add(entity);
    return entity;
  }

  @override
  Future<UserEntity> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final current = _localDataService.currentUser;
    final updated = User(
      id: current.id,
      username: (username != null && username.trim().isNotEmpty) ? username.trim().toLowerCase() : current.username,
      displayName: (displayName != null && displayName.trim().isNotEmpty) ? displayName.trim() : current.displayName,
      avatarUrl: avatarUrl ?? current.avatarUrl,
    );
    _localDataService.currentUser = updated;
    final entity = updated.toDomain();
    _authStateController.add(entity);
    return entity;
  }

  @override
  Future<void> logout() async {
    await _apiClient.clearToken();
    _authStateController.add(null);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _apiClient.getToken();
  }

  void dispose() {
    _authStateController.close();
  }
}
