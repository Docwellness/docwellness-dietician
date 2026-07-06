import 'package:docwellnesdoc/app/modules/chat/views/chat_screen.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/chat_info_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        elevation: 0,
        title: Text(
          'Chats',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xff1F2A37),
          ),
        ),
      ),
      body: Obx(
        () => controller.showAllChatLoading.value
            ? Center(child: CircularProgressIndicator(
               color: Color(0xff851653),
            ))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffFCFCFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffF3E8F0), width: 1),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/icons/vector(2).png',
                              height: 15,
                              width: 15,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          hintText: 'Search patients...',
                          hintStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xffBBA5B5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: controller.allChatsList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data = controller.allChatsList[index];
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

                          return MessageCard(
                            onTap: () {
                              Get.to(() => ChatScreen(conversationId: data.id,));
                            },
                            isOnline: data.isOnline == false ? 0 : 1,
                            name: data.name,
                            message: data.message,
                            time: timeAgo(data.time),
                            unreadCount: data.count,
                            avatar:
                                "assets/demos/ce29dbd660832e9f4562a5667afb49dd0e192653.png",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
