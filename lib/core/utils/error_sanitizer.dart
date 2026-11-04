import 'dart:io';
import 'package:dio/dio.dart';
import '../diagnostics/diagnostics_service.dart';

class ErrorSanitizer {
  /// Format any technical exception into a polite, user-friendly string
  /// and automatically log the full diagnostics to Sentry.
  static String formatAndReport(
    dynamic error, {
    dynamic stackTrace,
    String? contextTag,
    String? bookTitle,
    Map<String, dynamic>? extra,
  }) {
    // 1. Silently record detailed diagnostics to Sentry and local logs
    final enrichedExtra = <String, dynamic>{
      if (bookTitle != null) 'book_title': bookTitle,
      if (extra != null) ...extra,
    };

    DiagnosticsService.instance.captureException(
      error,
      stackTrace: stackTrace,
      tag: contextTag ?? 'ErrorSanitizer',
      extra: enrichedExtra,
    );

    // 2. Generate clean, user-friendly message
    return toUserMessage(error, bookTitle: bookTitle);
  }

  /// Pure message formatter without logging side effects
  static String toUserMessage(dynamic error, {String? bookTitle}) {
    if (error == null) return 'An unexpected error occurred.';

    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 404) {
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          final serverMsg = data['message'].toString();
          return '$serverMsg You can import an EPUB file directly into your library.';
        }
        if (bookTitle != null && bookTitle.isNotEmpty) {
          return '“$bookTitle” is currently unavailable for direct download. You can import an EPUB file directly into your library.';
        }
        return 'The requested book is currently unavailable for direct download. You can import an EPUB file directly into your library.';
      }

      if (statusCode == 401 || statusCode == 403) {
        return 'Your session has expired or is unauthorized. Please sign in again.';
      }

      if (statusCode == 409) {
        return 'An item with these details already exists.';
      }

      if (statusCode == 429) {
        return 'Too many requests. Please wait a moment before trying again.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'The Bookies server is momentarily undergoing maintenance. Please try again shortly.';
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return 'Unable to reach the server. Please check your internet connection and try again.';
        case DioExceptionType.transformTimeout:
          return 'Data processing timed out. Please try again.';
        case DioExceptionType.cancel:
          return 'The request was cancelled.';
        case DioExceptionType.badCertificate:
          return 'A secure connection could not be established.';
        case DioExceptionType.badResponse:
          return 'Received an unexpected response from the server. Please try again.';
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'No internet connection. Please verify your network and try again.';
          }
          return 'Network error encountered. Please check your connection.';
      }
    }

    if (error is SocketException) {
      return 'Unable to connect to the internet. Please verify your connection.';
    }

    if (error is HttpException) {
      return 'A network communication error occurred. Please try again.';
    }

    if (error is FormatException) {
      return 'Data processing error. Please try again.';
    }

    final raw = error.toString().replaceAll('Exception:', '').replaceAll('Error:', '').trim();

    // Check if the string contains leaked technical jargon or stack traces
    final technicalIndicators = [
      'dioexception',
      'validatestatus',
      'bad response',
      'socketexception',
      'xmlhttprequest',
      'status code of',
      'requestoptions',
      'cannot get',
      'stacktrace',
      'unhandled',
      'null pointer',
    ];

    final isTechnical = technicalIndicators.any((tech) => raw.toLowerCase().contains(tech));
    if (isTechnical) {
      if (bookTitle != null && bookTitle.isNotEmpty) {
        return 'Unable to download “$bookTitle” right now. You can import an EPUB file directly into your library.';
      }
      return 'Something went wrong while completing this request. Please try again.';
    }

    return raw.isNotEmpty ? raw : 'An unexpected error occurred. Please try again.';
  }
}
