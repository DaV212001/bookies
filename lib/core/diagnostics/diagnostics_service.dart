import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../utils/app_logger.dart';

class DiagnosticsService {
  static final DiagnosticsService instance = DiagnosticsService._internal();
  DiagnosticsService._internal();

  static const String sentryDsn =
      'https://38daf0e93b66dd11783a37e87336df9b@o4512373368225793.ingest.de.sentry.io/4512373380808784';

  bool _isInitialized = false;
  Map<String, String> _deviceInfo = {};
  String _appVersion = 'Unknown';

  Map<String, String> get deviceInfo => Map.unmodifiable(_deviceInfo);
  String get appVersion => _appVersion;

  /// Gather device hardware and OS info for diagnostics
  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      final deviceInfoPlugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        _deviceInfo = {
          'platform': 'Web',
          'browser': webInfo.browserName.name,
          'userAgent': webInfo.userAgent ?? 'Unknown',
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfo = {
          'platform': 'Android',
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt.toString(),
          'isPhysical': androidInfo.isPhysicalDevice.toString(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'isPhysical': iosInfo.isPhysicalDevice.toString(),
        };
      } else {
        _deviceInfo = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      AppLogger.w('DiagnosticsService', 'Failed to load device info: $e');
    }
  }

  /// Initialize Sentry and client diagnostics
  Future<void> init({required Future<void> Function() appRunner}) async {
    if (_isInitialized) {
      await appRunner();
      return;
    }

    await _loadDeviceInfo();
    _isInitialized = true;

    AppLogger.i(
      'DiagnosticsService',
      'Initialized client diagnostics: model=${_deviceInfo['model'] ?? _deviceInfo['platform']}, version=$_appVersion',
    );

    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.attachScreenshot = false;
        options.attachViewHierarchy = false;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.release = 'com.book.bookies@$_appVersion';
      },
      appRunner: appRunner,
    );

    Sentry.configureScope((scope) {
      _deviceInfo.forEach((key, value) {
        scope.setTag('device.$key', value);
      });
    });
  }

  /// Attach authenticated user profile to diagnostics & Sentry
  void setUser({
    required String id,
    required String username,
    String? displayName,
    String? email,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          id: id,
          username: username,
          email: email,
          data: {
            'displayName': displayName ?? username,
            'deviceModel': _deviceInfo['model'] ?? 'Unknown',
            'osVersion': _deviceInfo['androidVersion'] ?? _deviceInfo['systemVersion'] ?? 'Unknown',
          },
        ),
      );
    });

    AppLogger.i('DiagnosticsService', 'Diagnostics user scope updated: $username ($id)');
  }

  /// Clear user profile on sign out
  void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
    AppLogger.i('DiagnosticsService', 'Diagnostics user scope cleared');
  }

  /// Record navigation or user action breadcrumb
  void logBreadcrumb(String message, {String category = 'action', Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        timestamp: DateTime.now().toUtc(),
        data: data,
        level: SentryLevel.info,
      ),
    );
  }

  /// Capture and report detailed exception diagnostics
  Future<void> captureException(
    dynamic error, {
    dynamic stackTrace,
    String? tag,
    Map<String, dynamic>? extra,
  }) async {
    final contextTag = tag ?? 'General';
    final timestamp = DateTime.now().toIso8601String();

    AppLogger.e(
      'DiagnosticsService',
      '[$contextTag] Diagnostic event captured at $timestamp: $error',
      error,
      stackTrace is StackTrace ? stackTrace : null,
    );

    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_tag', contextTag);
          _deviceInfo.forEach((k, v) => scope.setTag('device.$k', v));
          if (extra != null) {
            scope.setContexts('DiagnosticsContext', extra);
          }
        },
      );
    } catch (sentryErr) {
      AppLogger.w('DiagnosticsService', 'Sentry capture failed: $sentryErr');
    }
  }
}
