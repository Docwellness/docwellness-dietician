import 'package:docwellnesdoc/app/models/meal_log_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Widget to display a meal log card in the chat/logs view
class MealLogWidget extends StatelessWidget {
  final MealLogModel meal;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final bool showActions;

  const MealLogWidget({
    super.key,
    required this.meal,
    this.onApprove,
    this.onReject,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getBorderColor()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            if (showActions) _buildActions(),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (meal.status) {
      case 'approved':
        return const Color(0xff22C55E);
      case 'rejected':
        return const Color(0xffEF4444);
      default:
        return const Color(0xffFCCEEF);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xffFDF2FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _buildMealTypeIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealTypeDisplay,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff851653),
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(meal.submittedAt),
                  style: GoogleFonts.roboto(
                    color: const Color(0xff9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildMealTypeIcon() {
    IconData iconData;
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        iconData = Icons.free_breakfast;
        break;
      case 'lunch':
        iconData = Icons.lunch_dining;
        break;
      case 'dinner':
        iconData = Icons.dinner_dining;
        break;
      case 'snack':
        iconData = Icons.cookie;
        break;
      default:
        iconData = Icons.restaurant;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xffFCCEEF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: const Color(0xff851653), size: 20),
    );
  }

  Widget _buildStatusBadge() {
    if (meal.isEdited) {
      return _badge('✏️ Edited', const Color(0xffFEF3C7), const Color(0xff92400E));
    }
    if (meal.isCustomMeal) {
      return _badge('🆕 Custom', const Color(0xffDCFCE7), const Color(0xff166534));
    }
    if (meal.status == 'approved') {
      return _badge('✓ Approved', const Color(0xffDCFCE7), const Color(0xff166534));
    }
    if (meal.status == 'rejected') {
      return _badge('✕ Rejected', const Color(0xffFEE2E2), const Color(0xffDC2626));
    }
    return _badge('⏳ Pending', const Color(0xffFEF3C7), const Color(0xff92400E));
  }

  Widget _badge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(fontSize: 10, color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealImage(),
          const SizedBox(width: 12),
          Expanded(child: _buildMealDetails()),
        ],
      ),
    );
  }

  Widget _buildMealImage() {
    if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          meal.imageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderImage(),
        ),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xffFCCEEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.restaurant,
        color: Color(0xff851653),
        size: 32,
      ),
    );
  }

  Widget _buildMealDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal.mealName,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: const Color(0xff1F2A37),
          ),
        ),
        if (meal.calories != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.local_fire_department, size: 14, color: Color(0xff851653)),
              const SizedBox(width: 4),
              Text(
                '${meal.calories} kcal',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: const Color(0xff851653),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (meal.ingredients != null && meal.ingredients!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: meal.ingredients!.take(3).map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ingredient,
                  style: GoogleFonts.roboto(fontSize: 10, color: const Color(0xff6B7280)),
                ),
              );
            }).toList(),
          ),
        ],
        if (meal.description != null && meal.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            meal.description!,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: const Color(0xff6B7280),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    if (meal.status != 'pending') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xffFCCEEF)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_circle_outline, size: 18, color: Color(0xff166534)),
            label: Text(
              'Approve',
              style: GoogleFonts.roboto(color: const Color(0xff166534), fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xffDC2626)),
            label: Text(
              'Reject',
              style: GoogleFonts.roboto(color: const Color(0xffDC2626), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of meal log widget for list views
class MealLogCompactWidget extends StatelessWidget {
  final MealLogModel meal;
  final VoidCallback? onTap;

  const MealLogCompactWidget({
    super.key,
    required this.meal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xffFCCEEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          meal.mealType.toLowerCase() == 'breakfast' ? '🍳' :
          meal.mealType.toLowerCase() == 'lunch' ? '🍱' :
          meal.mealType.toLowerCase() == 'dinner' ? '🍽️' :
          meal.mealType.toLowerCase() == 'snack' ? '🍎' : '🍴',
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        meal.mealName,
        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${meal.mealTypeDisplay} • ${DateFormat('HH:mm').format(meal.submittedAt)}',
        style: GoogleFonts.roboto(fontSize: 12, color: const Color(0xff6B7280)),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (meal.calories != null)
            Text(
              '${meal.calories} kcal',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xff851653),
              ),
            ),
          if (meal.isEdited)
            const Text('✏️', style: TextStyle(fontSize: 12)),
          if (meal.isCustomMeal)
            const Text('🆕', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
