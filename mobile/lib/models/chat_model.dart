class ChatMessageModel {
  final String id;
  final String senderId;
  final String? senderName;
  final String? recipientId;
  final String chatType; // general, project
  final String? projectId;
  final String message;
  final bool isRead;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    this.senderName,
    this.recipientId,
    this.chatType = "general",
    this.projectId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'],
      recipientId: json['recipientId'],
      chatType: json['chatType'] ?? 'general',
      projectId: json['projectId'],
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'recipientId': recipientId,
      'chatType': chatType,
      'projectId': projectId,
    };
  }
}
