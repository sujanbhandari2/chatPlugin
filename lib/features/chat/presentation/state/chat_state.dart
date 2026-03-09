import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/tenant_user.dart';

class ChatState {
  const ChatState({
    required this.isBootstrapping,
    required this.isRefreshing,
    required this.isSending,
    required this.isRecording,
    required this.conversations,
    required this.users,
    required this.messages,
    required this.unreadByConversation,
    this.selectedConversationId,
    this.error,
    this.currentUser,
  });

  factory ChatState.initial() {
    return const ChatState(
      isBootstrapping: false,
      isRefreshing: false,
      isSending: false,
      isRecording: false,
      conversations: [],
      users: [],
      messages: [],
      unreadByConversation: {},
    );
  }

  final bool isBootstrapping;
  final bool isRefreshing;
  final bool isSending;
  final bool isRecording;
  final List<Conversation> conversations;
  final List<TenantUser> users;
  final List<ChatMessage> messages;
  final Map<String, int> unreadByConversation;
  final String? selectedConversationId;
  final String? error;
  final AuthUser? currentUser;

  Conversation? get selectedConversation {
    if (selectedConversationId == null) {
      return null;
    }

    for (final conversation in conversations) {
      if (conversation.id == selectedConversationId) {
        return conversation;
      }
    }

    return null;
  }

  ChatState copyWith({
    bool? isBootstrapping,
    bool? isRefreshing,
    bool? isSending,
    bool? isRecording,
    List<Conversation>? conversations,
    List<TenantUser>? users,
    List<ChatMessage>? messages,
    Map<String, int>? unreadByConversation,
    String? selectedConversationId,
    String? error,
    AuthUser? currentUser,
    bool clearError = false,
    bool clearSelection = false,
    bool clearCurrentUser = false,
  }) {
    return ChatState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSending: isSending ?? this.isSending,
      isRecording: isRecording ?? this.isRecording,
      conversations: conversations ?? this.conversations,
      users: users ?? this.users,
      messages: messages ?? this.messages,
      unreadByConversation: unreadByConversation ?? this.unreadByConversation,
      selectedConversationId: clearSelection
          ? null
          : (selectedConversationId ?? this.selectedConversationId),
      error: clearError ? null : (error ?? this.error),
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
    );
  }
}
