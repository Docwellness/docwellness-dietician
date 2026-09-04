import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/membership_badge.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One collapsed-by-default row in the Payment Information history list -
/// a renewed patient has one of these per cycle (see
/// PatientProfileModel.paymentHistory), newest first. Tapping expands it in
/// place to the same Plan/Amount/note detail [body] the single-cycle view
/// already used, so nothing about that content had to change - only how
/// many of it can be on screen, each dated and independently collapsible.
class PaymentHistoryRow extends StatefulWidget {
  final PaymentHistoryEntry entry;
  final Widget statusChip;
  final Widget body;
  final bool initiallyExpanded;

  const PaymentHistoryRow({
    super.key,
    required this.entry,
    required this.statusChip,
    required this.body,
    this.initiallyExpanded = false,
  });

  @override
  State<PaymentHistoryRow> createState() => _PaymentHistoryRowState();
}

class _PaymentHistoryRowState extends State<PaymentHistoryRow> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final badge = membershipBadgeStyle(entry.membershipPlan);
    final dateLabel =
        entry.date != null ? DateFormat('dd MMM yyyy').format(entry.date!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? badge.border : const Color(0xffF3D9EA),
          width: _expanded ? 1.3 : 1,
        ),
        boxShadow: cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: badge.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: badge.border),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: badge.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: CustomText(
                                  text: badge.label.isNotEmpty
                                      ? '${badge.label} Membership'
                                      : (entry.membershipPlan ?? 'Membership'),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: const Color(0xff1F2A37),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (entry.isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xffBBF7D0)),
                                  ),
                                  child: const CustomText(
                                    text: 'CURRENT',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                    color: Color(0xff16A34A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (dateLabel != null) ...[
                            const SizedBox(height: 2),
                            CustomText(
                              text: entry.isCurrent
                                  ? 'Started $dateLabel'
                                  : dateLabel,
                              fontWeight: FontWeight.w400,
                              fontSize: 11.5,
                              color: const Color(0xff9DA4AE),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    widget.statusChip,
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xff9DA4AE),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.body,
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
