import 'dart:io';

import 'package:docwellnesdoc/app/models/activity_log_model.dart';
import 'package:docwellnesdoc/app/models/meal_log_model.dart';
import 'package:docwellnesdoc/app/modules/chat/controllers/chat_logs_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// WhatsApp-style Chat + Logs Screen
/// Combines chat messages with meal logs and activity logs
class ChatLogsScreen extends StatefulWidget {
  final String conversationId;
  final String patientId;
  final String patientName;

  const ChatLogsScreen({
    super.key,
    required this.conversationId,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ChatLogsScreen> createState() => _ChatLogsScreenState();
}

class _ChatLogsScreenState extends State<ChatLogsScreen>
    with SingleTickerProviderStateMixin {
  late ChatLogsController controller;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChatLogsController());
    _tabController = TabController(length: 3, vsync: this);

    controller.loadPatientChatAndLogs(
      conversationId: widget.conversationId,
      patientId: widget.patientId,
      patientName: widget.patientName,
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    final file = File(image.path);
    await controller.sendImageMessage(file);
    _scrollToBottom();
  }

  void _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    await controller.sendTextMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab Bar for filtering
          _buildTabBar(),

          // Date navigation
          _buildDateNavigation(),

          // Chat + Logs list
          Expanded(child: _buildCombinedLogsList()),

          // Reply preview
          _buildReplyPreview(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xffFDF2FA),
      leading: BackButton(color: const Color(0xff1F2A37)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.patientName,
            style: GoogleFonts.roboto(
              color: const Color(0xff1F2A37),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            'Chat & Activity Logs',
            style: GoogleFonts.roboto(
              color: const Color(0xff6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Color(0xff851653)),
          onPressed: _showDatePicker,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xff1F2A37)),
          onSelected: (value) {
            switch (value) {
              case 'add_note':
                _showAddNoteDialog();
                break;
              case 'view_profile':
                // Navigate to patient profile
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'add_note', child: Text('Add Note')),
            const PopupMenuItem(
              value: 'view_profile',
              child: Text('View Profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xffFDF2FA),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xff851653),
        unselectedLabelColor: const Color(0xff6B7280),
        indicatorColor: const Color(0xff851653),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Chat'),
          Tab(text: 'Meals'),
        ],
        onTap: (index) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          border: Border.all(color: const Color(0xffFDF2FA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: controller.previousDate,
              icon: const Icon(Icons.chevron_left, color: Color(0xff851653)),
            ),
            Text(
              controller.formattedSelectedDate,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xff530630),
              ),
            ),
            IconButton(
              onPressed: controller.nextDate,
              icon: const Icon(Icons.chevron_right, color: Color(0xff851653)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedLogsList() {
    return Obx(() {
      if (controller.isLoadingMessages.value ||
          controller.isLoadingActivityLogs.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xff851653)),
        );
      }

      List<ActivityLogModel> logsToShow;

      switch (_tabController.index) {
        case 1: // Chat only
          logsToShow = controller.combinedLogs
              .where((log) => log.type == ActivityLogType.message)
              .toList();
          break;
        case 2: // Meals only
          logsToShow = controller.mealRelatedLogs;
          break;
        default: // All
          logsToShow = controller.combinedLogs;
      }

      if (logsToShow.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _tabController.index == 2
                    ? Icons.restaurant_menu
                    : Icons.chat_bubble_outline,
                size: 64,
                color: const Color(0xffFCCEEF),
              ),
              const SizedBox(height: 16),
              Text(
                _tabController.index == 2
                    ? 'No meals logged for this date'
                    : 'No messages yet',
                style: GoogleFonts.roboto(
                  color: const Color(0xff6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        itemCount: logsToShow.length,
        itemBuilder: (context, index) {
          final log = logsToShow[index];

          // Show date separator if needed
          final showDateSeparator =
              index == 0 ||
              !_isSameDay(logsToShow[index - 1].timestamp, log.timestamp);

          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(log.timestamp),
              _buildLogItem(log),
            ],
          );
        },
      );
    });
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xffE5E7EB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateHeader(date),
              style: GoogleFonts.roboto(
                color: const Color(0xff6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xffE5E7EB))),
        ],
      ),
    );
  }

  Widget _buildLogItem(ActivityLogModel log) {
    switch (log.type) {
      case ActivityLogType.message:
        return _buildMessageBubble(log);
      case ActivityLogType.mealSubmitted:
      case ActivityLogType.mealEdited:
      case ActivityLogType.customMeal:
        return _buildMealLogCard(log);
      default:
        return _buildActivityLogCard(log);
    }
  }

  Widget _buildMessageBubble(ActivityLogModel log) {
    final chat = log.chatMessage!;
    final isMe = chat.isMe;

    return Dismissible(
      key: ValueKey(log.id),
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
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: Get.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xffFCCEEF) : const Color(0xffFDF2FA),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chat.messageType == 'image' && chat.attachment != null)
                _buildImageContent(chat.attachment!),
              if (chat.message.isNotEmpty)
                Text(
                  chat.message,
                  style: GoogleFonts.roboto(
                    color: const Color(0xff1F2A37),
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(chat.createdAt),
                style: GoogleFonts.roboto(
                  color: const Color(0xff9CA3AF),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(String attachment) {
    final imageProvider = attachment.startsWith("http")
        ? NetworkImage(attachment)
        : FileImage(File(attachment)) as ImageProvider;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(image: imageProvider, height: 180, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMealLogCard(ActivityLogModel log) {
    final meal = log.mealLog!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFCCEEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xffFDF2FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(log.typeIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.displayTitle,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff851653),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(log.timestamp),
                        style: GoogleFonts.roboto(
                          color: const Color(0xff9CA3AF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (meal.isEdited)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '✏️ Edited',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: const Color(0xff92400E),
                      ),
                    ),
                  ),
                if (meal.isCustomMeal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🆕 Custom',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: const Color(0xff166534),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Meal content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal image
                if (meal.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      meal.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xffFCCEEF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Color(0xff851653),
                          size: 32,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xffFCCEEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xff851653),
                      size: 32,
                    ),
                  ),
                const SizedBox(width: 12),

                // Meal details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealName,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: const Color(0xff1F2A37),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.mealTypeDisplay,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xff6B7280),
                        ),
                      ),
                      if (meal.calories != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${meal.calories} calories',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: const Color(0xff851653),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (meal.description != null &&
                          meal.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          meal.description!,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: const Color(0xff6B7280),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons for doctor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xffFCCEEF))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showMealFeedbackDialog(meal, approve: true),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Color(0xff166534),
                  ),
                  label: Text(
                    'Approve',
                    style: GoogleFonts.roboto(color: const Color(0xff166534)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () =>
                      _showMealFeedbackDialog(meal, approve: false),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 18,
                    color: Color(0xffDC2626),
                  ),
                  label: Text(
                    'Reject',
                    style: GoogleFonts.roboto(color: const Color(0xffDC2626)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard(ActivityLogModel log) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(log.typeIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.displayTitle,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff1F2A37),
                  ),
                ),
                if (log.description != null)
                  Text(
                    log.description!,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xff6B7280),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(log.timestamp),
            style: GoogleFonts.roboto(
              color: const Color(0xff9CA3AF),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Obx(() {
      final reply = controller.replyingTo;
      if (reply == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xffFCE7F6),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: Color(0xff851653), width: 4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reply.messageType == "image" ? "📷 Photo" : reply.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(color: const Color(0xff1F2A37)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: controller.clearReply,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageInput() {
    return Container(
      color: const Color(0xffFDF2FA),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: const Icon(
                Icons.add_circle_outline,
                color: Color(0xff851653),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xffFCE7F6),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: "Type a message",
                    hintStyle: GoogleFonts.roboto(
                      color: const Color(0xff9CA3AF),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => IconButton(
                icon: controller.isSending.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xff851653),
                        ),
                      )
                    : const Icon(Icons.send, color: Color(0xff851653)),
                onPressed: controller.isSending.value ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  Future<void> _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff851653),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xff1F2A37),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      controller.selectDate(date);
    }
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter note for patient...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xff851653),
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff530630),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (noteController.text.isNotEmpty) {
                await controller.addNote(noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMealFeedbackDialog(MealLogModel meal, {required bool approve}) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Meal' : 'Reject Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal.mealName,
              style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add feedback (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xff851653),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve
                  ? const Color(0xff166534)
                  : const Color(0xffDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (approve) {
                await controller.approveMealLog(
                  meal.id,
                  feedback: feedbackController.text.isNotEmpty
                      ? feedbackController.text
                      : null,
                );
              } else {
                await controller.rejectMealLog(
                  meal.id,
                  feedback: feedbackController.text.isNotEmpty
                      ? feedbackController.text
                      : null,
                );
              }
              Navigator.pop(context);
            },
            child: Text(
              approve ? 'Approve' : 'Reject',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}
