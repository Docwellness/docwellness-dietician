import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MealLogBubble extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onReply;

  const MealLogBubble({super.key, required this.chat, this.onReply});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: const Color(0xffFDF2FA),
          borderRadius: BorderRadius.circular(12),
          border: cardBorder,
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xffFCE7F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getActionColor().withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActionIcon(),
                      size: 16,
                      color: _getActionColor(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getActionText(),
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff1F2A37),
                          ),
                        ),
                        if (chat.metadata?.servingTime != null)
                          Text(
                            chat.metadata!.servingTime!,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xff6B7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getActionColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getActionBadge(),
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getActionColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (chat.attachment != null && chat.attachment!.isNotEmpty)
              ClipRRect(
                child: CachedNetworkImage(
                  imageUrl: chat.attachment!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    color: const Color(0xffFCE7F6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff851653),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: const Color(0xffFCE7F6),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xff851653),
                      size: 40,
                    ),
                  ),
                ),
              )
            else if (chat.metadata?.imageUrl != null)
              ClipRRect(
                child: CachedNetworkImage(
                  imageUrl: chat.metadata!.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    color: const Color(0xffFCE7F6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff851653),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: const Color(0xffFCE7F6),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xff851653),
                      size: 40,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chat.metadata?.itemName != null)
                    Text(
                      chat.metadata!.itemName!,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1F2A37),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (chat.message.isNotEmpty &&
                      chat.message != chat.metadata?.itemName)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        chat.message,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: const Color(0xff4B5563),
                        ),
                      ),
                    ),

                  // Meal notes store the same text in both `message` and
                  // `description` - only show it once.
                  if (chat.description != null &&
                      chat.description!.isNotEmpty &&
                      chat.description != chat.message)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        chat.description!,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xff6B7280),
                        ),
                      ),
                    ),

                  if (chat.metadata?.calories != null ||
                      chat.metadata?.servings != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (chat.metadata?.calories != null) ...[
                              const Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Color(0xffF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${chat.metadata!.calories} cal',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xff1F2A37),
                                ),
                              ),
                            ],
                            if (chat.metadata?.calories != null &&
                                chat.metadata?.servings != null)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                width: 1,
                                height: 16,
                                color: const Color(0xffE5E7EB),
                              ),
                            if (chat.metadata?.servings != null) ...[
                              const Icon(
                                Icons.restaurant,
                                size: 16,
                                color: Color(0xff851653),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${chat.metadata!.servings} serving${chat.metadata!.servings! > 1 ? 's' : ''}',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xff1F2A37),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  if (chat.metadata?.totalConsumed != null &&
                      chat.metadata?.totalPlanned != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Progress',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xff6B7280),
                                ),
                              ),
                              Text(
                                '${chat.metadata!.totalConsumed}/${chat.metadata!.totalPlanned} cal',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff1F2A37),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: chat.metadata!.totalPlanned! > 0
                                  ? (chat.metadata!.totalConsumed! /
                                            chat.metadata!.totalPlanned!)
                                        .clamp(0.0, 1.0)
                                  : 0,
                              backgroundColor: const Color(0xffE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                chat.metadata!.totalConsumed! >=
                                        chat.metadata!.totalPlanned!
                                    ? Colors.green
                                    : const Color(0xff851653),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (chat.metadata?.action == 'completed')
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(chat.createdAt),
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: const Color(0xff9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon() {
    switch (chat.metadata?.action) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'updated':
        return Icons.edit_outlined;
      case 'added':
        return Icons.add_circle_outline;
      case 'note':
        return Icons.note_alt_outlined;
      default:
        return Icons.restaurant;
    }
  }

  Color _getActionColor() {
    switch (chat.metadata?.action) {
      case 'completed':
        return Colors.green;
      case 'updated':
        return Colors.orange;
      case 'added':
        return const Color(0xff851653);
      case 'note':
        return Colors.blue;
      default:
        return const Color(0xff851653);
    }
  }

  String _getActionText() {
    switch (chat.metadata?.action) {
      case 'completed':
        return 'Patient Completed Meal';
      case 'updated':
        return 'Patient Updated Meal';
      case 'added':
        return 'Patient Logged Meal';
      case 'note':
        return 'Patient Shared Note';
      default:
        return 'Meal Activity';
    }
  }

  String _getActionBadge() {
    switch (chat.metadata?.action) {
      case 'completed':
        return 'DONE';
      case 'updated':
        return 'EDITED';
      case 'added':
        return 'NEW';
      case 'note':
        return 'NOTE';
      default:
        return 'LOG';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
