/// Last message preview in conversation
class LastMessage {
  final String content;
  final DateTime timestamp;
  final String? senderId;

  LastMessage({
    required this.content,
    required this.timestamp,
    this.senderId,
  });

  factory LastMessage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LastMessage(
        content: '',
        timestamp: DateTime.now(),
      );
    }
    return LastMessage(
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      senderId: json['senderId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (senderId != null) 'senderId': senderId,
    };
  }
}

/// User info within conversation
class ConversationUser {
  final String id;
  final String name;
  final String? email;
  final String? profileImage;
  final String role;
  final bool? isOnline;

  ConversationUser({
    required this.id,
    required this.name,
    this.email,
    this.profileImage,
    required this.role,
    this.isOnline,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      profileImage: json['profileImage'],
      role: json['role'] ?? 'patient',
      isOnline: json['isOnline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (profileImage != null) 'profileImage': profileImage,
      'role': role,
      if (isOnline != null) 'isOnline': isOnline,
    };
  }
}

/// Conversation model matching backend: models/Conversation.js
class ConversationModel {
  final String id;
  final List<String> participants;
  final String patientId;
  final String doctorId;
  final ConversationUser? otherUser; // The other participant's info
  final LastMessage lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.patientId,
    required this.doctorId,
    this.otherUser,
    required this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Handle participants - could be ObjectIds or populated User objects
    List<String> participantIds = [];
    if (json['participants'] != null) {
      for (var p in json['participants']) {
        if (p is String) {
          participantIds.add(p);
        } else if (p is Map) {
          participantIds.add(p['_id'] ?? p['id'] ?? '');
        }
      }
    }

    // Extract patientId
    String patientId = '';
    if (json['patientId'] is Map) {
      patientId = json['patientId']['_id'] ?? '';
    } else {
      patientId = json['patientId']?.toString() ?? '';
    }

    // Extract doctorId
    String doctorId = '';
    if (json['doctorId'] is Map) {
      doctorId = json['doctorId']['_id'] ?? '';
    } else {
      doctorId = json['doctorId']?.toString() ?? '';
    }

    // Extract other user info (for doctor app, this is the patient)
    ConversationUser? otherUser;
    if (json['otherUser'] != null) {
      otherUser = ConversationUser.fromJson(json['otherUser']);
    } else if (json['patientId'] is Map) {
      otherUser = ConversationUser.fromJson(json['patientId']);
    }

    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      participants: participantIds,
      patientId: patientId,
      doctorId: doctorId,
      otherUser: otherUser,
      lastMessage: LastMessage.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'] ?? json['count'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'patientId': patientId,
      'doctorId': doctorId,
      'otherUser': otherUser?.toJson(),
      'lastMessage': lastMessage.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get display name (patient's name for doctor app)
  String get displayName => otherUser?.name ?? 'Unknown';

  /// Get profile image
  String? get profileImage => otherUser?.profileImage;

  /// Check if patient is online
  bool get isOnline => otherUser?.isOnline ?? false;

  /// Get last message preview (truncated)
  String get lastMessagePreview {
    if (lastMessage.content.isEmpty) return 'No messages yet';
    if (lastMessage.content.length > 50) {
      return '${lastMessage.content.substring(0, 50)}...';
    }
    return lastMessage.content;
  }

  /// Get time ago string for last message
  String get timeAgo {
    final now = DateTime.now().toUtc();
    final difference = now.difference(lastMessage.timestamp);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  /// Check if has unread messages
  bool get hasUnread => unreadCount > 0;
}
