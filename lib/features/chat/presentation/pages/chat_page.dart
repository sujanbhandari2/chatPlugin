import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_messenger_ui/health_messenger_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/models/app_role.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/chat_controller.dart';
import '../state/chat_state.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _messagesScrollController = ScrollController();

  String _lastAutoScrollKey = '';

  @override
  void initState() {
    super.initState();

    ref.listenManual(authControllerProvider.select((value) => value.session), (
      _,
      next,
    ) {
      if (next == null && mounted) {
        context.go('/auth');
      }
    });

    ref.listenManual<AsyncValue<String>>(openedPushConversationIdsProvider, (
      _,
      next,
    ) {
      next.whenData((conversationId) {
        if (conversationId.isEmpty) {
          return;
        }

        ref
            .read(chatControllerProvider.notifier)
            .selectConversation(conversationId);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conversationId = ref
          .read(pushNotificationServiceProvider)
          .consumePendingOpenedConversationId();
      if (conversationId == null || conversationId.isEmpty) {
        return;
      }

      ref
          .read(chatControllerProvider.notifier)
          .selectConversation(conversationId);
    });
  }

  @override
  void dispose() {
    _messagesScrollController.dispose();
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);

    _scheduleAutoScroll(chatState);

    final currentUser = chatState.currentUser;
    if (currentUser == null || authState.session == null) {
      return const Scaffold(
        body: GradientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final conversations = chatState.conversations
        .map(
          (conversation) => _toUiConversation(
            conversation: conversation,
            myUserId: currentUser.id,
            unreadByConversation: chatState.unreadByConversation,
          ),
        )
        .toList(growable: false);

    final users = chatState.users
        .where((user) => user.id != currentUser.id)
        .map(
          (user) => MessengerUser(
            id: user.id,
            username: user.username,
            roleLabel: user.role.label,
            isOnline: user.isOnline,
          ),
        )
        .toList(growable: false);

    final senderLabels = {
      for (final user in chatState.users) user.id: _displayName(user.username),
    };

    final messages = chatState.messages
        .map(
          (message) => _toUiMessage(
            message: message,
            currentUserId: currentUser.id,
            senderLabel:
                senderLabels[message.senderId] ?? _shortId(message.senderId),
          ),
        )
        .toList(growable: false);

    final shell = MessengerChatShell(
      currentUserId: currentUser.id,
      currentUserName: currentUser.username,
      conversations: conversations,
      users: users,
      selectedConversationId: chatState.selectedConversationId,
      messages: messages,
      composerController: _textController,
      messagesScrollController: _messagesScrollController,
      isSending: chatState.isSending,
      isRecording: chatState.isRecording,
      onRefresh: chatController.refreshData,
      onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      onSelectConversation: chatController.selectConversation,
      onOpenDirectChat: (uiUser) async {
        final user = chatState.users
            .where((item) => item.id == uiUser.id)
            .firstOrNull;
        if (user == null) {
          return;
        }

        await chatController.openDirectChat(user);
      },
      onSend: () async {
        final text = _textController.text;
        await chatController.sendText(text);
        if (text.trim().isNotEmpty) {
          _textController.clear();
        }
      },
      onPickImage: () => _pickImage(chatController),
      onPickAudio: () => _pickVoiceFile(chatController),
      onToggleRecording: () =>
          _toggleRecording(chatState.isRecording, chatController),
      onReact: chatController.reactToMessage,
      onDelete: chatController.deleteMessage,
      onMarkSeen: chatController.markAsRead,
      canDeleteMessage: (message) =>
          currentUser.role == AppRole.admin ||
          message.senderId == currentUser.id,
    );

    final content = Column(
      children: [
        if (chatState.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ErrorBanner(message: chatState.error!, inline: true),
          ),
        Expanded(child: shell),
      ],
    );

    final isDesktop = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      backgroundColor: isDesktop ? null : Colors.white,
      body: isDesktop
          ? GradientBackground(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: content,
                ),
              ),
            )
          : SafeArea(child: content),
    );
  }

  MessengerConversation _toUiConversation({
    required Conversation conversation,
    required String myUserId,
    required Map<String, int> unreadByConversation,
  }) {
    final title = _getConversationTitle(conversation, myUserId);
    final otherParticipant = conversation.participants
        .where((item) => item.userId != myUserId)
        .firstOrNull;

    final avatarSource = conversation.isGlobal
        ? 'ALL'
        : (otherParticipant?.user.username ?? title);

    return MessengerConversation(
      id: conversation.id,
      title: title,
      subtitle: _getConversationSubtitle(conversation),
      avatarLabel: conversation.isGlobal ? 'ALL' : _initials(avatarSource),
      createdAt: conversation.createdAt,
      isGlobal: conversation.isGlobal,
      unreadCount: unreadByConversation[conversation.id] ?? 0,
    );
  }

  MessengerChatMessage _toUiMessage({
    required ChatMessage message,
    required String currentUserId,
    required String senderLabel,
  }) {
    final type = switch (message.type) {
      MessageType.text => MessengerMessageType.text,
      MessageType.image => MessengerMessageType.image,
      MessageType.voice => MessengerMessageType.voice,
    };

    final isMine = message.senderId == currentUserId;
    final hasSeen = message.readReceipts.any(
      (item) => item.userId != message.senderId,
    );
    final hasDelivered = message.deliveredReceipts.any(
      (item) => item.userId != message.senderId,
    );

    final deliveryStatus = !isMine || message.isDeleted
        ? MessengerDeliveryStatus.none
        : hasSeen
        ? MessengerDeliveryStatus.seen
        : hasDelivered
        ? MessengerDeliveryStatus.delivered
        : MessengerDeliveryStatus.sent;

    final content = switch (message.type) {
      MessageType.text => message.content,
      MessageType.image ||
      MessageType.voice => _toAbsoluteMediaUrl(message.content),
    };

    return MessengerChatMessage(
      id: message.id,
      senderId: message.senderId,
      senderLabel: senderLabel,
      type: type,
      content: content,
      createdAt: message.createdAt,
      isDeleted: message.isDeleted,
      deliveryStatus: deliveryStatus,
      reactions: message.reactions
          .map(
            (reaction) => MessengerMessageReaction(
              userId: reaction.userId,
              reactionType: reaction.reactionType,
            ),
          )
          .toList(growable: false),
    );
  }

  String _toAbsoluteMediaUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final origin = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$origin$value';
  }

  void _scheduleAutoScroll(ChatState state) {
    final selectedConversationId = state.selectedConversationId;
    if (selectedConversationId == null) {
      _lastAutoScrollKey = '';
      return;
    }

    final lastMessageId = state.messages.isNotEmpty
        ? state.messages.last.id
        : '';
    final nextKey =
        '$selectedConversationId:$lastMessageId:${state.messages.length}';
    if (nextKey == _lastAutoScrollKey) {
      return;
    }
    _lastAutoScrollKey = nextKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messagesScrollController.hasClients) {
        return;
      }

      _messagesScrollController.animateTo(
        _messagesScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImage(ChatController controller) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    await controller.sendImage(File(file.path));
  }

  Future<void> _pickVoiceFile(ChatController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['webm', 'm4a', 'aac', 'wav', 'mp3'],
    );

    final filePath = result?.files.single.path;
    if (filePath == null) {
      return;
    }

    await controller.sendVoice(File(filePath));
  }

  Future<void> _toggleRecording(
    bool isRecording,
    ChatController controller,
  ) async {
    if (!isRecording) {
      try {
        if (!await _audioRecorder.hasPermission()) {
          throw Exception('Microphone permission denied');
        }

        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        controller.setRecording(true);
      } catch (error) {
        _showSnack(error.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }

    try {
      final path = await _audioRecorder.stop();
      controller.setRecording(false);
      if (path == null) {
        return;
      }

      await controller.sendVoice(File(path));
    } catch (error) {
      controller.setRecording(false);
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _getConversationTitle(Conversation conversation, String myUserId) {
    if (conversation.isGlobal) {
      return 'System Broadcast (All Users)';
    }

    final others = conversation.participants
        .where((item) => item.userId != myUserId)
        .toList();
    if (others.isEmpty) {
      return 'Just You';
    }

    if (others.length == 1) {
      return _displayName(others.first.user.username);
    }

    return '${_displayName(others.first.user.username)} + ${others.length - 1}';
  }

  String _getConversationSubtitle(Conversation conversation) {
    if (conversation.isGlobal) {
      return '${conversation.participants.length} registered users';
    }

    final roles = conversation.participants
        .map((participant) => participant.user.role.label)
        .join(', ');
    return '${conversation.participants.length} people • $roles';
  }

  String _displayName(String username) {
    return username
        .split(RegExp(r'[_-]'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _initials(String username) {
    final chunks = _displayName(
      username,
    ).split(' ').where((part) => part.isNotEmpty).toList();
    if (chunks.isEmpty) {
      return 'U';
    }

    final first = chunks.first[0];
    final second = chunks.length > 1
        ? chunks[1][0]
        : (chunks.first.length > 1 ? chunks.first[1] : '');
    return '$first$second';
  }

  String _shortId(String id) {
    return id.substring(0, id.length > 8 ? 8 : id.length);
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
