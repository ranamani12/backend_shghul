import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ChatService {
  static WebSocketChannel? _channel;
  static final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _isConnected = false;
  static int? _currentUserId;
  static String? _socketId;

  // Stream to listen for incoming messages
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageController.stream;

  static bool get isConnected => _isConnected;

  // Get all conversations
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final token = await AuthService.getToken();

    try {
      final response = await ApiService.get(
        'mobile/messages',
        token: token,
      );

      // API service wraps array responses in {'data': list}
      if (response.containsKey('data') && response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      print('ChatService.getConversations error: $e');
      rethrow;
    }
  }

  // Get messages in a conversation thread
  static Future<List<Map<String, dynamic>>> getThread(int userId) async {
    final token = await AuthService.getToken();

    final response = await ApiService.get(
      'mobile/messages/$userId',
      token: token,
    );

    // API service wraps array responses in {'data': list}
    if (response.containsKey('data') && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    }

    return [];
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage(
      int receiverId, String content) async {
    final token = await AuthService.getToken();

    return ApiService.post(
      'mobile/messages/$receiverId',
      {'content': content},
      token: token,
    );
  }

  // Mark a message as read
  static Future<Map<String, dynamic>> markAsRead(int messageId) async {
    final token = await AuthService.getToken();

    return ApiService.patch(
      'mobile/messages/$messageId/read',
      {},
      token: token,
    );
  }

  // Mark all messages in a thread as read
  static Future<Map<String, dynamic>> markThreadAsRead(int userId) async {
    final token = await AuthService.getToken();

    return ApiService.post(
      'mobile/messages/$userId/mark-read',
      {},
      token: token,
    );
  }

  // Get unread messages count
  static Future<int> getUnreadCount() async {
    final token = await AuthService.getToken();

    final response = await ApiService.get(
      'mobile/messages/unread-count',
      token: token,
    );

    return response['unread_count'] as int? ?? 0;
  }

  // Connect to Laravel Reverb WebSocket server
  static Future<void> connect() async {
    if (_isConnected) return;

    try {
      final user = await AuthService.getUser();
      if (user == null) return;

      _currentUserId = user['id'] as int?;
      if (_currentUserId == null) return;

      // Build Reverb WebSocket URL using Pusher protocol
      final wsUrl = '${AppConstants.reverbScheme == 'https' ? 'wss' : 'ws'}://'
          '${AppConstants.reverbHost}:${AppConstants.reverbPort}'
          '/app/${AppConstants.reverbAppKey}'
          '?protocol=7&client=flutter&version=1.0.0&flash=false';

      print('ChatService: Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('ChatService: WebSocket error: $error');
          _isConnected = false;
          _socketId = null;
          // Try to reconnect after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isConnected) {
              connect();
            }
          });
        },
        onDone: () {
          print('ChatService: WebSocket connection closed');
          _isConnected = false;
          _socketId = null;
        },
      );
    } catch (e) {
      print('ChatService: Failed to connect to WebSocket: $e');
      _isConnected = false;
    }
  }

  static void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final event = data['event'] as String?;

      print('ChatService: Received event: $event');

      switch (event) {
        case 'pusher:connection_established':
          // Connection successful, get socket ID
          final connectionData = jsonDecode(data['data'] as String);
          _socketId = connectionData['socket_id'] as String?;
          _isConnected = true;
          print('ChatService: Connected with socket_id: $_socketId');

          // Subscribe to private channel
          _subscribeToPrivateChannel();
          break;

        case 'pusher_internal:subscription_succeeded':
          print('ChatService: Subscribed to channel successfully');
          break;

        case 'pusher:error':
          print('ChatService: Pusher error: ${data['data']}');
          break;

        case 'message.sent':
          // New message received
          final messageData = data['data'] is String
              ? jsonDecode(data['data'] as String) as Map<String, dynamic>
              : data['data'] as Map<String, dynamic>;
          print('ChatService: New message received: $messageData');
          _messageController.add(messageData);
          break;

        case 'message.read':
          // Message read receipt
          final readData = data['data'] is String
              ? jsonDecode(data['data'] as String) as Map<String, dynamic>
              : data['data'] as Map<String, dynamic>;
          print('ChatService: Message read receipt: $readData');
          _messageController.add({'type': 'read_receipt', ...readData});
          break;
      }
    } catch (e) {
      print('ChatService: Error parsing message: $e');
    }
  }

  static Future<void> _subscribeToPrivateChannel() async {
    if (_channel == null || _currentUserId == null || _socketId == null) return;

    try {
      // Get auth token for private channel
      final token = await AuthService.getToken();
      if (token == null) return;

      final channelName = 'private-chat.$_currentUserId';

      // Request channel authorization from server
      final authResponse = await ApiService.post(
        'broadcasting/auth',
        {
          'socket_id': _socketId,
          'channel_name': channelName,
        },
        token: token,
      );

      final auth = authResponse['auth'] as String?;
      if (auth == null) {
        print('ChatService: Failed to get channel auth');
        return;
      }

      // Subscribe to private channel
      _channel!.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {
          'auth': auth,
          'channel': channelName,
        },
      }));

      print('ChatService: Subscribing to channel: $channelName');
    } catch (e) {
      print('ChatService: Error subscribing to channel: $e');
    }
  }

  // Disconnect from WebSocket
  static void disconnect() {
    if (_channel != null) {
      // Unsubscribe from channel before disconnecting
      if (_currentUserId != null) {
        _channel!.sink.add(jsonEncode({
          'event': 'pusher:unsubscribe',
          'data': {
            'channel': 'private-chat.$_currentUserId',
          },
        }));
      }
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _socketId = null;
    _currentUserId = null;
  }

  // Dispose resources
  static void dispose() {
    disconnect();
    _messageController.close();
  }
}
