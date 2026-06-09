class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.senderFirstName,
    this.senderLastName,
  });

  final String id;
  final String sessionId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final String? senderFirstName;
  final String? senderLastName;

  String get senderName {
    if (senderFirstName != null && senderLastName != null) {
      return '$senderFirstName $senderLastName';
    }
    return 'Étudiant';
  }

  bool isMine(String userId) => senderId == userId;
}
