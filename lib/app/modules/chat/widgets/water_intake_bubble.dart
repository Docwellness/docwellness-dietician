import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Water Intake Card Widget
/// Shows water intake logged by patient in chat
class WaterIntakeBubble extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onReply;

  const WaterIntakeBubble({super.key, required this.chat, this.onReply});

  @override
  Widget build(BuildContext context) {
    final waterAmount = chat.metadata?.waterAmount ?? 0;
    final waterInLiters = waterAmount / 1000;

    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xffE0F2FE), const Color(0xffBAE6FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0EA5E9).withOpacity(0.15),
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
                color: const Color(0xff0EA5E9).withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff0EA5E9).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 20,
                      color: Color(0xff0284C7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water Intake',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff0C4A6E),
                          ),
                        ),
                        Text(
                          _formatTime(chat.createdAt),
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: const Color(0xff0369A1),
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
                      color: const Color(0xff0284C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          '${waterAmount}ml',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Water visualization
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaterGlass(waterAmount >= 250),
                      const SizedBox(width: 8),
                      _buildWaterGlass(waterAmount >= 500),
                      const SizedBox(width: 8),
                      _buildWaterGlass(waterAmount >= 750),
                      const SizedBox(width: 8),
                      _buildWaterGlass(waterAmount >= 1000),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amount display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          waterInLiters >= 1
                              ? '${waterInLiters.toStringAsFixed(1)}L'
                              : '${waterAmount}ml',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'logged',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: const Color(0xff0369A1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (chat.message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        chat.message,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: const Color(0xff0C4A6E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // Footer with reply
            if (onReply != null)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onReply,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.reply,
                        size: 18,
                        color: Color(0xff0284C7),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterGlass(bool filled) {
    return Container(
      width: 32,
      height: 40,
      decoration: BoxDecoration(
        color: filled ? const Color(0xff0EA5E9) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xff0284C7).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.water_drop,
        size: 18,
        color: filled ? Colors.white : const Color(0xff0284C7).withOpacity(0.3),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
