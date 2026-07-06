class ChatUser {
  final String id;
  final String? image;
  final String name;
  final String message;
  final DateTime time;
  final int count;
  final bool isOnline;

  ChatUser({
    required this.id,
    this.image,
    required this.name,
    required this.message,
    required this.time,
    required this.count,
    required this.isOnline,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      image: json['image'],
      name: json['name'] ?? '',
      message: json['message'] ?? '',
      time: DateTime.parse(json['time']),
      count: json['count'] ?? 0,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'message': message,
      'time': time.toIso8601String(),
      'count': count,
      'isOnline': isOnline,
    };
  }
}
