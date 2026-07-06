import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Diet Plan Card Widget
/// Shows weekly diet plan sent by dietician in chat
class DietPlanBubble extends StatelessWidget {
  final ChatModel chat;
  final List<DietPlanItem>? dietItems;
  final VoidCallback? onReply;

  const DietPlanBubble({
    super.key,
    required this.chat,
    this.dietItems,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    // Parse diet items from metadata or message
    final items = dietItems ?? _parseDietItems();

    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffFCE7F6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff9F1561).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xff9F1561), const Color(0xffC51162)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Diet Plan',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getWeekLabel(),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length} meals',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Diet items list
            if (items.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: items.length > 5
                    ? 5
                    : items.length, // Show max 5 items
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildDietItem(item);
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  chat.message.isNotEmpty ? chat.message : 'Diet plan details',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xff4B5563),
                  ),
                ),
              ),

            // Show more if more than 5 items
            if (items.length > 5)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                child: Center(
                  child: Text(
                    '+${items.length - 5} more meals',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xff9F1561),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Footer - Total calories
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientInfo(
                    Icons.local_fire_department,
                    '${_getTotalCalories(items)}',
                    'kcal',
                    const Color(0xffEF4444),
                  ),
                  _buildNutrientInfo(
                    Icons.fitness_center,
                    '${_getTotalProtein(items)}g',
                    'protein',
                    const Color(0xff3B82F6),
                  ),
                  _buildNutrientInfo(
                    Icons.grain,
                    '${_getTotalCarbs(items)}g',
                    'carbs',
                    const Color(0xffF59E0B),
                  ),
                  _buildNutrientInfo(
                    Icons.water_drop,
                    '${_getTotalFat(items)}g',
                    'fat',
                    const Color(0xff10B981),
                  ),
                ],
              ),
            ),

            // Timestamp & Reply
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8, left: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(chat.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: const Color(0xff9CA3AF),
                    ),
                  ),
                  if (onReply != null)
                    InkWell(
                      onTap: onReply,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.reply,
                          size: 18,
                          color: Color(0xff851653),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietItem(DietPlanItem item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                (item.imageUrl != null &&
                    item.imageUrl!.isNotEmpty &&
                    item.imageUrl!.startsWith('http'))
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildPlaceholderImage(),
                    errorWidget: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Serving time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: _getServingTimeColor(
                      item.servingTime,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.servingTime,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getServingTimeColor(item.servingTime),
                    ),
                  ),
                ),
                Text(
                  item.name,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1F2A37),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.totalWeight.toInt()}g',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: const Color(0xff6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.local_fire_department,
                      size: 12,
                      color: Color(0xffEF4444),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.calories} kcal',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xffEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xffFCE7F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: Color(0xff9F1561), size: 24),
    );
  }

  Widget _buildNutrientInfo(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1F2A37),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: const Color(0xff6B7280),
          ),
        ),
      ],
    );
  }

  Color _getServingTimeColor(String servingTime) {
    switch (servingTime.toLowerCase()) {
      case 'morning drink':
        return const Color(0xffF59E0B);
      case 'breakfast':
        return const Color(0xffEF4444);
      case 'brunch':
        return const Color(0xffEC4899);
      case 'lunch':
        return const Color(0xff10B981);
      case 'evening snack':
        return const Color(0xff8B5CF6);
      case 'dinner':
        return const Color(0xff3B82F6);
      case 'night drink':
        return const Color(0xff6366F1);
      default:
        return const Color(0xff9F1561);
    }
  }

  String _getWeekLabel() {
    // Try to get week info from metadata
    return 'Weekly Plan';
  }

  List<DietPlanItem> _parseDietItems() {
    // Parse diet items from chat metadata
    final metadata = chat.metadata;
    if (metadata == null) return [];

    // If single item
    if (metadata.foodName != null || metadata.itemName != null) {
      return [
        DietPlanItem(
          name: metadata.foodName ?? metadata.itemName ?? 'Unknown',
          servingTime: metadata.servingTime ?? 'Meal',
          totalWeight: metadata.totalWeight ?? 100,
          calories: metadata.calories ?? 0,
          protein: metadata.protein ?? 0,
          carbs: metadata.carbs ?? 0,
          fat: metadata.fat ?? 0,
          imageUrl: metadata.imageUrl,
        ),
      ];
    }

    return [];
  }

  int _getTotalCalories(List<DietPlanItem> items) {
    return items.fold(0, (sum, item) => sum + item.calories);
  }

  double _getTotalProtein(List<DietPlanItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.protein);
  }

  double _getTotalCarbs(List<DietPlanItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.carbs);
  }

  double _getTotalFat(List<DietPlanItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.fat);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Model for diet plan item
class DietPlanItem {
  final String name;
  final String servingTime;
  final double totalWeight;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;

  DietPlanItem({
    required this.name,
    required this.servingTime,
    required this.totalWeight,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
  });

  factory DietPlanItem.fromJson(Map<String, dynamic> json) {
    return DietPlanItem(
      name: json['name'] ?? json['recipeName'] ?? 'Unknown',
      servingTime: json['servingTime'] ?? 'Meal',
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 100,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] ?? json['image'],
    );
  }
}
