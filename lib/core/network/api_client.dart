import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  static const String tokenKey = 'bookies_jwt_access_token';
  String? _cachedToken;
  String? get cachedToken => _cachedToken;

  ApiClient({
    required String baseUrl,
    Dio? dioClient,
    FlutterSecureStorage? storage,
  })  : dio = dioClient ?? Dio(),
        secureStorage = storage ?? const FlutterSecureStorage() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          AppLogger.d('ApiClient', 'Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          AppLogger.e('ApiClient', 'Response Error [${error.response?.statusCode}]: ${error.message}');
          // If 401 Unauthorized, we can handle refresh token or trigger logout
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await secureStorage.write(key: tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await secureStorage.delete(key: tokenKey);
  }

  Future<String?> getToken() async {
    _cachedToken = await secureStorage.read(key: tokenKey);
    return _cachedToken;
  }

  String get baseUrl => dio.options.baseUrl;
}
