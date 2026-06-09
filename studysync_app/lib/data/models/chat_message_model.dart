import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.sessionId,
    required super.senderId,
    required super.content,
    required super.sentAt,
    super.senderFirstName,
    super.senderLastName,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    Map<String, dynamic>? senderMap;
    if (sender is Map) {
      senderMap = Map<String, dynamic>.from(sender);
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ??
          DateTime.now(),
      senderFirstName: senderMap?['first_name']?.toString(),
      senderLastName: senderMap?['last_name']?.toString(),
    );
  }
}
