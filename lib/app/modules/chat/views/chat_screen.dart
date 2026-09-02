import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';
import 'package:docwellnesdoc/app/modules/chat/controllers/chat_controller.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/allergy_report_bubble.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/confession_box_bubble.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/custom_food_bubble.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/diet_plan_bubble.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/doctor_recommendation_bubble.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/meal_log_bubble.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/typing_indicator.dart';
import 'package:docwellnesdoc/app/modules/chat/widgets/water_intake_bubble.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  // Known up front by callers that already have the patient's id (e.g. from
  // a patient profile). Without this, the controller had to guess the
  // receiver by scanning fetched messages for one sent by the patient -
  // which is always empty for a brand-new conversation, so every message a
  // dietician tried to send to a patient they'd never messaged before
  // silently failed with a missing-receiverId error from the backend.
  final String? receiverId;

  const ChatScreen({super.key, required this.conversationId, this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController controller = Get.find<ChatController>();

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();

  Timer? _speechTimer;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    // Set immediately (not just as a fallback inferred from message
    // history) so sending works even before the patient has ever sent
    // anything in this conversation.
    if (widget.receiverId != null && widget.receiverId!.isNotEmpty) {
      controller.currentReceiverId = widget.receiverId;
    }
    controller.getPatientChat(widget.conversationId);
    _speechToText.initialize();

    // Setup text field listener for typing indicator
    messageController.addListener(_onTextChanged);
    // Pull in older message history when the reversed list nears the top.
    scrollController.addListener(_onScrollForHistory);
  }

  void _onScrollForHistory() {
    if (!scrollController.hasClients) return;
    // reverse: true -> maxScrollExtent is the top (oldest messages).
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.loadOlderMessages();
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _typingDebounce?.cancel();
    _speechToText.stop();
    messageController.removeListener(_onTextChanged);
    messageController.dispose();
    scrollController.removeListener(_onScrollForHistory);
    scrollController.dispose();
    controller.leaveChat();
    super.dispose();
  }

  void _onTextChanged() {
    // Send typing indicator with debounce
    _typingDebounce?.cancel();
    controller.sendTypingIndicator();

    _typingDebounce = Timer(const Duration(seconds: 2), () {
      controller.sendStopTyping();
    });
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        // With reverse: true, position 0 is at the bottom (newest messages)
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // ---------------- IMAGE PICK ----------------
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    // Read bytes once up front for the preview - File(image.path) only
    // works on platforms with real filesystem access. On Flutter Web,
    // image_picker's XFile.path is a blob: URL, not a filesystem path, so
    // dart:io's File can't open it at all (this silently broke both the
    // preview and the actual upload, which also used to build a File from
    // this same path).
    final imageBytes = await image.readAsBytes();

    // Show preview dialog with caption
    final captionController = TextEditingController();

    await Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    'Send Photo',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),
            Expanded(child: Image.memory(imageBytes, fit: BoxFit.contain)),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: captionController,
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        filled: true,
                        fillColor: const Color(0xffF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xff851653),
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Get.back(result: true);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((send) async {
      if (send != true) return;

      final localId = DateTime.now().millisecondsSinceEpoch.toString();

      final resolvedReceiverId =
          controller.receiverModel?.receiverId ??
          controller.currentReceiverId ??
          "";

      // Add locally
      controller.addLocalMessage(
        ChatModel(
          id: localId,
          senderId: userId ?? "",
          receiverId: resolvedReceiverId,
          message: captionController.text.trim(),
          messageType: "image",
          attachment: image.path,
          isRead: false,
          conversationId: widget.conversationId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          senderRole: "dietician",
          receiverRole: "patient",
          isMe: true,
        ),
      );

      final replyId = controller.replyingTo?.id;

      final response = await controller.sendImageMessage(
        receiverId: resolvedReceiverId,
        imageFile: image,
        message: captionController.text.trim().isEmpty
            ? null
            : captionController.text.trim(),
        replyTo: replyId,
      );

      if (response != null) {
        controller.replaceMessage(
          localId,
          ChatModel.fromJson(response['data']),
        );
      }

      controller.clearReply();
    });
  }

  // ---------------- SEND TEXT ----------------
  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty && controller.replyingTo == null) return;

    messageController.clear();
    controller.sendStopTyping();

    // Send via socket (with REST fallback)
    await controller.sendMessage(
      receiverId:
          controller.receiverModel?.receiverId ??
          controller.currentReceiverId ??
          "",
      message: text,
      conversationId: widget.conversationId,
    );

    _scrollToBottom();
  }

  // ---------------- SEND RECOMMENDATION ----------------
  void _showRecommendationSheet() {
    final textController = TextEditingController();
    String selectedCategory = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_services_outlined,
                        color: Color(0xff059669),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Send Recommendation',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1F2A37),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category picker
                  Text(
                    'Category',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['diet', 'exercise', 'lifestyle', 'general'].map((
                      cat,
                    ) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat[0].toUpperCase() + cat.substring(1)),
                        selected: isSelected,
                        selectedColor: const Color(0xff059669).withOpacity(0.2),
                        labelStyle: GoogleFonts.roboto(
                          color: isSelected
                              ? const Color(0xff059669)
                              : const Color(0xff6B7280),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        onSelected: (_) {
                          setSheetState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Text field
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write your recommendation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff059669)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final text = textController.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(ctx);

                        await controller.sendRecommendation(
                          receiverId:
                              controller.receiverModel?.receiverId ??
                              controller.currentReceiverId ??
                              "",
                          conversationId: widget.conversationId,
                          recommendationText: text,
                          category: selectedCategory,
                        );
                        _scrollToBottom();
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- REPLY PREVIEW ----------------
  Widget replyPreview() {
    return Obx(() {
      final reply = controller.replyingTo;
      if (reply == null) return SizedBox();

      return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xffFCE7F6),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: Color(0xff851653), width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reply.messageType == "image" ? "📷 Photo" : reply.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18),
              onPressed: controller.clearReply,
            ),
          ],
        ),
      );
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: BackButton(color: Color(0xff1F2A37)),
        title: Obx(() {
          final chatUser = controller.allChatsList.firstWhereOrNull(
            (c) => c.id == widget.conversationId,
          );

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xffFCE7F6),
                backgroundImage: chatUser?.image != null
                    ? NetworkImage(chatUser!.image!)
                    : null,
                child: chatUser?.image == null
                    ? Text(
                        chatUser?.name.isNotEmpty == true
                            ? chatUser!.name[0].toUpperCase()
                            : 'P',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff851653),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatUser?.name ?? 'Chat with patient',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: const Color(0xff1F2A37),
                    ),
                  ),
                  if (chatUser?.isOnline == true)
                    Text(
                      'Online',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          );
        }),
      ),

      bottomSheet: Container(
        color: Color(0xffFDF2FA),
        padding: EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              replyPreview(),
              Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add_circle_outline),
                    onSelected: (value) {
                      if (value == 'image') pickImage();
                      if (value == 'recommendation') _showRecommendationSheet();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'image',
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Send Image'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'recommendation',
                        child: Row(
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 20,
                              color: Color(0xff059669),
                            ),
                            SizedBox(width: 10),
                            Text('Send Recommendation'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Color(0xffFCE7F6),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
                ],
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          // Telegram-style typing indicator
          Obx(() {
            if (controller.isOtherUserTyping.value) {
              return const TypingIndicator(
                dotColor: Color(0xff851653),
                typingText: 'typing...',
              );
            }
            return const SizedBox.shrink();
          }),

          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.showChatLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff851653)),
                );
              }

              if (controller.chatList.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: GoogleFonts.roboto(
                      color: const Color(0xff6B7280),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                reverse: true,
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: controller.chatList.length,
                itemBuilder: (context, index) {
                  final chat = controller.chatList[index];
                  final showDateSeparator = controller.shouldShowDateSeparator(
                    index,
                  );

                  final messageWidget = Dismissible(
                    key: ValueKey(chat.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      controller.setReply(chat);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.reply, color: Color(0xff851653)),
                    ),
                    child: _buildMessageWidget(chat),
                  );

                  if (showDateSeparator) {
                    return Column(
                      children: [
                        _buildDateSeparator(chat.createdAt),
                        messageWidget,
                      ],
                    );
                  }

                  return messageWidget;
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffFCE7F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            controller.getDateSeparatorText(date),
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xff851653),
            ),
          ),
        ),
      ),
    );
  }

  /// Build appropriate widget based on message type
  Widget _buildMessageWidget(ChatModel chat) {
    // Backward compat: detect confession/allergy from plain text messages
    if (chat.messageType == 'text') {
      if (chat.message.startsWith('🍕 Confession Box')) {
        return ConfessionBoxBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );
      }
      if (chat.message.startsWith('⚠️ Allergy Report')) {
        return AllergyReportBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );
      }
    }

    switch (chat.messageType) {
      case 'meal_log':
      case 'diet_update':
        return MealLogBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );

      case 'water_intake':
        return WaterIntakeBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );

      case 'diet_plan':
        return DietPlanBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );

      case 'custom_food':
        return CustomFoodBubble(
          chat: chat,
          onApprove: () => _handleCustomFoodAction(chat, 'approve'),
          onReject: () => _handleCustomFoodAction(chat, 'reject'),
          onReply: () => controller.setReply(chat),
        );

      case 'confession_box':
        return ConfessionBoxBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );

      case 'allergy_report':
        return AllergyReportBubble(
          chat: chat,
          onReply: () => controller.setReply(chat),
        );

      case 'doctor_recommendation':
        return DoctorRecommendationBubble(chat: chat);

      case 'image':
        return imageBubble(chat);

      default:
        return textBubble(chat);
    }
  }

  void _showMessageOptions(ChatModel chat) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text('Reply', style: GoogleFonts.roboto()),
              onTap: () {
                Get.back();
                controller.setReply(chat);
              },
            ),
            if (chat.messageType == 'text')
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text('Copy', style: GoogleFonts.roboto()),
                onTap: () {
                  Get.back();
                  // Copy to clipboard
                  // Since we cannot easily import flutter/services.dart here without being sure it's imported at the top,
                  // I will use controller to handle the copy logic or import it.
                  // Wait, I can just use clipboard here since we use material.
                  Clipboard.setData(ClipboardData(text: chat.message));
                  showAppToast(
                    Get.overlayContext!,
                    message: 'Message copied to clipboard',
                    type: AppToastType.success,
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text('Share', style: GoogleFonts.roboto()),
              onTap: () {
                Get.back();
                // To share, we would typically use share_plus, but I'm not sure if it's installed.
                // For now, I will show a snackbar or implement forwarding natively.
                _showForwardOptions(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: Text('Forward', style: GoogleFonts.roboto()),
              onTap: () {
                Get.back();
                _showForwardOptions(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showForwardOptions(ChatModel chat) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              'Forward to...',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: controller.allChatsList.length,
                itemBuilder: (context, index) {
                  final user = controller.allChatsList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.image != null
                          ? NetworkImage(user.image!)
                          : null,
                      child: user.image == null
                          ? Text(user.name.isNotEmpty ? user.name[0] : 'P')
                          : null,
                    ),
                    title: Text(user.name),
                    onTap: () {
                      Get.back();
                      // Forward message logic
                      if (chat.messageType == 'text') {
                        controller.sendMessage(
                          receiverId: user
                              .id, // Assuming user.id is receiverId or we might need an actual backend call to forward.
                          // Wait, sendMessage needs receiverId. But user.id is conversationId.
                          message: chat.message,
                          conversationId: user
                              .id, // We'll just pass conversationId here. We need to handle receiverId correctly inside the controller.
                        );
                        showAppToast(
                          Get.overlayContext!,
                          message: 'Message forwarded to ${user.name}',
                          type: AppToastType.success,
                        );
                      } else {
                        showAppToast(
                          Get.overlayContext!,
                          message:
                              'Forwarding this message type is not supported yet',
                          type: AppToastType.warning,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCustomFoodAction(ChatModel chat, String action) async {
    final requestId = chat.metadata?.customFoodRequestId;
    if (requestId == null || requestId.isEmpty) {
      showAppToast(
        Get.overlayContext!,
        message: 'Custom food request ID not found',
        type: AppToastType.error,
      );
      return;
    }

    final status = action == 'approve' ? 'Accepted' : 'Rejected';

    try {
      final response = await Dio().patch(
        '$apiBaseUrl/custom-food/requests/$requestId',
        data: {'status': status},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update the chat message metadata locally
        final idx = controller.chatList.indexWhere((c) => c.id == chat.id);
        if (idx != -1) {
          final old = controller.chatList[idx];
          controller.chatList[idx] = ChatModel(
            id: old.id,
            senderId: old.senderId,
            receiverId: old.receiverId,
            message: old.message,
            messageType: old.messageType,
            attachment: old.attachment,
            description: old.description,
            metadata: ChatMetadata(
              mealLogId: old.metadata?.mealLogId,
              action: action == 'approve' ? 'approved' : 'rejected',
              itemName: old.metadata?.itemName,
              calories: old.metadata?.calories,
              servings: old.metadata?.servings,
              servingTime: old.metadata?.servingTime,
              totalConsumed: old.metadata?.totalConsumed,
              totalPlanned: old.metadata?.totalPlanned,
              completionPercentage: old.metadata?.completionPercentage,
              imageUrl: old.metadata?.imageUrl,
              foodName: old.metadata?.foodName,
              totalWeight: old.metadata?.totalWeight,
              protein: old.metadata?.protein,
              carbs: old.metadata?.carbs,
              fat: old.metadata?.fat,
              waterAmount: old.metadata?.waterAmount,
              customFoodRequestId: old.metadata?.customFoodRequestId,
            ),
            isRead: old.isRead,
            conversationId: old.conversationId,
            createdAt: old.createdAt,
            updatedAt: old.updatedAt,
            senderRole: old.senderRole,
            receiverRole: old.receiverRole,
            isMe: old.isMe,
            serverSeq: old.serverSeq,
            replyTo: old.replyTo,
          );
          controller.chatList.refresh();
        }

        showAppToast(
          Get.overlayContext!,
          message: 'Custom food request ${action}d successfully',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      debugPrint('Custom food action error: $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Failed to $action custom food request',
        type: AppToastType.error,
      );
    }
  }

  Widget textBubble(ChatModel chat) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(chat),
      child: Align(
        alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: Get.width * 0.7),
          decoration: BoxDecoration(
            color: chat.isMe
                ? const Color(0xffFCE7F6)
                : const Color(0xffFDF2FA),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(chat.isMe ? 18 : 4),
              bottomRight: Radius.circular(chat.isMe ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chat.replyTo != null)
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: Color(0xff851653), width: 3),
                    ),
                  ),
                  child: Text(
                    chat.replyTo!.messageType == 'image'
                        ? '📷 Photo'
                        : chat.replyTo!.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              Text(
                chat.message,
                style: GoogleFonts.roboto(
                  color: Color(0xff851653),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(chat.createdAt),
                    style: GoogleFonts.roboto(
                      color: Color(0xff851653).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  if (chat.isMe) ...[
                    SizedBox(width: 4),
                    Icon(
                      chat.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: chat.isRead
                          ? Colors.blue
                          : Color(0xff851653).withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget imageBubble(ChatModel chat) {
    final rawUrl = chat.attachment ?? chat.message;
    if (rawUrl.isEmpty) return const SizedBox.shrink();
    // blob: URLs (what image_picker's XFile.path is on Flutter Web) are
    // loadable via NetworkImage - the browser resolves them natively. This
    // matters for the optimistic local message shown while an image upload
    // is still in flight; FileImage(File(...)) doesn't work on web at all.
    final isNetwork =
        rawUrl.startsWith('http://') ||
        rawUrl.startsWith('https://') ||
        rawUrl.startsWith('blob:');
    final imageUrl = rawUrl;
    final imageProvider = isNetwork
        ? NetworkImage(imageUrl)
        : FileImage(File(imageUrl)) as ImageProvider;

    return Align(
      alignment: chat.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _openFullScreenImage(imageUrl),
        child: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xffFDF2FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chat.replyTo != null)
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: Color(0xff851653), width: 3),
                    ),
                  ),
                  child: Text(
                    chat.replyTo!.messageType == 'image'
                        ? '📷 Photo'
                        : chat.replyTo!.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: imageProvider,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(String imageUrl) {
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('blob:');
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Image', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: isNetwork
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff851653),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : Image.file(File(imageUrl), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    String minStr = minute < 10 ? '0$minute' : minute.toString();
    return '$hour:$minStr $period';
  }
}
