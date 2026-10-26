import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

class IncomingFileService {
  static const String _tag = 'IncomingFileService';
  static const MethodChannel _channel = MethodChannel('com.book.bookies/open_file');

  final StreamController<String> _fileStreamController = StreamController<String>.broadcast();
  Stream<String> get onFileReceived => _fileStreamController.stream;

  bool _initialized = false;

  void initialize({Function(String filePath)? onFileOpened}) {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened') {
        final filePath = call.arguments as String?;
        if (filePath != null && filePath.isNotEmpty) {
          AppLogger.i(_tag, 'Received incoming file from system intent: $filePath');
          _fileStreamController.add(filePath);
          onFileOpened?.call(filePath);
        }
      }
    });

    // Check if app was opened with a file on cold start
    _channel.invokeMethod<String>('getInitialFile').then((initialPath) {
      if (initialPath != null && initialPath.isNotEmpty) {
        AppLogger.i(_tag, 'Cold start with file: $initialPath');
        _fileStreamController.add(initialPath);
        onFileOpened?.call(initialPath);
      }
    }).catchError((e) {
      AppLogger.w(_tag, 'Could not retrieve initial file: $e');
    });
  }

  void dispose() {
    _fileStreamController.close();
  }
}
