import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isPolling = false;
  bool _shouldPoll = true;
  int _lastMessageId = 0;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _shouldPoll = false;
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _shouldPoll = true;
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _shouldPoll = false;
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      _isAtBottom = (maxScroll - currentScroll) < 100;
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      if (roomService.currentRoomId == null) return;

      final messages = await apiService.getMessages(roomService.currentRoomId!);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          if (messages.isNotEmpty) {
            _lastMessageId = messages.last.id;
          }
        });

        _scrollToBottom();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _startPolling() async {
    if (_isPolling) return;
    _isPolling = true;

    final apiService = context.read<ApiService>();
    final roomService = context.read<RoomService>();

    while (_shouldPoll && mounted) {
      try {
        if (roomService.currentRoomId == null) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        final newMessages = await apiService.pollMessages(
          roomService.currentRoomId!,
          lastMessageId: _lastMessageId,
          timeout: 25,
        );

        if (!mounted || !_shouldPoll) break;

        if (newMessages.isNotEmpty) {
          setState(() {
            for (var msg in newMessages) {
              if (!_messages.any((m) => m.id == msg.id)) {
                _messages.add(msg);
              }
            }
            _lastMessageId = _messages.last.id;
          });

          if (_isAtBottom) {
            _scrollToBottom();
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
        if (mounted && _shouldPoll) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    _isPolling = false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      final newMessage =
          await apiService.sendMessage(roomService.currentRoomId!, content);

      if (mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.add(newMessage);
            _lastMessageId = newMessage.id;
          }
          _isSending = false;
        });

        _isAtBottom = true;
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
        _messageController.text = content;
      }
    }
  }

  Future<void> _refreshMessages() async {
    try {
      final apiService = context.read<ApiService>();
      final roomService = context.read<RoomService>();

      if (roomService.currentRoomId == null) return;

      final messages = await apiService.getMessages(roomService.currentRoomId!);

      if (mounted) {
        setState(() {
          _messages = messages;
          if (messages.isNotEmpty) {
            _lastMessageId = messages.last.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUser = context.watch<AuthService>().currentUser;

    return Column(
      children: [
        if (_isPolling)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Подключено',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshMessages,
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет сообщений',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Начните общение!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == currentUser?.id;

                      bool showDate = false;
                      if (index == 0) {
                        showDate = true;
                      } else {
                        final prevMessage = _messages[index - 1];
                        final prevDate = DateTime(
                          prevMessage.createdAt.year,
                          prevMessage.createdAt.month,
                          prevMessage.createdAt.day,
                        );
                        final currentDate = DateTime(
                          message.createdAt.year,
                          message.createdAt.month,
                          message.createdAt.day,
                        );
                        showDate = !prevDate.isAtSameMomentAs(currentDate);
                      }

                      return Column(
                        children: [
                          if (showDate) _buildDateDivider(message.createdAt),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  ),
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildDateDivider(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      dateText = 'Сегодня';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      dateText = 'Вчера';
    } else {
      dateText = DateFormat('d MMMM yyyy', 'ru').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: Theme.of(context).colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
              child: Divider(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.sender.fullName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isSending,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
