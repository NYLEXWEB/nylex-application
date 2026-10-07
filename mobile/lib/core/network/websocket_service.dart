import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

typedef MessageCallback = void Function(Map<String, dynamic> data);

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String? _currentUserId;

  final List<MessageCallback> _listeners = [];

  bool get isConnected => _isConnected;

  void addListener(MessageCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(MessageCallback callback) {
    _listeners.remove(callback);
  }

  void connect(String userId) {
    if (_isConnected && _currentUserId == userId) return;
    disconnect();

    _currentUserId = userId;
    final wsUrl = ApiConstants.chatWs(userId);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _subscription = _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString()) as Map<String, dynamic>;
            for (final listener in _listeners) {
              listener(data);
            }
          } catch (_) {}
        },
        onError: (error) {
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (_) {
      _isConnected = false;
    }
  }

  void sendMessage({
    required String text,
    String? recipientId,
    String chatType = "general",
    String? projectId,
  }) {
    if (_channel != null && _isConnected) {
      final payload = {
        "type": "send_message",
        "message": text,
        "recipientId": recipientId,
        "chatType": chatType,
        "projectId": projectId,
      };
      _channel?.sink.add(jsonEncode(payload));
    }
  }

  void sendTypingIndicator({
    required bool isTyping,
    String chatType = "general",
    String? projectId,
  }) {
    if (_channel != null && _isConnected) {
      final payload = {
        "type": "typing",
        "isTyping": isTyping,
        "chatType": chatType,
        "projectId": projectId,
      };
      _channel?.sink.add(jsonEncode(payload));
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}
