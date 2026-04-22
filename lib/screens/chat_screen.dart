import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/friend_profile.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';

class ChatScreen extends StatefulWidget {
  final FriendProfile friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingDebounceTimer;
  DateTime? _lastTypingHeartbeatAt;
  bool _isSending = false;
  bool _hasTypingState = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    if (widget.friend.friendshipId != null &&
        widget.friend.friendshipId!.isNotEmpty) {
      _workoutService.subscribeToChat(widget.friend.friendshipId!);
    }
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    unawaited(_stopTyping());
    _messageController.dispose();
    _scrollController.dispose();
    _workoutService.unsubscribeChat();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.friend.friendshipId == null ||
        widget.friend.friendshipId!.isEmpty) {
      return;
    }
    await _workoutService.loadChatMessages(widget.friend.friendshipId!);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.friend.friendshipId == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _stopTyping();
      await _workoutService.sendChatMessage(
        widget.friend.friendshipId!,
        widget.friend.id,
        text,
      );
      _messageController.clear();
      await _loadMessages();
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _handleMessageChanged(String value) {
    final friendshipId = widget.friend.friendshipId;
    if (friendshipId == null || friendshipId.isEmpty) {
      return;
    }

    final hasText = value.trim().isNotEmpty;
    _typingDebounceTimer?.cancel();

    if (!hasText) {
      unawaited(_stopTyping());
      return;
    }

    if (!_hasTypingState) {
      _hasTypingState = true;
      _lastTypingHeartbeatAt = DateTime.now();
      unawaited(_workoutService.setTypingState(friendshipId, true));
    } else {
      final now = DateTime.now();
      final lastHeartbeatAt = _lastTypingHeartbeatAt;
      if (lastHeartbeatAt == null ||
          now.difference(lastHeartbeatAt) >= const Duration(seconds: 1)) {
        _lastTypingHeartbeatAt = now;
        unawaited(_workoutService.setTypingState(friendshipId, true));
      }
    }

    _typingDebounceTimer = Timer(
      const Duration(seconds: 2),
      () {
        unawaited(_stopTyping());
      },
    );
  }

  Future<void> _stopTyping() async {
    final friendshipId = widget.friend.friendshipId;
    if (!_hasTypingState || friendshipId == null || friendshipId.isEmpty) {
      return;
    }

    _typingDebounceTimer?.cancel();
    _hasTypingState = false;
    _lastTypingHeartbeatAt = null;
    await _workoutService.setTypingState(friendshipId, false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatMessageTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Сегодня';
    }
    if (difference == 1) {
      return 'Вчера';
    }

    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }

  bool _shouldShowDateChip(List<ChatMessage> messages, int index) {
    if (index == 0) {
      return true;
    }

    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  String _friendInitials() {
    final parts = widget.friend.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'T';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final messagesNotifier = _workoutService.getChatMessagesNotifier(
      widget.friend.friendshipId ?? '',
    );
    final friendTypingNotifier = _workoutService.getFriendTypingNotifier(
      widget.friend.friendshipId ?? '',
    );
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF111827),
              child: Text(
                _friendInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: friendTypingNotifier,
                builder: (context, isFriendTyping, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.friend.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isFriendTyping
                            ? 'печатает...'
                            : widget.friend.isOnline
                                ? 'Сейчас в сети'
                                : _buildLastSeenLabel(widget.friend.lastSeen),
                        style: TextStyle(
                          fontSize: 12,
                          color: isFriendTyping
                              ? const Color(0xFF2A9D8F)
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: AppScreenBackground(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: messagesNotifier,
                builder: (context, messages, child) {
                  _scrollToBottom();
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Начни переписку — сообщение появится здесь.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == currentUserId;
                      final showReadState = isMine &&
                          index == messages.length - 1 &&
                          message.isRead;
                      return Column(
                        children: [
                          if (_shouldShowDateChip(messages, index)) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _formatDateLabel(message.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? const Color(0xFFFF6B35)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatMessageTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMine
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  if (showReadState) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Прочитано',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMine
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _handleMessageChanged,
                      decoration: InputDecoration(
                        hintText: 'Написать сообщение',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      child: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildLastSeenLabel(DateTime? lastSeen) {
    if (lastSeen == null) {
      return 'Личный диалог';
    }

    final difference = DateTime.now().difference(lastSeen);
    if (difference.inMinutes < 1) {
      return 'Был(а) только что';
    }
    if (difference.inMinutes < 60) {
      return 'Был(а) ${difference.inMinutes} мин назад';
    }
    if (difference.inHours < 24) {
      return 'Был(а) ${difference.inHours} ч назад';
    }
    return 'Был(а) ${lastSeen.day.toString().padLeft(2, '0')}.${lastSeen.month.toString().padLeft(2, '0')}';
  }
}
