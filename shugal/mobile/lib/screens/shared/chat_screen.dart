import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String? userImage;
  final String? userRole;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userImage,
    this.userRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // Get current user ID
    final user = await AuthService.getUser();
    _currentUserId = user?['id'] as int?;

    // Load messages
    await _loadMessages();

    // Start polling for new messages (simple real-time fallback)
    _startPolling();

    // Try to connect to WebSocket for real-time updates
    _connectWebSocket();
  }

  void _startPolling() {
    // Poll every 10 seconds as fallback when WebSocket is not connected
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !ChatService.isConnected) {
        _loadMessages(showLoading: false);
      }
    });
  }

  void _connectWebSocket() {
    // Listen for incoming messages from WebSocket
    _messageSubscription = ChatService.messageStream.listen((message) {
      // Handle read receipts
      if (message['type'] == 'read_receipt') {
        // Update read status for messages
        final messageId = message['message_id'] as int?;
        if (messageId != null && mounted) {
          setState(() {
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i]['id'] == messageId) {
                _messages[i]['read_at'] = message['read_at'];
                break;
              }
            }
          });
        }
        return;
      }

      // Check if message is for this conversation
      final senderId = message['sender_id'] as int?;
      if (senderId == widget.userId && mounted) {
        setState(() {
          // Add message if not already in list
          final exists = _messages.any((m) => m['id'] == message['id']);
          if (!exists) {
            _messages.add(message);
          }
        });
        // No scroll needed - reverse:true shows latest messages at bottom

        // Mark as read since we're viewing the chat
        ChatService.markThreadAsRead(widget.userId);
      }
    });

    // Connect to WebSocket
    ChatService.connect();
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final messages = await ChatService.getThread(widget.userId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        // No scroll needed - reverse:true shows latest messages at bottom
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients && mounted) {
          if (animated) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Create a temporary message with sending status (optimistic UI)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = {
      'id': tempId,
      'sender_id': _currentUserId,
      'receiver_id': widget.userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'is_sending': true, // Flag to show sending status
    };

    // Add message immediately and clear input
    setState(() {
      _messages.add(tempMessage);
      _messageController.clear();
    });

    try {
      final message = await ChatService.sendMessage(widget.userId, content);

      if (mounted) {
        setState(() {
          // Replace temp message with actual message from server
          final index = _messages.indexWhere((m) => m['id'] == tempId);
          if (index != -1) {
            _messages[index] = message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Remove the temp message on failure
          _messages.removeWhere((m) => m['id'] == tempId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatMessageTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  String _formatDateHeader(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return 'Today';
      } else if (messageDate == yesterday) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    final currentDate = DateTime.tryParse(currentMessage['created_at'] ?? '');
    final previousDate = DateTime.tryParse(previousMessage['created_at'] ?? '');

    if (currentDate == null || previousDate == null) return false;

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  bool _shouldShowDateHeaderReversed(List<Map<String, dynamic>> reversedMessages, int index) {
    // In reversed list, we show date header at the END of a day's messages (which appears first when scrolling up)
    // So we compare with the next item (index + 1) instead of previous
    if (index == reversedMessages.length - 1) return true;

    final currentMessage = reversedMessages[index];
    final nextMessage = reversedMessages[index + 1];

    final currentDate = DateTime.tryParse(currentMessage['created_at'] ?? '');
    final nextDate = DateTime.tryParse(nextMessage['created_at'] ?? '');

    if (currentDate == null || nextDate == null) return false;

    return currentDate.day != nextDate.day ||
        currentDate.month != nextDate.month ||
        currentDate.year != nextDate.year;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messageSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.darkPrimaryColor],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.bodySurfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(child: _buildMessageList()),
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.white.withOpacity(0.2),
            backgroundImage: widget.userImage != null
                ? NetworkImage(ApiService.normalizeUrl(widget.userImage))
                : null,
            child: widget.userImage == null
                ? Icon(
                    widget.userRole == 'company' ? Icons.business : Icons.person,
                    color: AppTheme.white,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.userRole == 'company' ? 'Company' : 'Candidate',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Use reversed list so newest messages appear at bottom naturally
    final reversedMessages = _messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        final message = reversedMessages[index];
        final isMe = message['sender_id'] == _currentUserId;
        // For reversed list, check date header with next item (which is previous in original order)
        final showDateHeader = _shouldShowDateHeaderReversed(reversedMessages, index);

        return Column(
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDateHeader(message['created_at']),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? AppTheme.white : AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message['created_at']),
                  style: TextStyle(
                    color: isMe
                        ? AppTheme.white.withOpacity(0.7)
                        : AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message['is_sending'] == true
                        ? Icons.access_time // Clock while sending
                        : message['read_at'] != null
                            ? Icons.done_all // Double check when read
                            : Icons.done, // Single check when sent
                    size: 14,
                    color: message['read_at'] != null
                        ? AppTheme.lightBlue
                        : AppTheme.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bodySurfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: AppTheme.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
