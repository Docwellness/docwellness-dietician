/// Model for individual meal items within a meal log
class MealItem {
  final String? id;
  final String name;
  final String? quantity;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final int? fiber;
  final String? imageUrl;
  final bool isCompleted;

  MealItem({
    this.id,
    required this.name,
    this.quantity,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.imageUrl,
    this.isCompleted = false,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      quantity: json['quantity'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      fiber: json['fiber'],
      imageUrl: json['imageUrl'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (quantity != null) 'quantity': quantity,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (fiber != null) 'fiber': fiber,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isCompleted': isCompleted,
    };
  }
}

/// Model for meal logs submitted by patients
/// Matches backend: models/MealLog.js
class MealLogModel {
  final String id;
  final String patientId;
  final DateTime date;
  final String mealType; // morning_drink, breakfast, fruits, lunch, evening, dinner
  final List<MealItem> items;
  final String? notes;
  final List<String> images; // Photos of actual meals
  final int totalCalories;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // pending, approved, rejected
  final DateTime submittedAt;
  final bool isCustomMeal;
  final String? description;
  final List<String>? ingredients;

  MealLogModel({
    required this.id,
    required this.patientId,
    required this.date,
    required this.mealType,
    required this.items,
    this.notes,
    this.images = const [],
    this.totalCalories = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'pending',
    DateTime? submittedAt,
    this.isCustomMeal = false,
    this.description,
    this.ingredients,
  }) : submittedAt = submittedAt ?? createdAt;

  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    return MealLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      patientId: json['patientId'] is Map
          ? json['patientId']['_id'] ?? ''
          : json['patientId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      mealType: json['mealType'] ?? 'meal',
      items: json['items'] != null
          ? (json['items'] as List).map((e) => MealItem.fromJson(e)).toList()
          : [],
      notes: json['notes'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      totalCalories: json['totalCalories'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      isCustomMeal: json['isCustomMeal'] ?? json['isCustom'] ?? false,
      description: json['description'],
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'date': date.toIso8601String(),
      'mealType': mealType,
      'items': items.map((e) => e.toJson()).toList(),
      'notes': notes,
      'images': images,
      'totalCalories': totalCalories,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'isCustomMeal': isCustomMeal,
      if (description != null) 'description': description,
      if (ingredients != null) 'ingredients': ingredients,
    };
  }

  /// Check if meal was updated after creation
  bool get isEdited => updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));

  /// Get display name for meal type based on backend enum
  String get mealTypeDisplay {
    switch (mealType.toLowerCase()) {
      case 'morning_drink':
        return '☕ Morning Drink';
      case 'breakfast':
        return '🍳 Breakfast';
      case 'fruits':
        return '🍎 Fruits';
      case 'lunch':
        return '🍱 Lunch';
      case 'evening':
        return '🌙 Evening Snack';
      case 'dinner':
        return '🍽️ Dinner';
      default:
        return '🍴 Meal';
    }
  }

  /// Get meal type icon
  String get mealTypeIcon {
    switch (mealType.toLowerCase()) {
      case 'morning_drink':
        return '☕';
      case 'breakfast':
        return '🍳';
      case 'fruits':
        return '🍎';
      case 'lunch':
        return '🍱';
      case 'evening':
        return '🌙';
      case 'dinner':
        return '🍽️';
      default:
        return '🍴';
    }
  }

  /// Get all item names as comma-separated string
  String get itemsDisplay {
    if (items.isEmpty) return 'No items';
    return items.map((e) => e.name).join(', ');
  }

  /// Get first item name for preview
  String get firstItemName {
    if (items.isEmpty) return 'No items';
    return items.first.name;
  }

  /// Check if any item is completed
  bool get hasCompletedItems => items.any((item) => item.isCompleted);

  /// Get completion progress
  String get completionStatus {
    if (items.isEmpty) return '0/0';
    final completed = items.where((item) => item.isCompleted).length;
    return '$completed/${items.length}';
  }

  /// Get meal name - returns first item name or meal type display
  String get mealName {
    if (items.isNotEmpty) return items.first.name;
    return mealTypeDisplay;
  }

  /// Get total calories from items or totalCalories field
  int? get calories {
    if (totalCalories > 0) return totalCalories;
    if (items.isEmpty) return null;
    int sum = 0;
    for (final item in items) {
      sum += item.calories ?? 0;
    }
    return sum > 0 ? sum : null;
  }

  /// Get first image URL from images list or first item's image
  String? get imageUrl {
    if (images.isNotEmpty) return images.first;
    for (final item in items) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        return item.imageUrl;
      }
    }
    return null;
  }
}
