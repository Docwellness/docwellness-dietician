import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorRecommendationBubble extends StatelessWidget {
  final ChatModel chat;

  const DoctorRecommendationBubble({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final recommendationText =
        chat.metadata?.recommendationText ?? chat.message;
    final category = chat.metadata?.recommendationCategory ?? 'general';

    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: const Color(0xffF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffBBF7D0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff10B981).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xff059669), const Color(0xff10B981)],
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recommendation',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _categoryLabel(category),
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _categoryIcon(category),
                    size: 18,
                    color: const Color(0xff059669),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recommendationText,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xff1F2A37),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                _formatTime(chat.createdAt),
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: const Color(0xff9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'diet':
        return 'DIET';
      case 'exercise':
        return 'EXERCISE';
      case 'lifestyle':
        return 'LIFESTYLE';
      default:
        return 'GENERAL';
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'diet':
        return Icons.restaurant_outlined;
      case 'exercise':
        return Icons.fitness_center_outlined;
      case 'lifestyle':
        return Icons.self_improvement_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
