import 'package:docwellnesdoc/app/modules/chat/controllers/chat_controller.dart';
import 'package:docwellnesdoc/app/modules/chat/views/chat_screen.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/chat_info_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// The other half of ChatView's swipe-to-archive - lists whatever this
/// dietician has archived (per-participant archivedAt, see the backend
/// Conversation/ConversationV1 models) and lets them swipe the same way to
/// bring a chat back onto the main Chats list.
class ArchivedChatsView extends GetView<ChatController> {
  const ArchivedChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.getArchivedChats();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        leading: BackButton(color: const Color(0xff1F2A37)),
        title: Text(
          'Archived Chats',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1F2A37),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.showArchivedChatsLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff851653)),
          );
        }

        if (controller.archivedChatsList.isEmpty) {
          return Center(
            child: Text(
              'No archived chats',
              style: GoogleFonts.roboto(
                color: const Color(0xff6B7280),
                fontSize: 16,
              ),
            ),
          );
        }

        String timeAgo(DateTime apiTime) {
          final now = DateTime.now().toUtc();
          final difference = now.difference(apiTime);

          if (difference.inSeconds < 60) {
            return 'now';
          } else if (difference.inMinutes < 60) {
            return '${difference.inMinutes}m';
          } else if (difference.inHours < 24) {
            return '${difference.inHours}h';
          } else if (difference.inDays < 7) {
            return '${difference.inDays}d';
          } else {
            return '${(difference.inDays / 7).floor()}w';
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView.separated(
            itemCount: controller.archivedChatsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = controller.archivedChatsList[index];

              // Shared by the revealed button and a full swipe past the
              // pane's dismiss threshold - same WhatsApp-style pattern as
              // ChatView's own archive swipe.
              Future<bool> doUnarchive() async {
                final ok = await controller.unarchiveConversation(data.id);
                if (ok) {
                  // Brings it back onto the main Chats list right away,
                  // rather than leaving it missing until the next natural
                  // refresh there.
                  controller.getAllPatientChat();
                  showAppToast(
                    Get.overlayContext!,
                    message: 'Chat unarchived',
                    type: AppToastType.success,
                  );
                } else {
                  showAppToast(
                    Get.overlayContext!,
                    message: 'Failed to unarchive chat. Please try again.',
                    type: AppToastType.error,
                  );
                }
                return ok;
              }

              return Slidable(
                key: ValueKey(data.id),
                endActionPane: ActionPane(
                  motion: const StretchMotion(),
                  extentRatio: 0.28,
                  dismissible: DismissiblePane(
                    onDismissed: () {},
                    confirmDismiss: doUnarchive,
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) => doUnarchive(),
                      backgroundColor: const Color(0xff851653),
                      foregroundColor: Colors.white,
                      icon: Icons.unarchive_outlined,
                      label: 'Unarchive',
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                child: MessageCard(
                  onTap: () {
                    Get.to(() => ChatScreen(conversationId: data.id));
                  },
                  isOnline: data.isOnline == false ? 0 : 1,
                  name: data.name,
                  message: data.message,
                  time: timeAgo(data.time),
                  unreadCount: data.count,
                  avatar:
                      "assets/demos/ce29dbd660832e9f4562a5667afb49dd0e192653.png",
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
