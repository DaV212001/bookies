import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/app_logger.dart';

enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SocketService {
  final String serverUrl;
  final String? Function() tokenProvider;
  io.Socket? _socket;
  final StreamController<SocketConnectionState> _connectionStateController =
      StreamController<SocketConnectionState>.broadcast();

  Stream<SocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  SocketService({
    required this.serverUrl,
    required this.tokenProvider,
  });

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _connectionStateController.add(SocketConnectionState.connecting);
    AppLogger.i('SocketService', 'Connecting to NestJS Socket.IO Gateway at $serverUrl');

    final token = tokenProvider();

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setAuth(token != null ? {'token': token} : {})
          .build(),
    );

    _socket?.onConnect((_) {
      AppLogger.i('SocketService', 'Connected to Socket.IO gateway');
      _connectionStateController.add(SocketConnectionState.connected);
    });

    _socket?.onDisconnect((_) {
      AppLogger.w('SocketService', 'Disconnected from Socket.IO gateway');
      _connectionStateController.add(SocketConnectionState.disconnected);
    });

    _socket?.onConnectError((err) {
      AppLogger.e('SocketService', 'Socket.IO connect error: $err');
      _connectionStateController.add(SocketConnectionState.error);
    });

    _socket?.onError((err) {
      AppLogger.e('SocketService', 'Socket.IO error: $err');
    });
  }

  void joinRoom(String roomName) {
    if (_socket == null) return;
    _socket?.emit('join_room', {'room': roomName});
    AppLogger.d('SocketService', 'Emitted join_room for $roomName');
  }

  void leaveRoom(String roomName) {
    if (_socket == null) return;
    _socket?.emit('leave_room', {'room': roomName});
    AppLogger.d('SocketService', 'Emitted leave_room for $roomName');
  }

  void emit(String event, dynamic data) {
    if (_socket == null) return;
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionStateController.add(SocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
  }
}
