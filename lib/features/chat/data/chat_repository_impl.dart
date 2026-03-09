import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/socket_client.dart';
import '../domain/chat_repository.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/tenant_user.dart';
import 'chat_api.dart';
import 'chat_socket_api.dart';

final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient();
  ref.onDispose(client.close);
  return client;
});

final chatApiProvider = Provider<ChatApi>((ref) {
  final dio = ref.read(dioProvider);
  return ChatApi(dio);
});

final chatSocketApiProvider = Provider<ChatSocketApi>((ref) {
  final socketClient = ref.read(socketClientProvider);
  return ChatSocketApi(socketClient);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ref.read(chatApiProvider);
  final socketApi = ref.read(chatSocketApiProvider);
  return ChatRepositoryImpl(api, socketApi);
});

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._api, this._socketApi);

  final ChatApi _api;
  final ChatSocketApi _socketApi;

  @override
  Stream<ChatSocketEvent> get socketEvents => _socketApi.events;

  @override
  Future<void> connectSocket(String token) => _socketApi.connect(token);

  @override
  void disconnectSocket() => _socketApi.disconnect();

  @override
  Future<List<Conversation>> getConversations(String token) async {
    final payload = await _api.getConversations(token);
    return payload.map(Conversation.fromJson).toList();
  }

  @override
  Future<List<TenantUser>> getUsers(String token) async {
    final payload = await _api.getUsers(token);
    return payload.map(TenantUser.fromJson).toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String token,
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final payload = await _api.getMessages(
      token,
      conversationId,
      page: page,
      pageSize: pageSize,
    );
    return payload.map(ChatMessage.fromJson).toList();
  }

  @override
  Future<Conversation> createConversation(
    String token,
    List<String> participantIds,
  ) async {
    final payload = await _api.createConversation(token, participantIds);
    return Conversation.fromJson(payload);
  }

  @override
  Future<String> uploadFile(String token, File file) =>
      _api.uploadFile(token, file);

  @override
  Future<void> joinConversation(String conversationId) =>
      _socketApi.joinConversation(conversationId);

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required MessageType type,
    required String content,
  }) {
    return _socketApi.sendMessage(
      conversationId: conversationId,
      type: type,
      content: content,
    );
  }

  @override
  Future<MessageReaction> reactToMessage({
    required String messageId,
    required String reactionType,
  }) {
    return _socketApi.reactToMessage(
      messageId: messageId,
      reactionType: reactionType,
    );
  }

  @override
  Future<DeletedMessageEvent> deleteMessage(String messageId) =>
      _socketApi.deleteMessage(messageId);

  @override
  Future<DeliveredReceipt> markAsDelivered(String messageId) =>
      _socketApi.markAsDelivered(messageId);

  @override
  Future<ReadReceipt> markAsRead(String messageId) =>
      _socketApi.markAsRead(messageId);
}
