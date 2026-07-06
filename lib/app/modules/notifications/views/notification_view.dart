import 'package:docwellnesdoc/app/modules/notifications/controllers/notification_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: const Color(0xff1F2A37),
          ),
        ),
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0) return const SizedBox();
            return TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: Text(
                'Mark all read',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xff851653),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff851653)),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: const Color(0xff94A3B8),
                ),
                const SizedBox(height: 12),
                CustomText(
                  text: 'No notifications yet',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff94A3B8),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: const Color(0xff851653),
          onRefresh: () => controller.fetchNotifications(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 100) {
                controller.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount:
                  controller.notifications.length +
                  (controller.isLoadingMore.value ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xffF1F5F9)),
              itemBuilder: (context, index) {
                if (index >= controller.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xff851653),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }
                final item = controller.notifications[index];
                return _NotificationTile(
                  item: item,
                  onTap: () => controller.onTapNotification(item),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  IconData get _icon {
    switch (item.type) {
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'diet_plan':
        return Icons.restaurant_menu_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'progress':
        return Icons.trending_up_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case 'chat':
        return const Color(0xff3B82F6);
      case 'diet_plan':
        return const Color(0xff10B981);
      case 'payment':
        return const Color(0xffF59E0B);
      case 'progress':
        return const Color(0xff8B5CF6);
      default:
        return const Color(0xff851653);
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? Colors.white : const Color(0xffFDF2FA),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 20, color: _iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: item.title,
                          fontSize: 13.5,
                          fontWeight: item.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: const Color(0xff1F2A37),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        text: _timeAgo,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: item.message,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff64748B),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: Color(0xff851653),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
