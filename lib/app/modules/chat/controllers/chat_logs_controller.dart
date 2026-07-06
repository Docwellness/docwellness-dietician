import 'package:docwellnesdoc/app/models/activity_log_model.dart';
import 'package:docwellnesdoc/app/models/all_chats_model.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:docwellnesdoc/app/models/meal_log_model.dart';
import 'package:docwellnesdoc/app/modules/chat/services/chat_logs_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

/// Controller for combined Chat + Activity Logs (WhatsApp-style)
class ChatLogsController extends GetxController {
  final ChatLogsService service = ChatLogsService();

  // Loading states
  RxBool isLoadingConversations = false.obs;
  RxBool isLoadingMessages = false.obs;
  RxBool isLoadingActivityLogs = false.obs;
  RxBool isSending = false.obs;

  // Data lists
  RxList<ChatUser> conversations = <ChatUser>[].obs;
  RxList<ChatModel> messages = <ChatModel>[].obs;
  RxList<MealLogModel> mealLogs = <MealLogModel>[].obs;
  RxList<ActivityLogModel> activityLogs = <ActivityLogModel>[].obs;

  // Combined chat + logs (sorted by timestamp)
  RxList<ActivityLogModel> combinedLogs = <ActivityLogModel>[].obs;

  // Current conversation info
  RxString currentConversationId = ''.obs;
  RxString currentPatientId = ''.obs;
  RxString currentPatientName = ''.obs;

  // Reply message state
  final Rx<ChatModel?> replyMessage = Rx<ChatModel?>(null);
  ReceiverModel? receiverModel;

  // Selected date filter
  Rx<DateTime> selectedDate = DateTime.now().obs;

  // Getters
  ChatModel? get replyingTo => replyMessage.value;

  String get formattedSelectedDate {
    final now = DateTime.now();
    final date = selectedDate.value;

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAllConversations();
  }

  // ==================== CONVERSATIONS ====================

  /// Fetch all patient conversations
  Future<void> fetchAllConversations() async {
    isLoadingConversations.value = true;
    try {
      final response = await service.getAllConversations();

      if (response != null && response['data'] != null) {
        conversations.value = (response['data'] as List)
            .map((e) => ChatUser.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("fetchAllConversations error: $e");
    } finally {
      isLoadingConversations.value = false;
    }
  }

  // ==================== MESSAGES ====================

  /// Fetch messages for a conversation
  Future<void> fetchMessages(String conversationId) async {
    currentConversationId.value = conversationId;
    isLoadingMessages.value = true;

    try {
      final response = await service.getConversationMessages(conversationId);

      if (response != null && response['data'] != null) {
        final List data = response['data'];
        messages.value = data.map((e) => ChatModel.fromJson(e)).toList();

        // Extract receiver info
        final dieticianJson = data.firstWhereOrNull(
          (e) => e['senderRole'] == 'dietician',
        );
        if (dieticianJson != null) {
          receiverModel = ReceiverModel.fromJson(dieticianJson);
        }

        // Mark as read
        await service.markAsRead(conversationId);

        // Update combined logs
        _updateCombinedLogs();
      }
    } catch (e) {
      debugPrint("fetchMessages error: $e");
    } finally {
      isLoadingMessages.value = false;
    }
  }

  /// Send a text message
  Future<bool> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return false;

    isSending.value = true;
    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add optimistic local message
    final localMessage = ChatModel(
      id: localId,
      senderId: "currentUserId",
      receiverId: receiverModel?.receiverId ?? "",
      message: message,
      messageType: "text",
      attachment: null,
      isRead: false,
      conversationId: currentConversationId.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      senderRole: "dietician",
      receiverRole: "patient",
      isMe: true,
    );

    messages.add(localMessage);
    _updateCombinedLogs();

    try {
      final response = await service.sendMessage(
        conversationId: currentConversationId.value,
        receiverId: receiverModel?.receiverId ?? "",
        message: message,
        replyTo: replyingTo?.id,
      );

      if (response != null && response['data'] != null) {
        // Replace local message with server message
        final index = messages.indexWhere((e) => e.id == localId);
        if (index != -1) {
          messages[index] = ChatModel.fromJson(response['data']);
        }
        clearReply();
        _updateCombinedLogs();
        return true;
      }
    } catch (e) {
      debugPrint("sendTextMessage error: $e");
    } finally {
      isSending.value = false;
    }
    return false;
  }

  /// Send an image message
  Future<bool> sendImageMessage(File imageFile, {String? caption}) async {
    isSending.value = true;
    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add optimistic local message
    final localMessage = ChatModel(
      id: localId,
      senderId: "currentUserId",
      receiverId: receiverModel?.receiverId ?? "",
      message: caption ?? "",
      messageType: "image",
      attachment: imageFile.path,
      isRead: false,
      conversationId: currentConversationId.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      senderRole: "dietician",
      receiverRole: "patient",
      isMe: true,
    );

    messages.add(localMessage);
    _updateCombinedLogs();

    try {
      final response = await service.sendImageMessage(
        receiverId: receiverModel?.receiverId ?? "",
        imageFile: imageFile,
        message: caption,
        replyTo: replyingTo?.id,
      );

      if (response != null && response['data'] != null) {
        final index = messages.indexWhere((e) => e.id == localId);
        if (index != -1) {
          messages[index] = ChatModel.fromJson(response['data']);
        }
        clearReply();
        _updateCombinedLogs();
        return true;
      }
    } catch (e) {
      debugPrint("sendImageMessage error: $e");
    } finally {
      isSending.value = false;
    }
    return false;
  }

  // ==================== MEAL LOGS ====================

  /// Fetch patient meal logs for selected date
  Future<void> fetchMealLogs(String patientId, {DateTime? date}) async {
    currentPatientId.value = patientId;
    final targetDate = date ?? selectedDate.value;
    final dateString = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    try {
      final response = await service.getPatientMealLogs(
        patientId: patientId,
        date: dateString,
      );

      if (response != null && response['data'] != null) {
        mealLogs.value = (response['data'] as List)
            .map((e) => MealLogModel.fromJson(e))
            .toList();

        _updateCombinedLogs();
      }
    } catch (e) {
      debugPrint("fetchMealLogs error: $e");
    }
  }

  /// Approve a meal log
  Future<bool> approveMealLog(String mealLogId, {String? feedback}) async {
    try {
      final response = await service.updateMealLogStatus(
        patientId: currentPatientId.value,
        mealLogId: mealLogId,
        status: 'approved',
        feedback: feedback,
      );

      if (response != null) {
        // Update local meal log status
        final index = mealLogs.indexWhere((e) => e.id == mealLogId);
        if (index != -1) {
          // Refresh meal logs
          await fetchMealLogs(currentPatientId.value);
        }
        return true;
      }
    } catch (e) {
      debugPrint("approveMealLog error: $e");
    }
    return false;
  }

  /// Reject a meal log
  Future<bool> rejectMealLog(String mealLogId, {String? feedback}) async {
    try {
      final response = await service.updateMealLogStatus(
        patientId: currentPatientId.value,
        mealLogId: mealLogId,
        status: 'rejected',
        feedback: feedback,
      );

      if (response != null) {
        await fetchMealLogs(currentPatientId.value);
        return true;
      }
    } catch (e) {
      debugPrint("rejectMealLog error: $e");
    }
    return false;
  }

  // ==================== ACTIVITY LOGS ====================

  /// Fetch combined activity logs
  Future<void> fetchActivityLogs(String patientId) async {
    currentPatientId.value = patientId;
    isLoadingActivityLogs.value = true;

    try {
      final response = await service.getPatientActivityLogs(patientId: patientId);

      if (response != null && response['data'] != null) {
        activityLogs.value = (response['data'] as List)
            .map((e) => ActivityLogModel.fromJson(e))
            .toList();

        _updateCombinedLogs();
      }
    } catch (e) {
      debugPrint("fetchActivityLogs error: $e");
    } finally {
      isLoadingActivityLogs.value = false;
    }
  }

  /// Add a note to patient's log
  Future<bool> addNote(String note, {String? category}) async {
    try {
      final response = await service.addNoteToPatient(
        patientId: currentPatientId.value,
        note: note,
        category: category,
      );

      if (response != null) {
        await fetchActivityLogs(currentPatientId.value);
        return true;
      }
    } catch (e) {
      debugPrint("addNote error: $e");
    }
    return false;
  }

  // ==================== COMBINED LOGS ====================

  /// Load all data for a patient's chat + logs view
  Future<void> loadPatientChatAndLogs({
    required String conversationId,
    required String patientId,
    String? patientName,
  }) async {
    currentConversationId.value = conversationId;
    currentPatientId.value = patientId;
    if (patientName != null) currentPatientName.value = patientName;

    // Load in parallel
    await Future.wait([
      fetchMessages(conversationId),
      fetchMealLogs(patientId),
    ]);
  }

  /// Update combined logs by merging messages and meal logs
  void _updateCombinedLogs() {
    final List<ActivityLogModel> combined = [];

    // Add messages as activity logs
    for (final msg in messages) {
      combined.add(ActivityLogModel.fromChatMessage(msg));
    }

    // Add meal logs as activity logs
    for (final meal in mealLogs) {
      combined.add(ActivityLogModel.fromMealLog(meal));
    }

    // Sort by timestamp (newest last for chat view)
    combined.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    combinedLogs.value = combined;
  }

  /// Get logs grouped by date
  Map<String, List<ActivityLogModel>> get logsGroupedByDate {
    final Map<String, List<ActivityLogModel>> grouped = {};

    for (final log in combinedLogs) {
      final dateKey = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(log);
    }

    return grouped;
  }

  /// Filter logs by type
  List<ActivityLogModel> getLogsByType(ActivityLogType type) {
    return combinedLogs.where((log) => log.type == type).toList();
  }

  /// Get only meal-related logs
  List<ActivityLogModel> get mealRelatedLogs {
    return combinedLogs.where((log) =>
      log.type == ActivityLogType.mealLog ||
      log.type == ActivityLogType.mealSubmitted ||
      log.type == ActivityLogType.mealEdited ||
      log.type == ActivityLogType.customMeal
    ).toList();
  }

  // ==================== DATE NAVIGATION ====================

  /// Go to previous date
  void previousDate() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
    if (currentPatientId.value.isNotEmpty) {
      fetchMealLogs(currentPatientId.value);
    }
  }

  /// Go to next date
  void nextDate() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (selectedDate.value.isBefore(tomorrow)) {
      selectedDate.value = selectedDate.value.add(const Duration(days: 1));
      if (currentPatientId.value.isNotEmpty) {
        fetchMealLogs(currentPatientId.value);
      }
    }
  }

  /// Select a specific date
  void selectDate(DateTime date) {
    selectedDate.value = date;
    if (currentPatientId.value.isNotEmpty) {
      fetchMealLogs(currentPatientId.value);
    }
  }

  // ==================== REPLY MANAGEMENT ====================

  void setReply(ChatModel message) {
    replyMessage.value = message;
  }

  void clearReply() {
    replyMessage.value = null;
  }

  // ==================== CLEANUP ====================

  void clearCurrentChat() {
    messages.clear();
    mealLogs.clear();
    combinedLogs.clear();
    currentConversationId.value = '';
    currentPatientId.value = '';
    currentPatientName.value = '';
    replyMessage.value = null;
    receiverModel = null;
  }

  @override
  void onClose() {
    clearCurrentChat();
    super.onClose();
  }
}
