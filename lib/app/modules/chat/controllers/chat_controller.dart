import 'dart:async';
import 'dart:io';

import 'package:docwellnesdoc/app/models/all_chats_model.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:docwellnesdoc/app/modules/chat/services/service.dart';
import 'package:docwellnesdoc/app/services/socket_service.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  ReceiverModel? receiverModel;
  final ChatService service = ChatService();
  late SocketService _socketService;

  RxBool showAllChatLoading = false.obs;
  RxBool showChatLoading = false.obs;

  RxList<ChatUser> allChatsList = <ChatUser>[].obs;
  RxList<ChatModel> chatList = <ChatModel>[].obs;
  final Rx<ChatModel?> replyMessage = Rx<ChatModel?>(null);

  // Current conversation
  String? currentConversationId;
  String? currentReceiverId;

  // Typing indicator
  final RxBool isOtherUserTyping = false.obs;
  Timer? _typingTimer;

  // Stream subscriptions
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _readSubscription;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initSocketService();
    getAllPatientChat();
  }

  void _initSocketService() {
    try {
      _socketService = Get.find<SocketService>();
    } catch (e) {
      debugPrint('Socket service not found: $e');
      return;
    }

    // Ensure socket is connected when entering chat
    if (!_socketService.isConnected.value) {
      _socketService.connect();
    }

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new messages
    _messageSubscription = _socketService.onMessage.listen((data) {
      debugPrint('📩 Received message in controller: $data');
      _handleIncomingMessage(data);
    });

    // Listen for typing indicators
    _typingSubscription = _socketService.onTyping.listen((data) {
      final typingUserId = data['user_id']?.toString();
      final isTyping = data['typing'] ?? true;

      if (typingUserId != null && typingUserId != userId) {
        isOtherUserTyping.value = isTyping;

        // Auto-clear typing after 3 seconds
        if (isTyping) {
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3), () {
            isOtherUserTyping.value = false;
          });
        }
      }
    });

    // Listen for read receipts — when the other user reads our messages
    _readSubscription = _socketService.onRead.listen((data) {
      debugPrint('👁️ Read receipt: $data');
      final readConversationId =
          data['conversation_id'] ?? data['conversationId'];
      if (readConversationId == currentConversationId) {
        // Mark all our sent messages as read
        for (int i = 0; i < chatList.length; i++) {
          if (chatList[i].isMe && !chatList[i].isRead) {
            chatList[i] = ChatModel(
              id: chatList[i].id,
              senderId: chatList[i].senderId,
              receiverId: chatList[i].receiverId,
              message: chatList[i].message,
              messageType: chatList[i].messageType,
              attachment: chatList[i].attachment,
              description: chatList[i].description,
              metadata: chatList[i].metadata,
              isRead: true,
              conversationId: chatList[i].conversationId,
              createdAt: chatList[i].createdAt,
              updatedAt: chatList[i].updatedAt,
              senderRole: chatList[i].senderRole,
              receiverRole: chatList[i].receiverRole,
              isMe: chatList[i].isMe,
              serverSeq: chatList[i].serverSeq,
              replyTo: chatList[i].replyTo,
            );
          }
        }
        chatList.refresh();
      }
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      // Check if message is for current conversation
      final messageConversationId =
          data['conversation_id'] ?? data['conversationId'];
      debugPrint(
        '📌 Message conversationId: $messageConversationId, current: $currentConversationId',
      );

      if (messageConversationId == currentConversationId) {
        // Handle acknowledgement (sent confirmation)
        if (data['type'] == 'ack') {
          final messageId = data['message_id'] ?? data['id'];
          final serverSeq = data['server_seq'];
          // Update local message with server data
          debugPrint('✅ Message acknowledged: $messageId, seq: $serverSeq');
          return;
        }

        // Create ChatModel from socket data
        final message = ChatModel.fromSocketData(data);
        debugPrint(
          '✅ Parsed message: id=${message.id}, type=${message.messageType}, text=${message.message}',
        );

        // Check if message already exists
        final existingIndex = chatList.indexWhere((m) => m.id == message.id);
        debugPrint('📍 Existing index: $existingIndex');
        if (existingIndex == -1) {
          // Insert at beginning so newest appears at bottom with reverse: true
          chatList.insert(0, message);
          debugPrint(
            '✅ Message ADDED to chatList. New count: ${chatList.length}',
          );

          // Auto-mark incoming (not our own) messages as read since we're viewing the chat
          if (!message.isMe && currentConversationId != null) {
            readMessage(conversationId: currentConversationId!);
          }
        } else {
          debugPrint('⚠️ Message already exists at index $existingIndex');
        }
      } else {
        debugPrint('⚠️ Message is for different conversation, skipping');
      }

      // Also refresh conversation list to update last message
      _refreshConversationList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error handling incoming message: $e');
      debugPrint('📚 Stack trace: $stackTrace');
    }
  }

  void _refreshConversationList() {
    // Debounced refresh — cancel previous timer so rapid messages don't pile up
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 500), () {
      _silentRefreshConversations();
    });
  }

  Future<void> getAllPatientChat() async {
    showAllChatLoading.value = true;
    try {
      final response = await service.getAllPatientsChat();

      if (response != null) {
        allChatsList.value = (response['data'] as List)
            .map((e) => ChatUser.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("--------------------->$e");
    }
    showAllChatLoading.value = false;
  }

  /// Silent refresh — updates the list without showing the loading spinner
  Future<void> _silentRefreshConversations() async {
    try {
      final response = await service.getAllPatientsChat();
      if (response != null) {
        allChatsList.value = (response['data'] as List)
            .map((e) => ChatUser.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Silent refresh error: $e");
    }
  }

  Future<void> getPatientChat(String id) async {
    try {
      showChatLoading.value = true;
      currentConversationId = id;

      // Join the conversation room for real-time updates
      _socketService.joinConversation(id);

      final response = await service.getPatientChat(id);

      if (response != null) {
        // Mark messages as read
        await readMessage(conversationId: id);

        // Silently refresh conversation list to update unread count
        _silentRefreshConversations();

        final List data = response['data'];
        final fetchedChats = data.map((e) => ChatModel.fromJson(e)).toList();

        // Ensure messages are sorted newest first
        fetchedChats.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        chatList.value = fetchedChats;

        // Get receiver info
        final Map<String, dynamic>? patientJson = data.firstWhereOrNull(
          (e) => e['senderRole'] == 'patient',
        );

        if (patientJson != null) {
          receiverModel = ReceiverModel.fromPatientJson(patientJson);
          currentReceiverId = receiverModel?.receiverId;
        }
      }
    } catch (e) {
      debugPrint("--------------------->$e");
    } finally {
      showChatLoading.value = false;
    }
  }

  void leaveChat() {
    if (currentConversationId != null) {
      _socketService.leaveConversation(currentConversationId!);
      currentConversationId = null;
      currentReceiverId = null;
    }
  }

  /// Send message via socket (real-time) with REST fallback
  Future<dynamic> sendMessage({
    required String receiverId,
    required String message,
    required String conversationId,
  }) async {
    final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final currentReplyId = replyingTo?.id;

    // Add local message immediately for instant feedback
    final localMessage = ChatModel(
      id: clientMessageId,
      senderId: userId ?? '',
      receiverId: receiverId,
      message: message,
      messageType: 'text',
      isRead: false,
      conversationId: conversationId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      senderRole: 'dietician',
      receiverRole: 'patient',
      isMe: true,
      replyTo: replyingTo,
    );
    // Insert at beginning so newest appears at bottom with reverse: true
    chatList.insert(0, localMessage);

    // Capture the reply before clearing it
    final chatReplyId = currentReplyId;
    clearReply();

    // ALWAYS use REST API to ensure message is saved in database
    // The backend will broadcast the new message via socket to the other user
    final response = await sendChatApi(
      receiverId: receiverId,
      message: message,
      conversationId: conversationId,
      replyTo: chatReplyId,
    );

    if (response != null && response['data'] != null) {
      replaceMessage(clientMessageId, ChatModel.fromJson(response['data']));
      return {'success': true, 'data': localMessage};
    }

    return null;
  }

  Future<dynamic> sendChatApi({
    required String receiverId,
    required String message,
    required String conversationId,
    String? replyTo,
  }) async {
    try {
      final response = await service.sendChat({
        "conversationId": conversationId,
        "receiverId": receiverId,
        "message": message,
        if (replyTo != null) "replyTo": replyTo,
      });

      if (response != null && response['success'] == true) {
        return response;
      }
    } catch (e) {
      debugPrint("Send chat error: $e");
    }
    return null;
  }

  /// Send typing indicator
  void sendTypingIndicator() {
    if (currentConversationId != null && currentReceiverId != null) {
      _socketService.startTyping(
        conversationId: currentConversationId,
        receiverId: currentReceiverId,
      );
    }
  }

  /// Stop typing indicator
  void sendStopTyping() {
    if (currentConversationId != null && currentReceiverId != null) {
      _socketService.stopTyping(
        conversationId: currentConversationId,
        receiverId: currentReceiverId,
      );
    }
  }

  void addLocalMessage(ChatModel message) {
    // Insert at beginning so newest appears at bottom with reverse: true
    chatList.insert(0, message);
  }

  void replaceMessage(String localId, ChatModel serverMessage) {
    final index = chatList.indexWhere((e) => e.id == localId);
    if (index != -1) {
      chatList[index] = serverMessage;
    }
  }

  Future<dynamic> readMessage({required String conversationId}) async {
    try {
      // Also mark via socket
      if (chatList.isNotEmpty) {
        final lastSeq = chatList.last.serverSeq ?? 0;
        _socketService.markConversationRead(conversationId, lastSeq);
      }

      final response = await service.readMessage(conversationId);

      if (response != null) {
        debugPrint('-------------------${response['success']}');
      }
    } catch (e) {
      debugPrint("--------------- $e");
    }
    return null;
  }

  // ---------------- REPLY MESSAGE ----------------

  ChatModel? get replyingTo => replyMessage.value;

  void setReply(ChatModel message) {
    replyMessage.value = message;
  }

  void clearReply() {
    replyMessage.value = null;
  }

  bool shouldShowDateSeparator(int index) {
    if (index == chatList.length - 1) return true;

    final currentDateRaw = chatList[index].createdAt ?? DateTime.now();
    final previousDateRaw = chatList[index + 1].createdAt ?? DateTime.now();

    final currentDate = DateTime(
      currentDateRaw.year,
      currentDateRaw.month,
      currentDateRaw.day,
    );
    final previousDate = DateTime(
      previousDateRaw.year,
      previousDateRaw.month,
      previousDateRaw.day,
    );

    return currentDate != previousDate;
  }

  String getDateSeparatorText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // ---------------- SEND IMAGE ----------------
  Future<dynamic> sendImageMessage({
    required String receiverId,
    File? imageFile,
    String? message,
    String? replyTo,
  }) async {
    try {
      final response = await service.sendImageInChatOrReply(
        receiverId: receiverId,
        imageFile: imageFile,
        message: message,
        replyTo: replyTo,
      );

      if (response != null && response['success'] == true) {
        return response;
      }
    } catch (e) {
      debugPrint("sendImageMessage error: $e");
    }
    return null;
  }

  // ---------------- SEND RECOMMENDATION ----------------
  Future<void> sendRecommendation({
    required String receiverId,
    required String conversationId,
    required String recommendationText,
    required String category,
  }) async {
    final clientMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    if (_socketService.isConnected.value) {
      _socketService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        clientMessageId: clientMessageId,
        content: recommendationText,
        type: 'doctor_recommendation',
        replyTo: replyingTo?.id,
        extraData: {
          'recommendation_data': {
            'recommendationText': recommendationText,
            'category': category,
          },
        },
      );
    }

    // Add local message for instant feedback
    final localMessage = ChatModel(
      id: clientMessageId,
      senderId: userId ?? '',
      receiverId: receiverId,
      message: recommendationText,
      messageType: 'doctor_recommendation',
      metadata: ChatMetadata(
        recommendationText: recommendationText,
        recommendationCategory: category,
      ),
      isRead: false,
      conversationId: conversationId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      senderRole: 'dietician',
      receiverRole: 'patient',
      isMe: true,
      replyTo: replyingTo,
    );
    chatList.insert(0, localMessage);

    // Capture the reply before clearing it
    final chatReplyId = replyingTo?.id;
    clearReply();

    // ALWAYS use REST API to ensure message is saved in database
    final response = await service.sendChat({
      "conversationId": conversationId,
      "receiverId": receiverId,
      "message": recommendationText,
      "messageType": "doctor_recommendation",
      "metadata": {
        "recommendationText": recommendationText,
        "recommendationCategory": category,
      },
      if (chatReplyId != null) "replyTo": chatReplyId,
    });

    if (response != null && response['data'] != null) {
      replaceMessage(clientMessageId, ChatModel.fromJson(response['data']));
    }
  }

  @override
  void onClose() {
    // Leave conversation room
    if (currentConversationId != null) {
      _socketService.leaveConversation(currentConversationId!);
    }

    // Cancel subscriptions
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _readSubscription?.cancel();
    _typingTimer?.cancel();
    _refreshTimer?.cancel();

    super.onClose();
  }
}
