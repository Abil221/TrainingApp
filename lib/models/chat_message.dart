class ChatMessage {
  final String id;
  final String friendshipId;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.friendshipId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      friendshipId: json['friendship_id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'friendship_id': friendshipId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}
