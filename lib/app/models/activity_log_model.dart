import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:docwellnesdoc/app/models/meal_log_model.dart';
import 'package:docwellnesdoc/app/models/message_model.dart';

/// Enum for different types of activity logs
enum ActivityLogType {
  message,        // Regular chat message
  image,          // Image message
  mealLog,        // Patient logged a meal (auto-message)
  mealSubmitted,  // Patient submitted a new meal
  mealEdited,     // Patient edited a meal
  customMeal,     // Patient added a custom meal
  dietUpdate,     // Diet plan update message
  system,         // System message
  waterIntake,    // Water intake log
  weight,         // Weight log
  exercise,       // Exercise log
  note,           // Notes from dietician
}

/// Unified Activity Log Model that combines chat messages and meal logs
/// This is used for the WhatsApp-style combined view
class ActivityLogModel {
  final String id;
  final ActivityLogType type;
  final String patientId;
  final String? senderId;
  final String? senderRole; // 'patient' or 'doctor'
  final DateTime timestamp;
  final bool isFromDoctor;

  // For chat messages
  final MessageModel? message;

  // For ChatModel based messages
  final ChatModel? chatMessage;

  // For meal logs
  final MealLogModel? mealLog;

  // For generic activity
  final String? title;
  final String? description;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ActivityLogModel({
    required this.id,
    required this.type,
    required this.patientId,
    this.senderId,
    this.senderRole,
    required this.timestamp,
    required this.isFromDoctor,
    this.message,
    this.chatMessage,
    this.mealLog,
    this.title,
    this.description,
    this.imageUrl,
    this.metadata,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    ActivityLogType type = _parseActivityType(json['type'] ?? json['messageType'] ?? 'message');

    return ActivityLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: type,
      patientId: json['patientId']?.toString() ?? '',
      senderId: json['senderId']?.toString(),
      senderRole: json['senderRole'],
      timestamp: DateTime.parse(json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      isFromDoctor: json['senderRole'] == 'doctor' || json['senderRole'] == 'dietician',
      message: json['message'] != null
          ? MessageModel.fromJson(json['message'])
          : null,
      chatMessage: json['chatMessage'] != null
          ? ChatModel.fromJson(json['chatMessage'])
          : null,
      mealLog: json['mealLog'] != null
          ? MealLogModel.fromJson(json['mealLog'])
          : null,
      title: json['title'],
      description: json['description'] ?? json['content'],
      imageUrl: json['imageUrl'],
      metadata: json['metadata'],
    );
  }

  /// Create from a MessageModel
  factory ActivityLogModel.fromMessage(MessageModel msg) {
    ActivityLogType type;
    switch (msg.messageType) {
      case MessageType.image:
        type = ActivityLogType.image;
        break;
      case MessageType.mealLog:
        type = ActivityLogType.mealLog;
        break;
      case MessageType.dietUpdate:
        type = ActivityLogType.dietUpdate;
        break;
      case MessageType.system:
        type = ActivityLogType.system;
        break;
      default:
        type = ActivityLogType.message;
    }

    return ActivityLogModel(
      id: msg.id,
      type: type,
      patientId: msg.receiverRole == 'patient' ? msg.receiverId : msg.senderId,
      senderId: msg.senderId,
      senderRole: msg.senderRole,
      timestamp: msg.createdAt,
      isFromDoctor: msg.senderRole == 'doctor' || msg.senderRole == 'dietician',
      message: msg,
      title: msg.metadata?.itemName,
      description: msg.content,
      imageUrl: msg.metadata?.imageUrl,
      metadata: msg.metadata?.toJson(),
    );
  }

  /// Create from a MealLogModel (for meal_log type messages)
  factory ActivityLogModel.fromMealLog(MealLogModel meal) {
    return ActivityLogModel(
      id: meal.id,
      type: ActivityLogType.mealLog,
      patientId: meal.patientId,
      senderRole: 'patient',
      timestamp: meal.updatedAt,
      isFromDoctor: false,
      mealLog: meal,
      title: meal.mealTypeDisplay,
      description: meal.itemsDisplay,
      imageUrl: meal.images.isNotEmpty ? meal.images.first : null,
    );
  }

  /// Create from a ChatModel (for chat messages in combined view)
  factory ActivityLogModel.fromChatMessage(ChatModel chat) {
    ActivityLogType type;
    switch (chat.messageType.toLowerCase()) {
      case 'image':
        type = ActivityLogType.image;
        break;
      case 'meal_log':
      case 'meallog':
        type = ActivityLogType.mealLog;
        break;
      case 'meal_submitted':
      case 'mealsubmitted':
        type = ActivityLogType.mealSubmitted;
        break;
      case 'meal_edited':
      case 'mealedited':
        type = ActivityLogType.mealEdited;
        break;
      case 'custom_meal':
      case 'custommeal':
        type = ActivityLogType.customMeal;
        break;
      case 'diet_update':
      case 'dietupdate':
        type = ActivityLogType.dietUpdate;
        break;
      case 'system':
        type = ActivityLogType.system;
        break;
      default:
        type = ActivityLogType.message;
    }

    return ActivityLogModel(
      id: chat.id,
      type: type,
      patientId: chat.receiverRole == 'patient' ? chat.receiverId : chat.senderId,
      senderId: chat.senderId,
      senderRole: chat.senderRole,
      timestamp: chat.createdAt,
      isFromDoctor: chat.senderRole == 'doctor' || chat.senderRole == 'dietician',
      chatMessage: chat,
      title: chat.metadata?.itemName,
      description: chat.message,
      imageUrl: chat.attachment,
      metadata: chat.metadata?.toJson(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'patientId': patientId,
      'senderId': senderId,
      'senderRole': senderRole,
      'timestamp': timestamp.toIso8601String(),
      'isFromDoctor': isFromDoctor,
      'message': message?.toJson(),
      'chatMessage': chatMessage?.toJson(),
      'mealLog': mealLog?.toJson(),
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  static ActivityLogType _parseActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
      case 'message':
        return ActivityLogType.message;
      case 'image':
        return ActivityLogType.image;
      case 'meal_log':
      case 'meallog':
        return ActivityLogType.mealLog;
      case 'meal_submitted':
      case 'mealsubmitted':
        return ActivityLogType.mealSubmitted;
      case 'meal_edited':
      case 'mealedited':
        return ActivityLogType.mealEdited;
      case 'custom_meal':
      case 'custommeal':
        return ActivityLogType.customMeal;
      case 'diet_update':
      case 'dietupdate':
        return ActivityLogType.dietUpdate;
      case 'system':
        return ActivityLogType.system;
      case 'water_intake':
      case 'waterintake':
        return ActivityLogType.waterIntake;
      case 'weight':
        return ActivityLogType.weight;
      case 'exercise':
        return ActivityLogType.exercise;
      case 'note':
        return ActivityLogType.note;
      default:
        return ActivityLogType.message;
    }
  }

  /// Get icon for activity type
  String get typeIcon {
    switch (type) {
      case ActivityLogType.message:
        return '💬';
      case ActivityLogType.image:
        return '📷';
      case ActivityLogType.mealLog:
        return mealLog?.mealTypeIcon ?? '🍽️';
      case ActivityLogType.mealSubmitted:
        return '✅';
      case ActivityLogType.mealEdited:
        return '✏️';
      case ActivityLogType.customMeal:
        return '🍴';
      case ActivityLogType.dietUpdate:
        return '📋';
      case ActivityLogType.system:
        return 'ℹ️';
      case ActivityLogType.waterIntake:
        return '💧';
      case ActivityLogType.weight:
        return '⚖️';
      case ActivityLogType.exercise:
        return '🏃';
      case ActivityLogType.note:
        return '📝';
    }
  }

  /// Get display title for activity
  String get displayTitle {
    switch (type) {
      case ActivityLogType.message:
        return message?.content ?? description ?? '';
      case ActivityLogType.image:
        return message?.content.isNotEmpty == true ? message!.content : '📷 Photo';
      case ActivityLogType.mealLog:
        if (mealLog != null) {
          final action = message?.metadata?.actionDisplay ?? 'logged';
          return '$action ${mealLog!.mealTypeDisplay}';
        }
        return title ?? 'Meal logged';
      case ActivityLogType.mealSubmitted:
        return title ?? 'Meal submitted';
      case ActivityLogType.mealEdited:
        return title ?? 'Meal edited';
      case ActivityLogType.customMeal:
        return title ?? 'Custom meal added';
      case ActivityLogType.dietUpdate:
        return 'Diet plan updated';
      case ActivityLogType.system:
        return message?.content ?? 'System message';
      case ActivityLogType.waterIntake:
        return 'Water intake logged';
      case ActivityLogType.weight:
        return 'Weight logged';
      case ActivityLogType.exercise:
        return 'Exercise logged';
      case ActivityLogType.note:
        return 'Note added';
    }
  }

  /// Check if this is a meal-related activity
  bool get isMealRelated =>
      type == ActivityLogType.mealLog ||
      type == ActivityLogType.mealSubmitted ||
      type == ActivityLogType.mealEdited ||
      type == ActivityLogType.customMeal;

  /// Check if this is a chat message
  bool get isChatMessage => type == ActivityLogType.message || type == ActivityLogType.image;
}
