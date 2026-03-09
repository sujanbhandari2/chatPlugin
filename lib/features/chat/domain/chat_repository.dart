import 'dart:io';

import 'entities/chat_message.dart';
import 'entities/conversation.dart';
import 'entities/tenant_user.dart';

abstract class ChatRepository {
  Future<void> connectSocket(String token);
  void disconnectSocket();

  Stream<ChatSocketEvent> get socketEvents;

  Future<List<Conversation>> getConversations(String token);
  Future<List<TenantUser>> getUsers(String token);
  Future<List<ChatMessage>> getMessages(
    String token,
    String conversationId, {
    int page,
    int pageSize,
  });

  Future<Conversation> createConversation(
    String token,
    List<String> participantIds,
  );
  Future<String> uploadFile(String token, File file);

  Future<void> joinConversation(String conversationId);
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required MessageType type,
    required String content,
  });
  Future<MessageReaction> reactToMessage({
    required String messageId,
    required String reactionType,
  });
  Future<DeletedMessageEvent> deleteMessage(String messageId);
  Future<DeliveredReceipt> markAsDelivered(String messageId);
  Future<ReadReceipt> markAsRead(String messageId);
}

enum ChatSocketEventType {
  connected,
  disconnected,
  error,
  messageReceived,
  messageReacted,
  messageDeleted,
  messageDelivered,
  messageRead,
}

class ChatSocketEvent {
  const ChatSocketEvent({
    required this.type,
    this.message,
    this.reaction,
    this.deleted,
    this.delivered,
    this.receipt,
    this.error,
  });

  final ChatSocketEventType type;
  final ChatMessage? message;
  final MessageReaction? reaction;
  final DeletedMessageEvent? deleted;
  final DeliveredReceipt? delivered;
  final ReadReceipt? receipt;
  final String? error;
}
