enum MessageType { text, image, voice }

MessageType parseMessageType(String rawType) {
  switch (rawType.toUpperCase()) {
    case 'IMAGE':
      return MessageType.image;
    case 'VOICE':
      return MessageType.voice;
    case 'TEXT':
    default:
      return MessageType.text;
  }
}

extension MessageTypeX on MessageType {
  String get apiValue {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.voice:
        return 'VOICE';
    }
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.tenantId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.deletedAt,
    required this.createdAt,
    required this.reactions,
    required this.deliveredReceipts,
    required this.readReceipts,
  });

  final String id;
  final String conversationId;
  final String tenantId;
  final String senderId;
  final MessageType type;
  final String content;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final List<MessageReaction> reactions;
  final List<DeliveredReceipt> deliveredReceipts;
  final List<ReadReceipt> readReceipts;

  bool get isDeleted => deletedAt != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as List<dynamic>? ?? <dynamic>[];
    final rawDelivered =
        json['deliveredReceipts'] as List<dynamic>? ?? <dynamic>[];
    final rawReceipts = json['readReceipts'] as List<dynamic>? ?? <dynamic>[];

    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      tenantId: json['tenantId'] as String,
      senderId: json['senderId'] as String,
      type: parseMessageType(json['type'] as String),
      content: json['content'] as String,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reactions: rawReactions
          .map(
            (item) => MessageReaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      deliveredReceipts: rawDelivered
          .map(
            (item) => DeliveredReceipt.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      readReceipts: rawReceipts
          .map(
            (item) =>
                ReadReceipt.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  ChatMessage copyWith({
    String? content,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    List<MessageReaction>? reactions,
    List<DeliveredReceipt>? deliveredReceipts,
    List<ReadReceipt>? readReceipts,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      tenantId: tenantId,
      senderId: senderId,
      type: type,
      content: content ?? this.content,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      createdAt: createdAt,
      reactions: reactions ?? this.reactions,
      deliveredReceipts: deliveredReceipts ?? this.deliveredReceipts,
      readReceipts: readReceipts ?? this.readReceipts,
    );
  }
}

class DeliveredReceipt {
  const DeliveredReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.deliveredAt,
    this.conversationId,
  });

  final String id;
  final String messageId;
  final String userId;
  final DateTime deliveredAt;
  final String? conversationId;

  factory DeliveredReceipt.fromJson(Map<String, dynamic> json) {
    return DeliveredReceipt(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      deliveredAt: DateTime.parse(json['deliveredAt'] as String),
      conversationId: json['conversationId'] as String?,
    );
  }
}

class MessageReaction {
  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reactionType,
    this.conversationId,
  });

  final String id;
  final String messageId;
  final String userId;
  final String reactionType;
  final String? conversationId;

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      reactionType: json['reactionType'] as String,
      conversationId: json['conversationId'] as String?,
    );
  }
}

class ReadReceipt {
  const ReadReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.readAt,
    this.conversationId,
  });

  final String id;
  final String messageId;
  final String userId;
  final DateTime readAt;
  final String? conversationId;

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      id: json['id'] as String,
      messageId: json['messageId'] as String,
      userId: json['userId'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
      conversationId: json['conversationId'] as String?,
    );
  }
}

class DeletedMessageEvent {
  const DeletedMessageEvent({
    required this.messageId,
    required this.conversationId,
    required this.deletedAt,
  });

  final String messageId;
  final String conversationId;
  final DateTime deletedAt;

  factory DeletedMessageEvent.fromJson(Map<String, dynamic> json) {
    return DeletedMessageEvent(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      deletedAt: DateTime.parse(json['deletedAt'] as String),
    );
  }
}
