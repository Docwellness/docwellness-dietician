import 'package:docwellnesdoc/app/modules/patient_journey/controllers/patient_timeline_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet for sending an encouragement "nudge" to a patient - a
/// quick-pick list of canned messages, or a custom one. Delivered via
/// POST /api/dietician/nudges (in-app Notification + best-effort live
/// socket + real FCM push - see docwellness-backend's
/// controllers/dietician/timelineController.js::createNudge).
class NudgeSheet extends StatefulWidget {
  final PatientTimelineController controller;
  final String? milestoneId;
  const NudgeSheet({super.key, required this.controller, this.milestoneId});

  @override
  State<NudgeSheet> createState() => _NudgeSheetState();
}

class _NudgeSheetState extends State<NudgeSheet> {
  // 'chat' opens the patient's Chat screen on tap; 'task' (every other
  // canned message, and the custom-text default) opens the Goal Journey
  // milestone sheet instead - see docwellness-backend's
  // timelineController.js::createNudge, which picks the push deep link
  // from this same tag.
  static const _quick = [
    {'message': "Time to log today's meals 🍽️", 'type': 'task'},
    {'message': "Weigh-in due — you're doing great ⚖️", 'type': 'task'},
    {'message': 'Your water goal is waiting 💧', 'type': 'task'},
    {'message': "Let's review your week — free for a chat?", 'type': 'chat'},
  ];
  final _custom = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _send(String message, {String nudgeType = 'task'}) async {
    if (message.trim().isEmpty) return;
    setState(() => _sending = true);
    HapticFeedback.mediumImpact();
    await widget.controller.nudge(
      message: message.trim(),
      milestoneId: widget.milestoneId,
      nudgeType: nudgeType,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffFCE7F6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const CustomText(
              text: 'NUDGE PATIENT',
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: Color(0xffC4547F),
            ),
            const SizedBox(height: 4),
            CustomText(
              text: 'Send to ${widget.controller.patientName}',
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: const Color(0xff530630),
            ),
            const SizedBox(height: 14),
            if (_sent)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CustomText(
                    text: '✓ Nudge sent',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xff1F8A5B),
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quick.map((q) {
                  final message = q['message']!;
                  return GestureDetector(
                    onTap: _sending ? null : () => _send(message, nudgeType: q['type']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xffFDF2FA),
                        border: Border.all(color: const Color(0xffE9C6DC)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        text: message,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: const Color(0xff530630),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _custom,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Custom message…',
                        filled: true,
                        fillColor: const Color(0xffFEF6FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: (_sending || _custom.text.trim().isEmpty) ? null : () => _send(_custom.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _custom.text.trim().isEmpty
                            ? const Color(0xffFCE7F6)
                            : const Color(0xff851653),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
