import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfessionBoxBubble extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onReply;

  const ConfessionBoxBubble({super.key, required this.chat, this.onReply});

  @override
  Widget build(BuildContext context) {
    final confessionText =
        chat.metadata?.confessionText ??
        chat.message.replaceFirst(RegExp(r'^🍕\s*Confession Box\s*\n*'), '');

    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: const Color(0xffFDF2FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffFCE7F6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff851653).withOpacity(0.08),
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
                  colors: [const Color(0xffF97316), const Color(0xffFB923C)],
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
                    child: const Text('🍕', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confession Box',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
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
              child: Text(
                confessionText,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: const Color(0xff1F2A37),
                  height: 1.4,
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(chat.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xff9CA3AF),
                    ),
                  ),
                  if (onReply != null)
                    InkWell(
                      onTap: onReply,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.reply,
                          size: 20,
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
