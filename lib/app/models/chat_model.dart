import 'package:docwellnesdoc/main.dart';

class ChatModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final String? attachment;
  final String? description;
  final ChatMetadata? metadata;
  final bool isRead;
  final String conversationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String senderRole;
  final String receiverRole;
  final bool isMe;
  final int? serverSeq;
  final ChatModel? replyTo;
  // Set on optimistically-created local messages (see ChatController.
  // sendMessage/sendRecommendation) and echoed back by the backend on both
  // the REST response and the msg.new socket payload - lets dedup match a
  // socket-delivered echo of a just-sent message against its still-pending
  // optimistic entry even before the REST response has replaced `id` with
  // the real server id (see ChatController._handleIncomingMessage - the
  // dietician is joined to the conversation's socket room via
  // joinConversation, so their own just-sent message can be echoed back
  // before that REST response arrives).
  final String? clientMessageId;

  ChatModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    this.attachment,
    this.description,
    this.metadata,
    required this.isRead,
    required this.conversationId,
    required this.createdAt,
    required this.updatedAt,
    required this.senderRole,
    required this.receiverRole,
    required this.isMe,
    this.serverSeq,
    this.replyTo,
    this.clientMessageId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Parse metadata from various backend formats
    ChatMetadata? parsedMetadata;
    if (json['metadata'] != null) {
      parsedMetadata = ChatMetadata.fromJson(json['metadata']);
    } else if (json['customFoodData'] != null) {
      parsedMetadata = ChatMetadata.fromCustomFood(json['customFoodData']);
    } else if (json['mealLogData'] != null) {
      parsedMetadata = ChatMetadata.fromMealLog(json['mealLogData']);
    } else if (json['confessionData'] != null) {
      parsedMetadata = ChatMetadata.fromConfession(json['confessionData']);
    } else if (json['allergyReportData'] != null) {
      parsedMetadata = ChatMetadata.fromAllergyReport(
        json['allergyReportData'],
      );
    } else if (json['recommendationData'] != null) {
      parsedMetadata = ChatMetadata.fromRecommendation(
        json['recommendationData'],
      );
    }

    final msgType = json['messageType'] ?? json['type'] ?? 'text';
    final msgContent = json['message'] ?? json['content'] ?? '';
    var parsedAttachment = _parseAttachment(json['attachment']);
    // If it's an image message with no attachment, the URL is in the message field
    if (parsedAttachment == null &&
        msgType == 'image' &&
        msgContent is String &&
        msgContent.startsWith('http')) {
      parsedAttachment = msgContent;
    }

    return ChatModel(
      id: json['id'] ?? json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: msgContent,
      messageType: msgType,
      attachment: parsedAttachment,
      description: json['description'],
      metadata: parsedMetadata,
      isRead: json['isRead'] ?? json['status'] == 'read' ?? false,
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      senderRole: json['senderRole'] ?? '',
      receiverRole: json['receiverRole'] ?? '',
      isMe: json['isMe'] ?? (json['senderId'] == userId),
      serverSeq: json['serverSeq'] ?? json['server_seq'],
      replyTo: json['replyTo'] != null
          ? ChatModel.fromJson(json['replyTo'])
          : null,
      clientMessageId: json['clientMessageId'] ?? json['client_message_id'],
    );
  }

  /// Factory to create ChatModel from socket data
  factory ChatModel.fromSocketData(Map<String, dynamic> data) {
    // Handle both v1 API format and legacy format
    // Check if 'message' is a Map (nested format) or String (flat format)
    final dynamic messageField = data['message'];
    final Map<String, dynamic> message = (messageField is Map<String, dynamic>)
        ? messageField
        : data;

    // Get the actual text content
    final String textContent = (messageField is String)
        ? messageField
        : (message['content'] ?? message['message'] ?? '');

    // Parse metadata from various formats
    ChatMetadata? parsedMetadata;
    if (message['customFoodData'] != null) {
      parsedMetadata = ChatMetadata.fromCustomFood(message['customFoodData']);
    } else if (data['customFoodData'] != null) {
      parsedMetadata = ChatMetadata.fromCustomFood(data['customFoodData']);
    } else if (message['mealLogData'] != null) {
      parsedMetadata = ChatMetadata.fromMealLog(message['mealLogData']);
    } else if (message['metadata'] != null) {
      parsedMetadata = ChatMetadata.fromJson(message['metadata']);
    } else if (data['metadata'] != null) {
      parsedMetadata = ChatMetadata.fromJson(data['metadata']);
    } else if (message['confessionData'] != null) {
      parsedMetadata = ChatMetadata.fromConfession(message['confessionData']);
    } else if (data['confessionData'] != null) {
      parsedMetadata = ChatMetadata.fromConfession(data['confessionData']);
    } else if (message['allergyReportData'] != null) {
      parsedMetadata = ChatMetadata.fromAllergyReport(
        message['allergyReportData'],
      );
    } else if (data['allergyReportData'] != null) {
      parsedMetadata = ChatMetadata.fromAllergyReport(
        data['allergyReportData'],
      );
    } else if (message['recommendationData'] != null) {
      parsedMetadata = ChatMetadata.fromRecommendation(
        message['recommendationData'],
      );
    } else if (data['recommendationData'] != null) {
      parsedMetadata = ChatMetadata.fromRecommendation(
        data['recommendationData'],
      );
    }

    final socketMsgType =
        message['type'] ??
        message['messageType'] ??
        data['messageType'] ??
        'text';
    var socketAttachment = _parseAttachment(
      message['attachment'] ?? data['attachment'],
    );
    // If it's an image message with no attachment, the URL is in the content
    if (socketAttachment == null &&
        socketMsgType == 'image' &&
        textContent.startsWith('http')) {
      socketAttachment = textContent;
    }

    return ChatModel(
      id:
          message['id'] ??
          message['_id'] ??
          data['message_id'] ??
          data['_id'] ??
          '',
      senderId:
          message['senderId'] ?? message['sender_id'] ?? data['senderId'] ?? '',
      receiverId:
          message['receiverId'] ??
          message['receiver_id'] ??
          data['receiverId'] ??
          '',
      message: textContent,
      messageType: socketMsgType,
      attachment: socketAttachment,
      description: message['description'] ?? data['description'],
      metadata: parsedMetadata,
      isRead:
          message['status'] == 'read' ||
          message['isRead'] == true ||
          data['isRead'] == true,
      conversationId:
          message['conversationId'] ??
          message['conversation_id'] ??
          data['conversation_id'] ??
          data['conversationId'] ??
          '',
      createdAt: _parseDateTime(
        message['createdAt'] ?? message['created_at'] ?? data['createdAt'],
      ),
      updatedAt: _parseDateTime(
        message['updatedAt'] ?? message['updated_at'] ?? data['updatedAt'],
      ),
      senderRole:
          message['senderRole'] ??
          data['senderRole'] ??
          _getRoleFromId(
            message['senderId'] ?? message['sender_id'] ?? data['senderId'],
          ),
      receiverRole:
          message['receiverRole'] ??
          data['receiverRole'] ??
          _getRoleFromId(
            message['receiverId'] ??
                message['receiver_id'] ??
                data['receiverId'],
          ),
      isMe:
          message['isMe'] ??
          data['isMe'] ??
          (message['senderId'] ?? message['sender_id'] ?? data['senderId']) ==
              userId,
      serverSeq:
          message['serverSeq'] ?? message['server_seq'] ?? data['serverSeq'],
      replyTo: message['replyTo'] != null
          ? ChatModel.fromJson(message['replyTo'])
          : null,
      clientMessageId:
          message['clientMessageId'] ??
          message['client_message_id'] ??
          data['clientMessageId'] ??
          data['client_message_id'],
    );
  }

  static String? _parseAttachment(dynamic attachment) {
    if (attachment == null) return null;
    if (attachment is String) return attachment;
    if (attachment is Map) {
      return attachment['url'] ?? attachment['path'];
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _getRoleFromId(String? id) {
    // Dietician ID check
    if (id == userId) return 'dietician';
    return 'patient';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'attachment': attachment,
      'description': description,
      'metadata': metadata?.toJson(),
      'isRead': isRead,
      'conversationId': conversationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'senderRole': senderRole,
      'receiverRole': receiverRole,
      'isMe': isMe,
      'serverSeq': serverSeq,
      'clientMessageId': clientMessageId,
    };
  }

  bool get isMealLog =>
      messageType == 'meal_log' || messageType == 'diet_update';
  bool get isImage => messageType == 'image';
  bool get isText => messageType == 'text';
  bool get isWaterIntake => messageType == 'water_intake';
  bool get isCustomFood => messageType == 'custom_food';
  bool get isDietPlan => messageType == 'diet_plan';
  bool get isConfessionBox => messageType == 'confession_box';
  bool get isAllergyReport => messageType == 'allergy_report';
  bool get isDoctorRecommendation => messageType == 'doctor_recommendation';
}

class ChatMetadata {
  final String? mealLogId;
  final String? action;
  final String? itemName;
  final int? calories;
  final double? servings;
  final String? servingTime;
  final int? totalConsumed;
  final int? totalPlanned;
  final double? completionPercentage;
  final String? imageUrl;
  final String? foodName;
  final double? totalWeight;
  final double? protein;
  final double? carbs;
  final double? fat;
  final int? waterAmount; // in ml
  final String? customFoodRequestId;
  final String? confessionText;
  final String? allergyText;
  final String? recommendationText;
  final String? recommendationCategory;

  ChatMetadata({
    this.mealLogId,
    this.action,
    this.itemName,
    this.calories,
    this.servings,
    this.servingTime,
    this.totalConsumed,
    this.totalPlanned,
    this.completionPercentage,
    this.imageUrl,
    this.foodName,
    this.totalWeight,
    this.protein,
    this.carbs,
    this.fat,
    this.waterAmount,
    this.customFoodRequestId,
    this.confessionText,
    this.allergyText,
    this.recommendationText,
    this.recommendationCategory,
  });

  factory ChatMetadata.fromJson(Map<String, dynamic> json) {
    return ChatMetadata(
      mealLogId: json['mealLogId'],
      action: json['action'],
      itemName: json['itemName'],
      calories: json['calories'] is int
          ? json['calories']
          : (json['calories'] as num?)?.toInt(),
      servings: json['servings'] is double
          ? json['servings']
          : (json['servings'] as num?)?.toDouble(),
      servingTime: json['servingTime'],
      totalConsumed: json['totalConsumed'] is int
          ? json['totalConsumed']
          : (json['totalConsumed'] as num?)?.toInt(),
      totalPlanned: json['totalPlanned'] is int
          ? json['totalPlanned']
          : (json['totalPlanned'] as num?)?.toInt(),
      completionPercentage: json['completionPercentage'] is double
          ? json['completionPercentage']
          : (json['completionPercentage'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'],
      foodName: json['foodName'],
      totalWeight: (json['totalWeight'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      waterAmount: (json['waterAmount'] as num?)?.toInt(),
      customFoodRequestId: json['customFoodRequestId'],
      confessionText: json['confessionText'],
      allergyText: json['allergyText'],
      recommendationText: json['recommendationText'],
      recommendationCategory: json['recommendationCategory'],
    );
  }

  /// Factory to create from confession data
  factory ChatMetadata.fromConfession(Map<String, dynamic> json) {
    return ChatMetadata(confessionText: json['confessionText']);
  }

  /// Factory to create from allergy report data
  factory ChatMetadata.fromAllergyReport(Map<String, dynamic> json) {
    return ChatMetadata(allergyText: json['allergyText']);
  }

  /// Factory to create from recommendation data
  factory ChatMetadata.fromRecommendation(Map<String, dynamic> json) {
    return ChatMetadata(
      recommendationText: json['recommendationText'],
      recommendationCategory: json['category'],
    );
  }

  /// Factory to create from custom food data in API/socket messages
  factory ChatMetadata.fromCustomFood(Map<String, dynamic> json) {
    // Map customFoodData.status ('pending'/'approved'/'rejected') to action
    final status = json['status']?.toString().toLowerCase();
    return ChatMetadata(
      action: status,
      foodName: json['foodName'],
      itemName: json['foodName'],
      calories: (json['calories'] as num?)?.toInt(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      imageUrl: json['image'],
      customFoodRequestId: json['customFoodRequestId'] ?? json['_id'],
    );
  }

  /// Factory to create from meal log data in socket messages
  factory ChatMetadata.fromMealLog(Map<String, dynamic> json) {
    return ChatMetadata(
      mealLogId: json['mealLogId'] ?? json['_id'],
      action: json['action'],
      itemName: json['itemName'] ?? json['recipeName'] ?? json['foodName'],
      calories: (json['caloriesConsumed'] ?? json['calories'] as num?)?.toInt(),
      servings: (json['servings'] as num?)?.toDouble(),
      servingTime: json['servingTime'],
      totalConsumed: (json['totalConsumed'] as num?)?.toInt(),
      totalPlanned: (json['totalPlanned'] as num?)?.toInt(),
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] ?? json['image'],
      foodName: json['foodName'] ?? json['recipeName'],
      totalWeight: (json['totalWeight'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      waterAmount: (json['waterAmount'] ?? json['amount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealLogId': mealLogId,
      'action': action,
      'itemName': itemName,
      'calories': calories,
      'servings': servings,
      'servingTime': servingTime,
      'totalConsumed': totalConsumed,
      'totalPlanned': totalPlanned,
      'completionPercentage': completionPercentage,
      'imageUrl': imageUrl,
      'foodName': foodName,
      'totalWeight': totalWeight,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'waterAmount': waterAmount,
      'customFoodRequestId': customFoodRequestId,
      'confessionText': confessionText,
      'allergyText': allergyText,
      'recommendationText': recommendationText,
      'recommendationCategory': recommendationCategory,
    };
  }
}

class ReceiverModel {
  String receiverId;
  String? name;
  String? profileImage;

  ReceiverModel({required this.receiverId, this.name, this.profileImage});

  factory ReceiverModel.fromJson(Map<String, dynamic> json) {
    return ReceiverModel(
      receiverId: json['receiverId'] ?? json['senderId'] ?? '',
      name: json['senderName'] ?? json['name'],
      profileImage: json['senderProfileImage'] ?? json['profileImage'],
    );
  }

  /// Factory to create from patient data
  factory ReceiverModel.fromPatientJson(Map<String, dynamic> json) {
    return ReceiverModel(
      receiverId: json['senderId'] ?? json['receiverId'] ?? '',
      name: json['senderName'] ?? json['patientName'],
      profileImage: json['senderProfileImage'],
    );
  }
}
