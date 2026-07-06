import 'package:docwellnesdoc/app/models/patient_request_model.dart';
import 'package:docwellnesdoc/app/modules/chat/controllers/chat_controller.dart';
import 'package:docwellnesdoc/app/modules/chat/services/service.dart';
import 'package:docwellnesdoc/app/modules/chat/views/chat_screen.dart';
import 'package:docwellnesdoc/app/modules/home/controllers/home_controller.dart';
import 'package:docwellnesdoc/app/modules/home/widgets/patient_request_container.dart';
import 'package:docwellnesdoc/app/modules/patients/views/patient_profile_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionDetailsView extends StatelessWidget {
  final String title;
  final int count;

  /// For Pending Payments — full patient request models with status badges
  final List<PatientRequestModel> requestPatients;

  /// For other categories — simple list of {patientId, patientName}
  final List<Map<String, String>> simplePatients;

  /// For Need Attention — history list of patients who were previously flagged
  final List<Map<String, String>> historyPatients;

  const ActionDetailsView({
    super.key,
    required this.title,
    required this.count,
    this.requestPatients = const [],
    this.simplePatients = const [],
    this.historyPatients = const [],
  });

  IconData get _icon {
    switch (title) {
      case 'Messages Received':
        return Icons.chat_bubble_outline_rounded;
      case 'Review Logged Data':
        return Icons.analytics_outlined;
      case 'Clients Close to End':
        return Icons.timer_outlined;
      case 'Did Extremely Well':
        return Icons.emoji_events_outlined;
      case 'Need Attention':
        return Icons.warning_amber_rounded;
      case 'Pending Payments':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String get _description {
    switch (title) {
      case 'Messages Received':
        return 'Messages from patients awaiting your response.';
      case 'Review Logged Data':
        return 'Patients who have logged data for you to review.';
      case 'Clients Close to End':
        return 'Clients whose diet plan is nearing completion.';
      case 'Did Extremely Well':
        return 'Patients who are exceeding their goals — great work!';
      case 'Need Attention':
        return 'Patients who may need a check-in or plan adjustment.';
      case 'Pending Payments':
        return 'Patients with outstanding or submitted payments.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Need Attention uses tabbed layout (Present / History)
    if (title == 'Need Attention') {
      return _NeedAttentionTabbedView(
        title: title,
        count: count,
        icon: _icon,
        description: _description,
        presentPatients: simplePatients,
        historyPatients: historyPatients,
      );
    }

    final bool isMessagesReceived = title == 'Messages Received';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          title,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: const Color(0xff1F2A37),
          ),
        ),
      ),
      body: Builder(
        builder: (_) {
          Widget buildBody(
            int effectiveCount,
            List<Map<String, String>> effectiveSimplePatients,
          ) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Stat header card ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF6FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFCE7F6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xffFDF2FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xffFCE7F6)),
                          ),
                          child: Icon(
                            _icon,
                            size: 28,
                            color: const Color(0xff851653),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: '$effectiveCount',
                                fontWeight: FontWeight.w600,
                                fontSize: 28,
                                color: const Color(0xff530630),
                              ),
                              const SizedBox(height: 2),
                              CustomText(
                                text: _description,
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                color: const Color(0xff851653),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Patient list (for Pending Payments — full request cards) ---
                  if (requestPatients.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    CustomText(
                      text: 'Patients',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: const Color(0xff530630),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      itemCount: requestPatients.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final p = requestPatients[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PatientRequestContainer(
                            title: p.patientName ?? 'Patient',
                            goal: p.primaryGoal ?? '',
                            status: p.status ?? 'Unpaid',
                            avatarUrl: p.avatarUrl,
                            onTap: () {
                              Get.to(
                                () => PatientProfileView(
                                  patientId: p.patientId ?? '',
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  // --- Patient list (for other categories — simple name cards) ---
                  if (effectiveSimplePatients.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    CustomText(
                      text: 'Patients',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: const Color(0xff530630),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      itemCount: effectiveSimplePatients.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final p = effectiveSimplePatients[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PatientTile(
                            name: p['patientName'] ?? 'Patient',
                            onTap: () {
                              final id = p['patientId'] ?? '';
                              if (id.isNotEmpty) {
                                if (isMessagesReceived) {
                                  _openChatWithPatient(id);
                                } else {
                                  Get.to(
                                    () => PatientProfileView(patientId: id),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],

                  // --- Empty state when count is zero ---
                  if (effectiveCount == 0 &&
                      requestPatients.isEmpty &&
                      effectiveSimplePatients.isEmpty) ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Icon(_icon, size: 64, color: const Color(0xffFCE7F6)),
                          const SizedBox(height: 16),
                          CustomText(
                            text: 'Nothing here right now',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: const Color(0xff530630),
                          ),
                          const SizedBox(height: 4),
                          const CustomText(
                            text: 'You\'re all caught up!',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xff851653),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          // For Messages Received, use reactive data from HomeController
          if (isMessagesReceived) {
            final homeController = Get.find<HomeController>();
            return Obx(
              () => buildBody(
                homeController.messagesReceived.value,
                homeController.messagesReceivedPatients.toList(),
              ),
            );
          }

          // For other categories, use static data passed via constructor
          return buildBody(count, simplePatients);
        },
      ),
    );
  }

  Future<void> _openChatWithPatient(String patientId) async {
    Get.put(ChatController());
    final chatService = ChatService();
    final conversationId = await chatService.getOrCreateConversation(patientId);
    if (conversationId != null && conversationId.isNotEmpty) {
      Get.to(() => ChatScreen(conversationId: conversationId));
      // Refresh dashboard stats after opening chat (marks as read)
      try {
        final hc = Get.find<HomeController>();
        Future.delayed(
          const Duration(seconds: 2),
          () => hc.fetchDashboardStats(),
        );
      } catch (_) {}
    } else {
      Get.snackbar(
        'Error',
        'Could not open chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _PatientTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _PatientTile({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xffFCE7F6)),
              ),
              child: Center(
                child: CustomText(
                  text: name.isNotEmpty ? name[0].toUpperCase() : '?',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: const Color(0xff851653),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                text: name,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: const Color(0xff1F2A37),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xff851653),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tabbed view for Need Attention — Present + History
class _NeedAttentionTabbedView extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final String description;
  final List<Map<String, String>> presentPatients;
  final List<Map<String, String>> historyPatients;

  const _NeedAttentionTabbedView({
    required this.title,
    required this.count,
    required this.icon,
    required this.description,
    required this.presentPatients,
    required this.historyPatients,
  });

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xffFDF2FA),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
            onPressed: () => Get.back(),
          ),
          title: Text(
            title,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w400,
              color: const Color(0xff1F2A37),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Obx(
              () => TabBar(
                indicatorColor: const Color(0xff851653),
                labelColor: const Color(0xff851653),
                unselectedLabelColor: const Color(0xff9CA3AF),
                labelStyle: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    text:
                        'Present (${homeController.needAttentionPatients.length})',
                  ),
                  Tab(
                    text:
                        'History (${homeController.needAttentionHistory.length})',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Obx(
              () => _buildPatientTab(
                homeController.needAttentionPatients.toList(),
                isHistory: false,
                homeController: homeController,
              ),
            ),
            Obx(
              () => _buildPatientTab(
                homeController.needAttentionHistory.toList(),
                isHistory: true,
                homeController: homeController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTab(
    List<Map<String, String>> patients, {
    required bool isHistory,
    required HomeController homeController,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xffFEF6FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFCE7F6)),
            ),
            child: Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xffFDF2FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffFCE7F6)),
                  ),
                  child: Icon(
                    isHistory ? Icons.history_rounded : icon,
                    size: 28,
                    color: const Color(0xff851653),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: '${patients.length}',
                        fontWeight: FontWeight.w600,
                        fontSize: 28,
                        color: const Color(0xff530630),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        text: isHistory
                            ? 'Previously flagged patients who improved.'
                            : description,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: const Color(0xff851653),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (patients.isNotEmpty) ...[
            const SizedBox(height: 24),
            CustomText(
              text: isHistory ? 'History' : 'Patients',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: const Color(0xff530630),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: patients.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final p = patients[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PatientTile(
                    name: p['patientName'] ?? 'Patient',
                    onTap: () async {
                      final id = p['patientId'] ?? '';
                      if (id.isNotEmpty) {
                        // Mark as read when opening from Present tab
                        if (!isHistory) {
                          homeController.acknowledgeNeedAttention(id);
                        }
                        Get.to(() => PatientProfileView(patientId: id));
                      }
                    },
                  ),
                );
              },
            ),
          ],

          if (patients.isEmpty) ...[
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Icon(
                    isHistory ? Icons.history_rounded : icon,
                    size: 64,
                    color: const Color(0xffFCE7F6),
                  ),
                  const SizedBox(height: 16),
                  CustomText(
                    text: isHistory
                        ? 'No history yet'
                        : 'Nothing here right now',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: const Color(0xff530630),
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: isHistory
                        ? 'Resolved patients will appear here.'
                        : 'You\'re all caught up!',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: const Color(0xff851653),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
