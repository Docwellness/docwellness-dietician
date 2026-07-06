/// Message metadata for meal_log and diet_update message types
/// Matches backend: models/Message.js metadata field
class MessageMetadata {
  final String? mealLogId;
  final String? dietPlanId;
  final String? itemName;
  final int? calories;
  final String? imageUrl;
  final String? action; // 'added', 'updated', 'completed'

  MessageMetadata({
    this.mealLogId,
    this.dietPlanId,
    this.itemName,
    this.calories,
    this.imageUrl,
    this.action,
  });

  factory MessageMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MessageMetadata();
    return MessageMetadata(
      mealLogId: json['mealLogId']?.toString(),
      dietPlanId: json['dietPlanId']?.toString(),
      itemName: json['itemName'],
      calories: json['calories'],
      imageUrl: json['imageUrl'],
      action: json['action'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mealLogId != null) 'mealLogId': mealLogId,
      if (dietPlanId != null) 'dietPlanId': dietPlanId,
      if (itemName != null) 'itemName': itemName,
      if (calories != null) 'calories': calories,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (action != null) 'action': action,
    };
  }

  /// Get action display text
  String get actionDisplay {
    switch (action?.toLowerCase()) {
      case 'added':
        return 'added';
      case 'updated':
        return 'updated';
      case 'completed':
        return 'completed';
      default:
        return 'logged';
    }
  }
}

/// Message type enum matching backend
enum MessageType {
  text,
  image,
  file,
  mealLog,
  dietUpdate,
  system,
}

/// Message model matching backend: models/Message.js
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final MessageMetadata? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  // Computed properties
  final String? senderRole;
  final String? receiverRole;
  final bool isMe;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.metadata,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.senderRole,
    this.receiverRole,
    this.isMe = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] is Map
          ? json['conversationId']['_id'] ?? ''
          : json['conversationId'] ?? '',
      senderId: json['senderId'] is Map
          ? json['senderId']['_id'] ?? ''
          : json['senderId'] ?? '',
      receiverId: json['receiverId'] is Map
          ? json['receiverId']['_id'] ?? ''
          : json['receiverId'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      messageType: _parseMessageType(json['messageType']),
      metadata: json['metadata'] != null
          ? MessageMetadata.fromJson(json['metadata'])
          : null,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      senderRole: json['senderRole'],
      receiverRole: json['receiverRole'],
      isMe: json['isMe'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.name,
      'metadata': metadata?.toJson(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'senderRole': senderRole,
      'receiverRole': receiverRole,
      'isMe': isMe,
    };
  }

  static MessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'meal_log':
        return MessageType.mealLog;
      case 'diet_update':
        return MessageType.dietUpdate;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Check if this is a meal-related message
  bool get isMealMessage => messageType == MessageType.mealLog;

  /// Check if this is a diet plan update
  bool get isDietUpdate => messageType == MessageType.dietUpdate;

  /// Check if this is a system message
  bool get isSystemMessage => messageType == MessageType.system;

  /// Check if this message has an image
  bool get hasImage => messageType == MessageType.image || metadata?.imageUrl != null;

  /// Get display content for meal log messages
  String get displayContent {
    if (messageType == MessageType.mealLog && metadata != null) {
      final action = metadata!.actionDisplay;
      final item = metadata!.itemName ?? 'meal';
      return '$action $item';
    }
    return content;
  }
}
