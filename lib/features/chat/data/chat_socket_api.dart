import '../../../core/network/socket_client.dart';
import '../domain/chat_repository.dart';
import '../domain/entities/chat_message.dart';

class ChatSocketApi {
  ChatSocketApi(this._socketClient);

  final SocketClient _socketClient;

  Stream<ChatSocketEvent> get events async* {
    await for (final socketEvent in _socketClient.events) {
      switch (socketEvent.type) {
        case SocketEventType.connected:
          yield const ChatSocketEvent(type: ChatSocketEventType.connected);
          break;
        case SocketEventType.disconnected:
          yield const ChatSocketEvent(type: ChatSocketEventType.disconnected);
          break;
        case SocketEventType.error:
          final payload = socketEvent.payload;
          final message = payload is Map<String, dynamic>
              ? payload['message']?.toString() ?? 'Socket error'
              : 'Socket error';
          yield ChatSocketEvent(
            type: ChatSocketEventType.error,
            error: message,
          );
          break;
        case SocketEventType.messageReceived:
          final payload = Map<String, dynamic>.from(socketEvent.payload as Map);
          yield ChatSocketEvent(
            type: ChatSocketEventType.messageReceived,
            message: ChatMessage.fromJson(payload),
          );
          break;
        case SocketEventType.messageReacted:
          final payload = Map<String, dynamic>.from(socketEvent.payload as Map);
          yield ChatSocketEvent(
            type: ChatSocketEventType.messageReacted,
            reaction: MessageReaction.fromJson(payload),
          );
          break;
        case SocketEventType.messageDeleted:
          final payload = Map<String, dynamic>.from(socketEvent.payload as Map);
          yield ChatSocketEvent(
            type: ChatSocketEventType.messageDeleted,
            deleted: DeletedMessageEvent.fromJson(payload),
          );
          break;
        case SocketEventType.messageDelivered:
          final payload = Map<String, dynamic>.from(socketEvent.payload as Map);
          yield ChatSocketEvent(
            type: ChatSocketEventType.messageDelivered,
            delivered: DeliveredReceipt.fromJson(payload),
          );
          break;
        case SocketEventType.messageRead:
          final payload = Map<String, dynamic>.from(socketEvent.payload as Map);
          yield ChatSocketEvent(
            type: ChatSocketEventType.messageRead,
            receipt: ReadReceipt.fromJson(payload),
          );
          break;
      }
    }
  }

  Future<void> connect(String token) => _socketClient.connect(token);

  void disconnect() => _socketClient.disconnect();

  Future<void> joinConversation(String conversationId) {
    return _socketClient.emitWithAck<void>('join_conversation', {
      'conversationId': conversationId,
    }, (_) {});
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required MessageType type,
    required String content,
  }) {
    return _socketClient.emitWithAck<ChatMessage>(
      'send_message',
      {
        'conversationId': conversationId,
        'type': type.apiValue,
        'content': content,
      },
      (data) => ChatMessage.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<MessageReaction> reactToMessage({
    required String messageId,
    required String reactionType,
  }) {
    return _socketClient.emitWithAck<MessageReaction>(
      'react_to_message',
      {'messageId': messageId, 'reactionType': reactionType},
      (data) =>
          MessageReaction.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<DeletedMessageEvent> deleteMessage(String messageId) {
    return _socketClient.emitWithAck<DeletedMessageEvent>(
      'delete_message',
      {'messageId': messageId},
      (data) =>
          DeletedMessageEvent.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<DeliveredReceipt> markAsDelivered(String messageId) {
    return _socketClient.emitWithAck<DeliveredReceipt>(
      'mark_as_delivered',
      {'messageId': messageId},
      (data) =>
          DeliveredReceipt.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ReadReceipt> markAsRead(String messageId) {
    return _socketClient.emitWithAck<ReadReceipt>(
      'mark_as_read',
      {'messageId': messageId},
      (data) => ReadReceipt.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }
}
