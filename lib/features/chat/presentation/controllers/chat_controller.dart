import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/push/push_notification_service.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/chat_repository_impl.dart';
import '../../domain/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/tenant_user.dart';
import '../state/chat_state.dart';

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    final repository = ref.read(chatRepositoryProvider);
    final storage = ref.read(sessionStorageProvider);
    final pushNotifications = ref.read(pushNotificationServiceProvider);

    final controller = ChatController(repository, storage, pushNotifications);

    ref.listen<AuthSession?>(
      authControllerProvider.select((value) => value.session),
      (_, next) {
        controller.onSessionChanged(next);
      },
      fireImmediately: true,
    );

    ref.onDispose(controller.dispose);

    return controller;
  },
);

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository, this._storage, this._pushNotifications)
    : super(ChatState.initial());

  final ChatRepository _repository;
  final SessionStorage _storage;
  final PushNotificationService _pushNotifications;

  StreamSubscription<ChatSocketEvent>? _socketSub;
  Timer? _presenceTimer;

  String? _token;
  String? _userId;

  Future<void> onSessionChanged(AuthSession? session) async {
    if (session == null) {
      final previousToken = _token;
      if (previousToken != null) {
        await _pushNotifications.unbindSession(previousToken);
      }

      _token = null;
      _userId = null;
      _presenceTimer?.cancel();
      _socketSub?.cancel();
      _repository.disconnectSocket();
      state = ChatState.initial();
      return;
    }

    if (_token == session.token) {
      state = state.copyWith(currentUser: session.user);
      return;
    }

    if (_token != null) {
      await _pushNotifications.unbindSession(_token!);
    }

    _token = session.token;
    _userId = session.user.id;

    state = ChatState.initial().copyWith(
      currentUser: session.user,
      isBootstrapping: true,
    );

    try {
      await _pushNotifications.bindSession(session.token);
      await _repository.connectSocket(session.token);
      await _socketSub?.cancel();
      _socketSub = _repository.socketEvents.listen(_handleSocketEvent);
      await bootstrap();
      _startPresenceRefresh();
    } catch (error) {
      state = state.copyWith(
        isBootstrapping: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> bootstrap() async {
    final token = _token;
    if (token == null) {
      return;
    }

    state = state.copyWith(isBootstrapping: true, clearError: true);

    try {
      final conversations = await _repository.getConversations(token);
      final users = await _repository.getUsers(token);
      final persisted = await _storage.loadSelectedConversationId();

      final globalConversation = conversations
          .where((item) => item.isGlobal)
          .firstOrNull;

      final canUsePersisted =
          persisted != null &&
          conversations.any((item) => item.id == persisted);
      final selectedId = canUsePersisted
          ? persisted
          : (globalConversation?.id ??
                (conversations.isNotEmpty ? conversations.first.id : null));

      List<ChatMessage> messages = const [];
      if (selectedId != null) {
        messages = await _repository.getMessages(token, selectedId);
      }

      final nextUnread = Map<String, int>.from(state.unreadByConversation);
      if (selectedId != null) {
        nextUnread.remove(selectedId);
      }

      state = state.copyWith(
        isBootstrapping: false,
        conversations: conversations,
        users: users,
        selectedConversationId: selectedId,
        messages: messages,
        unreadByConversation: nextUnread,
        clearError: true,
      );

      if (selectedId != null) {
        await _storage.saveSelectedConversationId(selectedId);
        _syncReceiptState(messages);
      }

      await _joinAllConversations(conversations);
    } catch (error) {
      state = state.copyWith(
        isBootstrapping: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refreshUsers() async {
    final token = _token;
    if (token == null) {
      return;
    }

    try {
      final users = await _repository.getUsers(token);
      state = state.copyWith(users: users);
    } catch (_) {
      // Presence refresh should be best-effort.
    }
  }

  Future<void> refreshData() async {
    final token = _token;
    if (token == null) {
      return;
    }

    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final conversations = await _repository.getConversations(token);
      final users = await _repository.getUsers(token);

      final selectedId = state.selectedConversationId;
      final hasSelection =
          selectedId != null &&
          conversations.any((item) => item.id == selectedId);
      final nextSelectedId = hasSelection
          ? selectedId
          : (conversations.isNotEmpty ? conversations.first.id : null);

      List<ChatMessage> messages = state.messages;
      if (nextSelectedId != null && nextSelectedId != selectedId) {
        messages = await _repository.getMessages(token, nextSelectedId);
        await _storage.saveSelectedConversationId(nextSelectedId);
      }

      state = state.copyWith(
        isRefreshing: false,
        conversations: conversations,
        users: users,
        selectedConversationId: nextSelectedId,
        messages: messages,
        clearError: true,
      );

      await _joinAllConversations(conversations);
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> selectConversation(String conversationId) async {
    final token = _token;
    if (token == null) {
      return;
    }

    state = state.copyWith(
      selectedConversationId: conversationId,
      clearError: true,
    );

    final unread = Map<String, int>.from(state.unreadByConversation);
    unread.remove(conversationId);
    state = state.copyWith(unreadByConversation: unread);

    try {
      final messages = await _repository.getMessages(token, conversationId);
      state = state.copyWith(messages: messages);
      _syncReceiptState(messages);
      await _storage.saveSelectedConversationId(conversationId);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> openDirectChat(TenantUser targetUser) async {
    final token = _token;
    final userId = _userId;

    if (token == null || userId == null) {
      return;
    }

    final existing = _findDirectConversation(targetUser.id);
    if (existing != null) {
      await selectConversation(existing.id);
      return;
    }

    try {
      final created = await _repository.createConversation(token, [
        targetUser.id,
      ]);
      final conversations = await _repository.getConversations(token);
      state = state.copyWith(conversations: conversations);
      await _joinAllConversations(conversations);
      await selectConversation(created.id);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> sendText(String text) async {
    final conversationId = state.selectedConversationId;
    if (conversationId == null) {
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _sendMessage(
      conversationId: conversationId,
      type: MessageType.text,
      content: trimmed,
    );
  }

  Future<void> sendImage(File file) async {
    final token = _token;
    final conversationId = state.selectedConversationId;
    if (token == null || conversationId == null) {
      return;
    }

    try {
      final url = await _repository.uploadFile(token, file);
      await _sendMessage(
        conversationId: conversationId,
        type: MessageType.image,
        content: url,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> sendVoice(File file) async {
    final token = _token;
    final conversationId = state.selectedConversationId;
    if (token == null || conversationId == null) {
      return;
    }

    try {
      final url = await _repository.uploadFile(token, file);
      await _sendMessage(
        conversationId: conversationId,
        type: MessageType.voice,
        content: url,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> reactToMessage(String messageId, String reactionType) async {
    try {
      await _repository.reactToMessage(
        messageId: messageId,
        reactionType: reactionType,
      );
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _repository.deleteMessage(messageId);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _repository.markAsRead(messageId);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markAsDelivered(String messageId) async {
    try {
      await _repository.markAsDelivered(messageId);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setRecording(bool isRecording) {
    state = state.copyWith(isRecording: isRecording);
  }

  Future<void> _sendMessage({
    required String conversationId,
    required MessageType type,
    required String content,
  }) async {
    state = state.copyWith(isSending: true, clearError: true);

    try {
      final message = await _repository.sendMessage(
        conversationId: conversationId,
        type: type,
        content: content,
      );
      _upsertMessage(message);
      state = state.copyWith(isSending: false);
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _joinAllConversations(List<Conversation> conversations) async {
    for (final conversation in conversations) {
      try {
        await _repository.joinConversation(conversation.id);
      } catch (_) {
        // Keep trying other rooms even if one room fails.
      }
    }
  }

  Conversation? _findDirectConversation(String targetUserId) {
    final selfUserId = _userId;
    if (selfUserId == null) {
      return null;
    }

    for (final conversation in state.conversations) {
      if (conversation.isGlobal) {
        continue;
      }

      final participantIds = conversation.participants
          .map((item) => item.userId)
          .toList();
      if (participantIds.length == 2 &&
          participantIds.contains(selfUserId) &&
          participantIds.contains(targetUserId)) {
        return conversation;
      }
    }

    return null;
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    switch (event.type) {
      case ChatSocketEventType.connected:
        unawaited(_joinAllConversations(state.conversations));
        break;
      case ChatSocketEventType.messageReceived:
        final message = event.message;
        if (message == null) {
          break;
        }

        if (message.conversationId == state.selectedConversationId) {
          _upsertMessage(message);
          _syncIncomingMessageDeliveryAndRead(message);
        } else {
          if (message.senderId == _userId) {
            break;
          }

          _syncIncomingMessageDeliveryOnly(message);

          final unread = Map<String, int>.from(state.unreadByConversation);
          unread[message.conversationId] =
              (unread[message.conversationId] ?? 0) + 1;
          state = state.copyWith(unreadByConversation: unread);
        }
        break;
      case ChatSocketEventType.messageReacted:
        final reaction = event.reaction;
        if (reaction == null ||
            reaction.conversationId != state.selectedConversationId) {
          break;
        }

        final nextMessages = state.messages.map((message) {
          if (message.id != reaction.messageId) {
            return message;
          }

          final filtered = message.reactions
              .where((item) => item.userId != reaction.userId)
              .toList();
          return message.copyWith(reactions: [...filtered, reaction]);
        }).toList();

        state = state.copyWith(messages: nextMessages);
        break;
      case ChatSocketEventType.messageDeleted:
        final deleted = event.deleted;
        if (deleted == null ||
            deleted.conversationId != state.selectedConversationId) {
          break;
        }

        final nextMessages = state.messages.map((message) {
          if (message.id != deleted.messageId) {
            return message;
          }

          return message.copyWith(
            content: '[deleted]',
            deletedAt: deleted.deletedAt,
          );
        }).toList();

        state = state.copyWith(messages: nextMessages);
        break;
      case ChatSocketEventType.messageDelivered:
        final delivered = event.delivered;
        if (delivered == null) {
          break;
        }

        final nextMessages = state.messages.map((message) {
          if (message.id != delivered.messageId) {
            return message;
          }

          final filtered = message.deliveredReceipts
              .where((item) => item.userId != delivered.userId)
              .toList();
          return message.copyWith(deliveredReceipts: [...filtered, delivered]);
        }).toList();

        state = state.copyWith(messages: nextMessages);
        break;
      case ChatSocketEventType.messageRead:
        final receipt = event.receipt;
        if (receipt == null) {
          break;
        }

        final nextMessages = state.messages.map((message) {
          if (message.id != receipt.messageId) {
            return message;
          }

          final filtered = message.readReceipts
              .where((item) => item.userId != receipt.userId)
              .toList();
          return message.copyWith(readReceipts: [...filtered, receipt]);
        }).toList();

        state = state.copyWith(messages: nextMessages);
        break;
      case ChatSocketEventType.error:
        state = state.copyWith(
          error: event.error ?? 'Realtime connection failed',
        );
        break;
      case ChatSocketEventType.disconnected:
        break;
    }
  }

  void _upsertMessage(ChatMessage incoming) {
    final nextMessages = [...state.messages];
    final index = nextMessages.indexWhere(
      (message) => message.id == incoming.id,
    );

    if (index == -1) {
      nextMessages.add(incoming);
    } else {
      nextMessages[index] = incoming;
    }

    nextMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = state.copyWith(messages: nextMessages);
  }

  void _syncReceiptState(List<ChatMessage> messages) {
    for (final message in messages) {
      _syncIncomingMessageDeliveryAndRead(message);
    }
  }

  void _syncIncomingMessageDeliveryAndRead(ChatMessage message) {
    final selfUserId = _userId;
    if (selfUserId == null ||
        message.senderId == selfUserId ||
        message.isDeleted) {
      return;
    }

    if (!message.deliveredReceipts.any((item) => item.userId == selfUserId)) {
      unawaited(_markAsDeliveredBestEffort(message.id));
    }

    if (!message.readReceipts.any((item) => item.userId == selfUserId)) {
      unawaited(_markAsReadBestEffort(message.id));
    }
  }

  void _syncIncomingMessageDeliveryOnly(ChatMessage message) {
    final selfUserId = _userId;
    if (selfUserId == null ||
        message.senderId == selfUserId ||
        message.isDeleted) {
      return;
    }

    if (!message.deliveredReceipts.any((item) => item.userId == selfUserId)) {
      unawaited(_markAsDeliveredBestEffort(message.id));
    }
  }

  Future<void> _markAsDeliveredBestEffort(String messageId) async {
    try {
      await _repository.markAsDelivered(messageId);
    } catch (_) {
      // Delivery sync should not interrupt chat UX.
    }
  }

  Future<void> _markAsReadBestEffort(String messageId) async {
    try {
      await _repository.markAsRead(messageId);
    } catch (_) {
      // Read sync should not interrupt chat UX.
    }
  }

  void _startPresenceRefresh() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => refreshUsers(),
    );
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _socketSub?.cancel();
    _repository.disconnectSocket();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    if (isEmpty) {
      return null;
    }

    return first;
  }
}
