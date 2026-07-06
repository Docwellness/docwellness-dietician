import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class MessageCard extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String avatar;
  final String? secondAvatar;
  final int? isOnline;
  final VoidCallback onTap;

  const MessageCard({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatar,
    this.secondAvatar,
    this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: unreadCount > 0
              ? const Color(0xffFDF2FA)
              : const Color(0xffFEF9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unreadCount > 0
                ? const Color(0xffF3D5EA)
                : const Color(0xffF5EDF2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            SizedBox(
              height: 50,
              width: 50,
              child: secondAvatar == null ? _singleAvatar() : _groupAvatar(),
            ),

            const SizedBox(width: 14),

            // Name + Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: name,
                    fontSize: 15,
                    fontWeight: unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: const Color(0xff111927),
                  ),
                  const SizedBox(height: 5),
                  CustomText(
                    text: message,
                    fontSize: 13,
                    fontWeight: unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: unreadCount > 0
                        ? const Color(0xff374151)
                        : const Color(0xff6B7280),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Time + Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time != '0' && time != 'now')
                  CustomText(
                    text: time,
                    fontSize: 11,
                    color: unreadCount > 0
                        ? const Color(0xff851653)
                        : const Color(0xff9DA4AE),
                    fontWeight: unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                if (time == 'now')
                  CustomText(
                    text: 'now',
                    fontSize: 11,
                    color: const Color(0xff851653),
                    fontWeight: FontWeight.w600,
                  ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xff851653),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // SINGLE AVATAR
  // -----------------------------
  Widget _singleAvatar() {
    return Stack(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2.2),
            borderRadius: BorderRadius.circular(90),
            color: const Color(0xffF3F4F6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(90),
            child: Image.asset(avatar, fit: BoxFit.cover),
          ),
        ),

        // online/offline dot
        if (isOnline != null)
          Positioned(
            bottom: 8,
            right: 6,
            child: Container(
              height: 11,
              width: 11,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(90),
                color: Colors.white,
              ),
              child: CircleAvatar(
                backgroundColor: isOnline == 1
                    ? const Color(0xff22C55E)
                    : const Color(0xffDE2493),
              ),
            ),
          ),
      ],
    );
  }

  // -----------------------------
  // GROUP AVATARS (2 avatars)
  // -----------------------------
  Widget _groupAvatar() {
    return Stack(
      children: [
        // FRONT AVATAR (top-right)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2.2),
              borderRadius: BorderRadius.circular(90),
              color: const Color(0xffF3F4F6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(90),
              child: Image.asset(secondAvatar!, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2.2),
              borderRadius: BorderRadius.circular(90),
              color: const Color(0xffF3F4F6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(90),
              child: Image.asset(avatar, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}
