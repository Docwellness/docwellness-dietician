import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/modules/performance/views/consultation_form_builder_view.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/add_coupon_sheet.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/add_update_quotes.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/patients_line_chart.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/revenue_line_chart.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/upload_video.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/youtube_player_screen.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/performance_controller.dart';

class PerformanceView extends GetView<PerformanceController> {
  const PerformanceView({super.key});

  String _formatInt(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int fromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void _openCouponSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 1,
          maxChildSize: 1,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return AddCouponSheet(scrollController: scrollController);
          },
        );
      },
    );
  }

  String _formatCurrency(double value) {
    return '\$${_formatInt(value.round())}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        title: CustomText(
          text: 'Performance',
          fontWeight: FontWeight.w400,
          fontSize: 21,
          color: Color(0xff1F2A37),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: PatientCard(
                        values: controller.patientsTrend,
                        totalPatientsText: _formatInt(
                          controller.totalPatients.value,
                        ),
                        changePercent: controller.patientsChangePercent.value,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: RevenueLineChart(
                        values: controller.revenueTrend,
                        totalRevenueText: _formatCurrency(
                          controller.totalRevenue.value,
                        ),
                        changePercent: controller.revenueChangePercent.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomText(
                text: 'Discounts & Coupons',
                fontWeight: FontWeight.w400,
                fontSize: 17,
                color: Color(0xff530630),
              ),
            ),
            SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => controller.isCouponsLoading.value
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xff851653),
                          ),
                        ),
                      )
                    : controller.couponsList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CustomText(
                            text: 'No coupons yet',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xff9DA4AE),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.couponsList.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final coupon = controller.couponsList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xffFEF6FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.only(
                                left: 16,
                                top: 12,
                                bottom: 12,
                                right: 9,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/a497facdd8d00bcb90521a8f41d608f0f294b8d9.jpg',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 5),
                                        CustomText(
                                          text: coupon['name'] ?? '',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                          color: Color(0xff1F2A37),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 7),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: Color(0xffFDF2FA),
                                            border: Border.all(
                                              color: Color(0xffFCE7F6),
                                            ),
                                          ),
                                          child: CustomText(
                                            text: coupon['code'] ?? '',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Color(0xffEF45B2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      controller.prefillForCouponEdit(coupon);
                                      _openCouponSheet(context);
                                    },
                                    icon: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xff851653),
                                      size: 21,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),

              child: CustomButton(
                onTap: () {
                  controller.resetCouponForm();
                  _openCouponSheet(context);
                },
                text: 'Add New Coupon',
                isOutline: false,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 32),

            // ── Customize Consultation Section ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomText(
                text: 'Customize Consultation',
                fontWeight: FontWeight.w400,
                fontSize: 17,
                color: Color(0xff530630),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF6FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffFAA7E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xff851653),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              CustomText(
                                text: 'First Consultation Form',
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Color(0xff1F2A37),
                              ),
                              SizedBox(height: 2),
                              CustomText(
                                text:
                                    'Add your own questions, choices and required fields. They will appear on every patient\u2019s first consultation.',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Color(0xff6C737F),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      onTap: () {
                        Get.to(() => ConsultationFormBuilderView());
                      },
                      text: 'Customize Consultation',
                      isOutline: false,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CustomText(
                    text: 'Videos for Clients',
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: Color(0xff9F1561),
                  ),
                  SizedBox(width: 15),
                  Icon(Icons.arrow_forward, color: Color(0xff530630), size: 21),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 6),
              child: Container(
                padding: EdgeInsets.only(bottom: 8, top: 8, left: 16),
                height: 449,
                width: double.infinity,
                color: Color(0xffFEF6FB),
                child: Obx(
                  () => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // "Add More Videos" card (always first)
                      Container(
                        height: 433,
                        width: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color(0xffF3F4F6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              child: CustomText(
                                text: 'Add More Videos',
                                fontWeight: FontWeight.w400,
                                fontSize: 24,
                                color: Color(0xff1F2A37),
                                textAlign: TextAlign.center,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 39.51),
                            GestureDetector(
                              onTap: () {
                                controller.resetUploadForm();
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  useSafeArea: true,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) {
                                    return DraggableScrollableSheet(
                                      initialChildSize: 1,
                                      maxChildSize: 1,
                                      minChildSize: 0.5,
                                      expand: false,
                                      builder: (context, scrollController) {
                                        return UploadVideo(
                                          scrollController: scrollController,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Color(0xffFCFCFD),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(0xffF3F4F6)),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xffEF45B2),
                                    size: 40,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Real videos from API
                      if (controller.isVideosLoading.value)
                        Container(
                          width: 240,
                          height: 433,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: Color(0xff851653),
                          ),
                        )
                      else
                        ...controller.videosList.map((video) {
                          final thumbUrl = _getVideoThumbnail(video);
                          final title = (video['title'] as String?) ?? '';
                          final videoId = video['_id'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                final source = video['source'] as String? ?? '';
                                if (source == 'YouTube') {
                                  final ytId = controller.extractYoutubeVideoId(
                                    video['youtubeUrl'] ?? '',
                                  );
                                  if (ytId != null) {
                                    Get.to(
                                      () => YoutubePlayerScreen(
                                        videoId: ytId,
                                        title: title,
                                      ),
                                    );
                                  }
                                }
                              },
                              onLongPress: () {
                                // Show options bottom sheet
                                final isVisible =
                                    video['visibleToUser'] == true;
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 4,
                                            width: 32,
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xff79747E),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                          // Edit
                                          ListTile(
                                            leading: Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xff851653),
                                            ),
                                            title: Text('Edit Video'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              controller.prefillForEdit(video);
                                              showModalBottomSheet(
                                                context: context,
                                                backgroundColor: Colors.white,
                                                useSafeArea: true,
                                                isScrollControlled: true,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                    ),
                                                builder: (context) {
                                                  return DraggableScrollableSheet(
                                                    initialChildSize: 1,
                                                    maxChildSize: 1,
                                                    minChildSize: 0.5,
                                                    expand: false,
                                                    builder:
                                                        (
                                                          context,
                                                          scrollController,
                                                        ) {
                                                          return UploadVideo(
                                                            scrollController:
                                                                scrollController,
                                                          );
                                                        },
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          // Toggle Visibility
                                          ListTile(
                                            leading: Icon(
                                              isVisible
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Color(0xff851653),
                                            ),
                                            title: Text(
                                              isVisible
                                                  ? 'Hide from Patients'
                                                  : 'Show to Patients',
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              controller.toggleVideoVisibility(
                                                videoId,
                                                isVisible,
                                              );
                                            },
                                          ),
                                          const Divider(),
                                          // Delete
                                          ListTile(
                                            leading: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              'Delete Video',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Get.defaultDialog(
                                                title: 'Delete Video',
                                                middleText:
                                                    'Are you sure you want to delete this video?',
                                                textConfirm: 'Delete',
                                                textCancel: 'Cancel',
                                                confirmTextColor: Colors.white,
                                                buttonColor: Colors.red,
                                                onConfirm: () {
                                                  Get.back();
                                                  controller.deleteVideoById(
                                                    videoId,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 433,
                                width: 236,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black12,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: thumbUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: thumbUrl,
                                              width: 236,
                                              height: 433,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xff851653),
                                                    ),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color: Color(0xff9DA4AE),
                                                    ),
                                                  ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.videocam_outlined,
                                                size: 48,
                                                color: Color(0xff9DA4AE),
                                              ),
                                            ),
                                    ),
                                    // Gradient overlay
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Play icon for YouTube
                                    if (video['source'] == 'YouTube')
                                      Positioned.fill(
                                        child: Center(
                                          child: Container(
                                            height: 48,
                                            width: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Title + visibility badge
                                    if (title.isNotEmpty)
                                      Positioned(
                                        left: 12,
                                        bottom: 16,
                                        right: 12,
                                        child: CustomText(
                                          text: title,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    // Visibility indicator
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  video['visibleToUser'] == true
                                                  ? Color(0xff851653)
                                                  : Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              video['visibleToUser'] == true
                                                  ? 'Visible'
                                                  : 'Hidden',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // More options button
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          final isVisible =
                                              video['visibleToUser'] == true;
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                            ),
                                            builder: (_) => SafeArea(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      height: 4,
                                                      width: 32,
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          0xff79747E,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                        Icons.edit_outlined,
                                                        color: Color(
                                                          0xff851653,
                                                        ),
                                                      ),
                                                      title: Text('Edit Video'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        controller
                                                            .prefillForEdit(
                                                              video,
                                                            );
                                                        showModalBottomSheet(
                                                          context: context,
                                                          backgroundColor:
                                                              Colors.white,
                                                          useSafeArea: true,
                                                          isScrollControlled:
                                                              true,
                                                          shape: const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                  top:
                                                                      Radius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                          ),
                                                          builder: (context) {
                                                            return DraggableScrollableSheet(
                                                              initialChildSize:
                                                                  1,
                                                              maxChildSize: 1,
                                                              minChildSize: 0.5,
                                                              expand: false,
                                                              builder:
                                                                  (
                                                                    context,
                                                                    scrollController,
                                                                  ) {
                                                                    return UploadVideo(
                                                                      scrollController:
                                                                          scrollController,
                                                                    );
                                                                  },
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: Icon(
                                                        isVisible
                                                            ? Icons
                                                                  .visibility_off_outlined
                                                            : Icons
                                                                  .visibility_outlined,
                                                        color: Color(
                                                          0xff851653,
                                                        ),
                                                      ),
                                                      title: Text(
                                                        isVisible
                                                            ? 'Hide from Patients'
                                                            : 'Show to Patients',
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        controller
                                                            .toggleVideoVisibility(
                                                              videoId,
                                                              isVisible,
                                                            );
                                                      },
                                                    ),
                                                    const Divider(),
                                                    ListTile(
                                                      leading: Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                      ),
                                                      title: Text(
                                                        'Delete Video',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        Get.defaultDialog(
                                                          title: 'Delete Video',
                                                          middleText:
                                                              'Are you sure you want to delete this video?',
                                                          textConfirm: 'Delete',
                                                          textCancel: 'Cancel',
                                                          confirmTextColor:
                                                              Colors.white,
                                                          buttonColor:
                                                              Colors.red,
                                                          onConfirm: () {
                                                            Get.back();
                                                            controller
                                                                .deleteVideoById(
                                                                  videoId,
                                                                );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 28,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.more_vert,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CustomText(
                    text: 'Quotes',
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: Color(0xff9F1561),
                  ),
                  SizedBox(width: 15),
                  Icon(Icons.arrow_forward, color: Color(0xff530630), size: 21),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 5),
              child: SizedBox(
                height: 137,

                child: Obx(
                  () => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Container(
                        height: 137,
                        width: 132,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color(0xffFDF2FA),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                controller.resetQuoteForm();
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  useSafeArea: true,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) {
                                    return DraggableScrollableSheet(
                                      initialChildSize: 1,
                                      maxChildSize: 1,
                                      minChildSize: 0.5,
                                      expand: false,
                                      builder: (context, scrollController) {
                                        return AddUpdateQuotes(
                                          scrollController: scrollController,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Color(0xffFCFCFD),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(0xffF3F4F6)),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xffEF45B2),
                                    size: 40,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Dynamic quotes from API
                      if (controller.isQuotesLoading.value)
                        Container(
                          width: 132,
                          height: 137,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: Color(0xff851653),
                          ),
                        )
                      else
                        ...controller.quotesList.map((quote) {
                          final quoteId = quote['_id'] as String? ?? '';
                          final imageUrl = quote['imageUrl'] as String? ?? '';
                          final isActive = quote['isActive'] == true;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onLongPress: () {
                                // Show options bottom sheet
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 4,
                                            width: 32,
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xff79747E),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                          // Edit
                                          ListTile(
                                            leading: Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xff851653),
                                            ),
                                            title: Text('Edit Quote'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              controller.prefillForQuoteEdit(
                                                quote,
                                              );
                                              showModalBottomSheet(
                                                context: context,
                                                backgroundColor: Colors.white,
                                                useSafeArea: true,
                                                isScrollControlled: true,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                    ),
                                                builder: (context) {
                                                  return DraggableScrollableSheet(
                                                    initialChildSize: 1,
                                                    maxChildSize: 1,
                                                    minChildSize: 0.5,
                                                    expand: false,
                                                    builder:
                                                        (
                                                          context,
                                                          scrollController,
                                                        ) {
                                                          return AddUpdateQuotes(
                                                            scrollController:
                                                                scrollController,
                                                          );
                                                        },
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          // Toggle Active
                                          ListTile(
                                            leading: Icon(
                                              isActive
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Color(0xff851653),
                                            ),
                                            title: Text(
                                              isActive
                                                  ? 'Set Inactive'
                                                  : 'Set Active',
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              controller.toggleQuoteActive(
                                                quoteId,
                                                isActive,
                                              );
                                            },
                                          ),
                                          const Divider(),
                                          // Delete
                                          ListTile(
                                            leading: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              'Delete Quote',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Get.defaultDialog(
                                                title: 'Delete Quote',
                                                middleText:
                                                    'Are you sure you want to delete this quote?',
                                                textConfirm: 'Delete',
                                                textCancel: 'Cancel',
                                                confirmTextColor: Colors.white,
                                                buttonColor: Colors.red,
                                                onConfirm: () {
                                                  Get.back();
                                                  controller.deleteQuoteById(
                                                    quoteId,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    height: 137,
                                    width: 132,
                                    decoration: BoxDecoration(
                                      color: Color(0xffFDF2FA),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: imageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                height: 120,
                                                width: 116.97,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Color(
                                                          0xff851653,
                                                        ),
                                                      ),
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 32,
                                                        color: Color(
                                                          0xff9DA4AE,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                            : Icon(
                                                Icons.format_quote_outlined,
                                                size: 32,
                                                color: Color(0xff9DA4AE),
                                              ),
                                      ),
                                    ),
                                  ),
                                  // Active/Inactive badge
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Color(0xff851653)
                                            : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Hidden',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // More options button
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (_) => SafeArea(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height: 4,
                                                    width: 32,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xff79747E),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            100,
                                                          ),
                                                    ),
                                                  ),
                                                  ListTile(
                                                    leading: Icon(
                                                      Icons.edit_outlined,
                                                      color: Color(0xff851653),
                                                    ),
                                                    title: Text('Edit Quote'),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      controller
                                                          .prefillForQuoteEdit(
                                                            quote,
                                                          );
                                                      showModalBottomSheet(
                                                        context: context,
                                                        backgroundColor:
                                                            Colors.white,
                                                        useSafeArea: true,
                                                        isScrollControlled:
                                                            true,
                                                        shape: const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      20,
                                                                    ),
                                                              ),
                                                        ),
                                                        builder: (context) {
                                                          return DraggableScrollableSheet(
                                                            initialChildSize: 1,
                                                            maxChildSize: 1,
                                                            minChildSize: 0.5,
                                                            expand: false,
                                                            builder:
                                                                (
                                                                  context,
                                                                  scrollController,
                                                                ) {
                                                                  return AddUpdateQuotes(
                                                                    scrollController:
                                                                        scrollController,
                                                                  );
                                                                },
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: Icon(
                                                      isActive
                                                          ? Icons
                                                                .visibility_off_outlined
                                                          : Icons
                                                                .visibility_outlined,
                                                      color: Color(0xff851653),
                                                    ),
                                                    title: Text(
                                                      isActive
                                                          ? 'Set Inactive'
                                                          : 'Set Active',
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      controller
                                                          .toggleQuoteActive(
                                                            quoteId,
                                                            isActive,
                                                          );
                                                    },
                                                  ),
                                                  const Divider(),
                                                  ListTile(
                                                    leading: Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    title: Text(
                                                      'Delete Quote',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      Get.defaultDialog(
                                                        title: 'Delete Quote',
                                                        middleText:
                                                            'Are you sure you want to delete this quote?',
                                                        textConfirm: 'Delete',
                                                        textCancel: 'Cancel',
                                                        confirmTextColor:
                                                            Colors.white,
                                                        buttonColor: Colors.red,
                                                        onConfirm: () {
                                                          Get.back();
                                                          controller
                                                              .deleteQuoteById(
                                                                quoteId,
                                                              );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 22,
                                        width: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 235,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xffFEF6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 17),

                      Image.asset(
                        'assets/images/badge.png',
                        height: 97.66,
                        width: 77.15,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 25.5),

                      CustomText(
                        text: 'AI Suggestion',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Color(0xff530630),
                      ),
                      SizedBox(height: 1),
                      SizedBox(
                        width: 235,
                        child: CustomText(
                          text:
                              '80% of patients achieved their first-week goal. You got this!',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xff851653),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.5),
          ],
        ),
      ),
    );
  }

  /// Get the best available thumbnail URL for a video
  String _getVideoThumbnail(Map<String, dynamic> video) {
    // YouTube thumbnailUrl is a full URL
    final thumbUrl = video['thumbnailUrl'] as String? ?? '';
    if (thumbUrl.isNotEmpty && thumbUrl.startsWith('http')) return thumbUrl;

    // bannerImage is a server path like /uploads/xxx.jpg
    final banner = video['bannerImage'] as String? ?? '';
    if (banner.isNotEmpty) {
      // Build full URL from apiBaseUrl (strip /api/dietician)
      final serverRoot = apiBaseUrl.replaceAll(RegExp(r'/api/dietician$'), '');
      return '$serverRoot$banner';
    }

    return thumbUrl;
  }
}
