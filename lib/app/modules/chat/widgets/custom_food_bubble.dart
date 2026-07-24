import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:docwellnesdoc/core/config/env_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Food Request Card Widget
/// Shows when patient creates a custom food request (off-plan eating)
class CustomFoodBubble extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onReply;

  const CustomFoodBubble({
    super.key,
    required this.chat,
    this.onApprove,
    this.onReject,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = chat.metadata;
    final foodName = metadata?.foodName ?? metadata?.itemName ?? 'Custom Food';
    final calories = metadata?.calories;
    final rawImageUrl = metadata?.imageUrl ?? chat.attachment;
    // AI_EXECUTION_PLAN.md Phase 7, P7-01 - was a hardcoded production IP
    // (http://65.20.81.44:5001), which silently broke this image in dev/
    // staging and would need a code change (not just an env var) to ever
    // repoint. EnvService.apiHost is the same env-driven base every other
    // relative-URL resolution in this app already goes through.
    final imageUrl =
        (rawImageUrl != null &&
            rawImageUrl.isNotEmpty &&
            rawImageUrl.startsWith('/'))
        ? '${EnvService.apiHost}$rawImageUrl'
        : rawImageUrl;

    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffFED7AA), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffF97316).withOpacity(0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xffFB923C), const Color(0xffF97316)],
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
                      Icons.fastfood,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Food Request',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          metadata?.servingTime ?? 'Off-plan meal',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
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
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: GoogleFonts.roboto(
                            fontSize: 10,
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

            // Image (if available)
            if (imageUrl != null && imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _openFullScreenImage(imageUrl),
                child: ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 140,
                      color: const Color(0xffFFF7ED),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xffF97316),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 100,
                      color: const Color(0xffFFF7ED),
                      child: const Icon(
                        Icons.fastfood,
                        color: Color(0xffF97316),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),

            // Food details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodName,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff1F2A37),
                    ),
                  ),

                  if (chat.description != null && chat.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        chat.description!,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: const Color(0xff6B7280),
                        ),
                      ),
                    ),

                  if (chat.message.isNotEmpty && chat.message != foodName)
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

                  // Nutrient info
                  if (calories != null || metadata?.servings != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (metadata?.servings != null)
                            _buildInfoItem(
                              Icons.restaurant,
                              '${metadata!.servings}',
                              'portions',
                            ),
                          if (calories != null)
                            _buildInfoItem(
                              Icons.local_fire_department,
                              '$calories',
                              'kcal',
                            ),
                          if (metadata?.totalWeight != null)
                            _buildInfoItem(
                              Icons.scale,
                              '${metadata!.totalWeight!.toInt()}g',
                              'weight',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons (for dietician only, when pending)
            if (!chat.isMe &&
                _isPending() &&
                (onApprove != null || onReject != null))
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xffEF4444),
                            side: const BorderSide(color: Color(0xffEF4444)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (onApprove != null && onReject != null)
                      const SizedBox(width: 10),
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
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
                          color: Color(0xffF97316),
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

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xffF97316)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
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

  bool _isPending() {
    final action = chat.metadata?.action?.toLowerCase();
    return action == null || action == 'pending' || action.isEmpty;
  }

  IconData _getStatusIcon() {
    final action = chat.metadata?.action?.toLowerCase();
    switch (action) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusText() {
    final action = chat.metadata?.action?.toLowerCase();
    switch (action) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _openFullScreenImage(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Food Image',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Color(0xffF97316)),
              ),
              errorWidget: (_, __, ___) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
