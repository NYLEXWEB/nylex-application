import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/websocket_service.dart';
import '../core/constants/api_constants.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  bool _isPartnerTyping = false;
  String _activeChatType = "general";
  String? _activeProjectId;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  bool get isPartnerTyping => _isPartnerTyping;
  String get activeChatType => _activeChatType;

  void initWebSocket(String currentUserId) {
    _wsService.connect(currentUserId);
    _wsService.addListener(_handleIncomingWsMessage);
    fetchUnreadCount();
  }

  void _handleIncomingWsMessage(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'new_message') {
      final msgData = data['message'] as Map<String, dynamic>;
      final newMsg = ChatMessageModel.fromJson(msgData);
      
      // If current chat matches, append directly
      if (newMsg.chatType == _activeChatType &&
          (_activeChatType == "general" || newMsg.projectId == _activeProjectId)) {
        _messages.add(newMsg);
        notifyListeners();
      } else {
        _unreadCount++;
        notifyListeners();
      }
    } else if (type == 'typing') {
      if (data['chatType'] == _activeChatType) {
        _isPartnerTyping = data['isTyping'] ?? false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchMessages({String chatType = "general", String? projectId}) async {
    _activeChatType = chatType;
    _activeProjectId = projectId;
    _isLoading = true;
    notifyListeners();

    try {
      var url = "${ApiConstants.chatMessages}?chat_type=$chatType";
      if (chatType == "project" && projectId != null) {
        url += "&project_id=$projectId";
      }

      final res = await ApiClient.get(url);
      if (res is List) {
        _messages = res.map((m) => ChatMessageModel.fromJson(m)).toList();
      }
      await markAsRead(chatType: chatType, projectId: projectId);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text, {String? recipientId}) async {
    if (text.trim().isEmpty) return;
    
    // Post to REST API (which also broadcasts via WS)
    try {
      final res = await ApiClient.post(
        ApiConstants.chatMessages,
        body: {
          'message': text.trim(),
          'recipientId': recipientId,
          'chatType': _activeChatType,
          'projectId': _activeProjectId,
        },
      );
      if (res is Map<String, dynamic>) {
        final newMsg = ChatMessageModel.fromJson(res);
        if (!_messages.any((m) => m.id == newMsg.id)) {
          _messages.add(newMsg);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void setTyping(bool isTyping) {
    _wsService.sendTypingIndicator(
      isTyping: isTyping,
      chatType: _activeChatType,
      projectId: _activeProjectId,
    );
  }

  Future<void> markAsRead({String chatType = "general", String? projectId}) async {
    try {
      var url = "${ApiConstants.chatRead}?chat_type=$chatType";
      if (chatType == "project" && projectId != null) {
        url += "&project_id=$projectId";
      }
      await ApiClient.put(url);
      await fetchUnreadCount();
    } catch (_) {}
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await ApiClient.get(ApiConstants.chatUnreadCount);
      if (res is Map<String, dynamic>) {
        _unreadCount = res['unreadCount'] ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
