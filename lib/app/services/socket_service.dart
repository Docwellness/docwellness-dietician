import 'dart:async';
import 'dart:developer';

import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Socket.IO Service for Dietician App
/// Handles real-time chat communication
class SocketService extends GetxService with WidgetsBindingObserver {
  static SocketService get to => Get.find<SocketService>();

  IO.Socket? _socket;

  // Base URL without /api path - socket connects to root
  String get baseUrl {
    final apiUrl = apiBaseUrl;
    // Remove /api/dietician from the URL for socket connection
    if (apiUrl.contains('/api')) {
      return apiUrl.split('/api')[0];
    }
    return apiUrl.replaceAll('/api/dietician', '');
  }

  final RxBool isConnected = false.obs;
  final RxString currentRoom = ''.obs;

  // Reconnect-sync (AI_EXECUTION_PLAN.md Phase 7, P7-03) - Socket.IO rooms
  // are server-side session state that's wiped on disconnect, so a dropped
  // and reconnected socket stops receiving conv:{id} broadcasts until it
  // rejoins; and any UI relying on presence/unread counts can go stale for
  // the same reason a network-level reconnect can (see
  // ConnectivityService, whose registerOnReconnected/unregister shape this
  // mirrors) - except a socket can drop and recover while the network
  // itself never goes offline (server restart, LB hiccup, idle timeout),
  // so this is a distinct signal from ConnectivityService, not a
  // duplicate of it.
  final _reconnectCallbacks = <VoidCallback>{};
  bool _hasConnectedBefore = false;

  void registerOnReconnect(VoidCallback onReconnect) {
    _reconnectCallbacks.add(onReconnect);
  }

  void unregisterOnReconnect(VoidCallback onReconnect) {
    _reconnectCallbacks.remove(onReconnect);
  }

  // Stream controllers for different events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _mealLogController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onRead => _readController.stream;
  Stream<Map<String, dynamic>> get onPresence => _presenceController.stream;
  Stream<Map<String, dynamic>> get onMealLogUpdate => _mealLogController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  /// Initialize the socket service
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_socket == null || !_socket!.connected) {
        log('🔄 App resumed — reconnecting socket');
        connect();
      }
    }
  }

  Future<SocketService> init() async {
    connect();
    return this;
  }

  /// Connect to the socket server
  void connect() {
    if (_socket != null && _socket!.connected) {
      log('Socket already connected');
      return;
    }

    log('🔌 Connecting to socket: $baseUrl');

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.maxFinite.toInt())
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setAuth({'token': token ?? ''})
          .build(),
    );

    _setupEventListeners();
    _socket!.connect();
  }

  /// Setup all socket event listeners
  void _setupEventListeners() {
    // Connection events
    _socket!.onConnect((_) {
      log('✅ Socket connected');
      isConnected.value = true;

      if (_hasConnectedBefore) {
        // A genuine reconnect (not the first connection this session) -
        // rejoin whatever room we were in server-side (the server has no
        // memory of it after a drop) before notifying listeners, so
        // syncActiveConversation()'s refetch and any subsequent live
        // messages both land correctly.
        log('🔄 Socket reconnected — syncing state');
        final room = currentRoom.value;
        if (room.isNotEmpty) {
          _socket?.emit('chat.join', {'conversation_id': room});
        }
        for (final cb in [..._reconnectCallbacks]) {
          cb();
        }
      }
      _hasConnectedBefore = true;
    });

    _socket!.on('ws.auth_ok', (data) {
      log('✅ Socket authenticated: $data');
    });

    _socket!.onDisconnect((_) {
      log('❌ Socket disconnected');
      isConnected.value = false;
    });

    _socket!.onConnectError((error) {
      log('❌ Socket connection error: $error');
      isConnected.value = false;
    });

    _socket!.onError((error) {
      log('❌ Socket error: $error');
    });

    // ==========================================
    // Message Events (v1 API format)
    // ==========================================

    // New message received
    _socket!.on('msg.new', (data) {
      log('📩 New message received: $data');
      final map = _toMap(data);
      // Extract message from nested structure if present
      if (map['message'] != null) {
        final message = Map<String, dynamic>.from(map['message'] as Map);
        message['conversationId'] =
            message['conversationId'] ?? map['conversation_id'];
        _messageController.add(message);
      } else {
        _messageController.add(map);
      }
    });

    // Message acknowledgement (sent confirmation)
    _socket!.on('msg.ack', (data) {
      log('✅ Message sent confirmed: $data');
      _messageController.add({..._toMap(data), 'type': 'ack'});
    });

    // Message status update (delivered/read)
    _socket!.on('msg.status', (data) {
      log('📬 Message status update: $data');
      _readController.add(_toMap(data));
    });

    // Message updated (meal log card updates)
    _socket!.on('msg.updated', (data) {
      log('🔄 Message updated: $data');
      _mealLogController.add(_toMap(data));
    });

    // ==========================================
    // Typing Events
    // ==========================================

    _socket!.on('typing', (data) {
      log('⌨️ Typing indicator: $data');
      _typingController.add(_toMap(data));
    });

    // ==========================================
    // Presence Events
    // ==========================================

    _socket!.on('presence.update', (data) {
      log('👤 Presence update: $data');
      _presenceController.add(_toMap(data));
    });

    // ==========================================
    // Conversation Events
    // ==========================================

    _socket!.on('chat.joined', (data) {
      log('✅ Joined chat room: $data');
      currentRoom.value = data['conversation_id'] ?? '';
    });

    _socket!.on('conv.read', (data) {
      log('👁️ Conversation read: $data');
      _readController.add(_toMap(data));
    });

    // ==========================================
    // Legacy Events (for backward compatibility)
    // ==========================================

    _socket!.on('new_message', (data) {
      log('📩 [Legacy] New message: $data');
      _messageController.add(_toMap(data));
    });

    // newMessage - camelCase variant from backend
    _socket!.on('newMessage', (data) {
      log('📩 [Legacy] newMessage (camelCase): $data');
      _messageController.add(_toMap(data));
    });

    _socket!.on('message_sent', (data) {
      log('✅ [Legacy] Message sent: $data');
      _messageController.add(_toMap(data));
    });

    _socket!.on('receive_message', (data) {
      log('📩 [Legacy] Receive message: $data');
      _messageController.add(_toMap(data));
    });

    _socket!.on('user_typing', (data) {
      log('⌨️ [Legacy] User typing: $data');
      _typingController.add({..._toMap(data), 'typing': true});
    });

    _socket!.on('user_stopped_typing', (data) {
      log('⌨️ [Legacy] User stopped typing: $data');
      _typingController.add({..._toMap(data), 'typing': false});
    });

    _socket!.on('messages_read', (data) {
      log('👁️ [Legacy] Messages read: $data');
      _readController.add(_toMap(data));
    });

    // ==========================================
    // Notification Events
    // ==========================================

    _socket!.on('notification.new', (data) {
      log('🔔 New notification: $data');
      _notificationController.add(_toMap(data));
    });
  }

  /// Helper to convert dynamic data to Map
  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  // ==========================================
  // Public Methods - Send Events
  // ==========================================

  /// Join a conversation room
  void joinConversation(String conversationId) {
    log('📥 Joining conversation: $conversationId');
    _socket?.emit('chat.join', {'conversation_id': conversationId});
    currentRoom.value = conversationId;
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    log('📤 Leaving conversation: $conversationId');
    _socket?.emit('chat.leave', {'conversation_id': conversationId});
    if (currentRoom.value == conversationId) {
      currentRoom.value = '';
    }
  }

  /// Send a message via socket
  void sendMessage({
    required String conversationId,
    required String receiverId,
    required String clientMessageId,
    required String content,
    String type = 'text',
    String? replyTo,
    Map<String, dynamic>? attachment,
    Map<String, dynamic>? extraData,
  }) {
    log('📤 Sending message to $receiverId');
    _socket?.emit('msg.send', {
      'conversation_id': conversationId,
      'receiver_id': receiverId,
      'client_message_id': clientMessageId,
      'type': type,
      'content': content,
      if (replyTo != null) 'reply_to': replyTo,
      if (attachment != null) 'attachment': attachment,
      if (extraData != null) ...extraData,
    });
  }

  /// Send typing indicator
  void startTyping({String? conversationId, String? receiverId}) {
    _socket?.emit('typing.start', {
      if (conversationId != null) 'conversation_id': conversationId,
      if (receiverId != null) 'receiver_id': receiverId,
    });
  }

  /// Stop typing indicator
  void stopTyping({String? conversationId, String? receiverId}) {
    _socket?.emit('typing.stop', {
      if (conversationId != null) 'conversation_id': conversationId,
      if (receiverId != null) 'receiver_id': receiverId,
    });
  }

  /// Mark conversation as read
  void markConversationRead(String conversationId, int lastReadSeq) {
    _socket?.emit('conv.read', {
      'conversation_id': conversationId,
      'last_read_seq': lastReadSeq,
    });
  }

  /// Mark message as delivered
  void markDelivered(String messageId) {
    _socket?.emit('msg.status', {
      'message_id': messageId,
      'status': 'delivered',
    });
  }

  /// Get presence status for users
  void getPresence(List<String> userIds) {
    _socket?.emit('presence.get', {'user_ids': userIds});
  }

  /// Sync messages after a sequence number
  void syncMessages(String conversationId, int afterSeq) {
    _socket?.emit('sync', {
      'conversation_id': conversationId,
      'after_seq': afterSeq,
    });
  }

  /// Disconnect socket
  void disconnect() {
    log('🔌 Disconnecting socket');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _messageController.close();
    _typingController.close();
    _readController.close();
    _presenceController.close();
    _mealLogController.close();
    _notificationController.close();
    super.onClose();
  }
}
