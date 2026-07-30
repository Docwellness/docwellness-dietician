import 'dart:io';

import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentStatusSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String patientId;
  final String dietPlanId;
  // True when dietPlanId already points at an Active plan (a renewal
  // payment) rather than one still awaiting first activation.
  final bool isRenewal;
  PaymentStatusSheet({
    super.key,
    required this.scrollController,
    required this.patientId,
    required this.dietPlanId,
    this.isRenewal = false,
  }) {
    debugPrint('🔍 PaymentStatusSheet initialized with:');
    debugPrint('   patientId: $patientId');
    debugPrint('   dietPlanId: $dietPlanId');
  }
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final PatientsController controller = Get.find<PatientsController>();

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: Color(0xff4D5761),
        ),
        CustomText(
          text: value,
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          color: valueColor ?? Color(0xff1F2A37),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Payment Screenshot',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff851653),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isProofLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: Color(0xff851653)),
        );
      }
      return _buildPaymentContent(context);
    });
  }

  Widget _buildPaymentContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: Color(0xff79747E),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  SizedBox(width: 14),
                  CustomText(
                    text: 'Payment Details',
                    fontWeight: FontWeight.w400,
                    fontSize: 19,
                    color: Color(0xff1F2A37),
                  ),
                ],
              ),
            ),
            Divider(color: Color(0xff9DA4AE)),
            SizedBox(height: 16),

            // Payment Screenshot Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Payment Screenshot',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xff1F2A37),
                  ),
                  SizedBox(height: 8),
                  Obx(
                    () => GestureDetector(
                      onTap: controller.proofPic.isNotEmpty
                          ? () => _showFullScreenImage(
                              context,
                              controller.proofPic.value,
                            )
                          : controller.pickedPaymentRecip.value == null
                          ? () => controller.pickPaymentRecip()
                          : null,
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xffFEF6FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xffFDF2FA),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: controller.proofPic.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        controller.proofPic.value,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xff851653),
                                                    ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 48,
                                                    color: Color(0xff9DA4AE),
                                                  ),
                                                  SizedBox(height: 8),
                                                  CustomText(
                                                    text: 'Image not available',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                    color: Color(0xff6C737F),
                                                  ),
                                                ],
                                              );
                                            },
                                      ),
                                    )
                                  : controller.pickedPaymentRecip.value == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icons/camra.png',
                                          height: 48,
                                        ),
                                        SizedBox(height: 8),
                                        CustomText(
                                          text: 'No screenshot uploaded',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          color: Color(0xff6C737F),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(
                                          controller
                                              .pickedPaymentRecip
                                              .value!
                                              .path,
                                        ),
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      ),
                                    ),
                            ),
                            // Tap to view indicator
                            if (controller.proofPic.isNotEmpty)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tap to view',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Payment Breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xffF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xffE5E7EB)),
                    boxShadow: cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Payment Breakdown',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xff1F2A37),
                      ),
                      SizedBox(height: 12),
                      if (controller.paymentOriginalAmount.value > 0) ...[
                        _infoRow(
                          'Subscription Amount',
                          '₹${controller.paymentOriginalAmount.value.toInt()}',
                        ),
                        SizedBox(height: 8),
                      ],
                      if (controller.paymentCouponCode.value.isNotEmpty) ...[
                        _infoRow(
                          'Coupon Applied',
                          controller.paymentCouponCode.value,
                          valueColor: Color(0xff851653),
                        ),
                        SizedBox(height: 8),
                      ],
                      if (controller.paymentDiscountPercentage.value > 0) ...[
                        _infoRow(
                          'Discount (${controller.paymentDiscountPercentage.value.toInt()}%)',
                          '-₹${((controller.paymentOriginalAmount.value * controller.paymentDiscountPercentage.value) / 100).toInt()}',
                          valueColor: Color(0xff16A34A),
                        ),
                        SizedBox(height: 8),
                        Divider(color: Color(0xffE5E7EB), height: 1),
                        SizedBox(height: 8),
                      ],
                      _infoRow(
                        'Amount Received',
                        '₹${controller.totalAmount.text.trim()}',
                        isBold: true,
                        valueColor: Color(0xff851653),
                      ),
                      SizedBox(height: 8),
                      _infoRow(
                        'Amount Pending',
                        '₹${controller.pendingAmount.text.trim()}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Patient's Description (read-only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomField(
                controller: controller.paymentDes,
                lable: 'Patient\'s Description',
                maxLines: 3,
                isDisable: true,
              ),
            ),
            SizedBox(height: 16),

            // // Doctor's Note (for rejection)
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: CustomField(
            //     controller: controller.rejectionNoteController,
            //     lable: 'Doctor\'s Note',
            //     hintText: 'Add a note (required for rejection)...',
            //     maxLines: 4,
            //   ),
            // ),
            SizedBox(height: 24),

            // Activate Diet Plan Button - only show if diet plan exists
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: dietPlanId.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xffFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xffFFE69C)),
                        boxShadow: cardShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xff856404),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Diet Plan Required',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff856404),
                                ),
                                SizedBox(height: 4),
                                CustomText(
                                  text:
                                      'Please create and finalize a diet plan before activating.',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff856404),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Renewal: the plan is already active and doesn't
                        // need to change, so just settle the bill. First
                        // activation: the plan is only Finalized so far and
                        // needs the full activate flow to go Active.
                        if (isRenewal)
                          Obx(
                            () => CustomButton(
                              isLoading:
                                  controller.confirmRenewalPaymentLoading.value,
                              onTap: () async {
                                await controller.confirmRenewalPayment(
                                  patientId,
                                );
                              },
                              text: 'Confirm Payment',
                              fontSize: 14,
                              isOutline: false,
                            ),
                          )
                        else
                          Obx(
                            () => CustomButton(
                              isLoading: controller.activateDietPlanLoading.value,
                              onTap: () async {
                                debugPrint('🔘 Accept button tapped!');
                                debugPrint('   patientId: $patientId');
                                debugPrint('   dietPlanId: $dietPlanId');
                                await controller.activateDietPlan(
                                  patientId,
                                  dietPlanId,
                                );
                              },
                              text: 'Confirm & Activate Diet Plan',
                              fontSize: 14,
                              isOutline: false,
                            ),
                          ),
                        // SizedBox(height: 12),
                        // // Reject button
                        // Obx(
                        //   () => SizedBox(
                        //     width: double.infinity,
                        //     height: 48,
                        //     child: OutlinedButton(
                        //       onPressed:
                        //           controller.rejectPaymentLoading.value
                        //           ? null
                        //           : () async {
                        //               if (controller
                        //                   .rejectionNoteController
                        //                   .text
                        //                   .trim()
                        //                   .isEmpty) {
                        //                 Get.snackbar(
                        //                   "Note Required",
                        //                   "Please add a note explaining the rejection reason.",
                        //                   snackPosition:
                        //                       SnackPosition.BOTTOM,
                        //                   backgroundColor: Colors.orange
                        //                       .withValues(alpha: 0.9),
                        //                   colorText: Colors.white,
                        //                   margin: const EdgeInsets.all(
                        //                     12,
                        //                   ),
                        //                   borderRadius: 8,
                        //                   duration: const Duration(
                        //                     seconds: 3,
                        //                   ),
                        //                 );
                        //                 return;
                        //               }
                        //               await controller.rejectPayment(
                        //                 patientId,
                        //               );
                        //             },
                        //       style: OutlinedButton.styleFrom(
                        //         side: BorderSide(
                        //           color: Color(0xffDC2626),
                        //         ),
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(
                        //             12,
                        //           ),
                        //         ),
                        //       ),
                        //       child:
                        //           controller.rejectPaymentLoading.value
                        //           ? SizedBox(
                        //               width: 20,
                        //               height: 20,
                        //               child: CircularProgressIndicator(
                        //                 strokeWidth: 2,
                        //                 color: Color(0xffDC2626),
                        //               ),
                        //             )
                        //           : Text(
                        //               'Reject Payment',
                        //               style: TextStyle(
                        //                 color: Color(0xffDC2626),
                        //                 fontSize: 14,
                        //                 fontWeight: FontWeight.w600,
                        //               ),
                        //             ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
