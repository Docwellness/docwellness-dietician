import 'dart:io';

import 'package:docwellnesdoc/app/modules/performance/controllers/performance_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/youtube_player_screen.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadVideo extends StatelessWidget {
  final ScrollController scrollController;
  UploadVideo({super.key, required this.scrollController});

  final PerformanceController controller = Get.find<PerformanceController>();
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Center(
              child: Container(
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: Color(0xff79747E),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18, left: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  SizedBox(width: 10),
                  CustomText(
                    text: controller.isEditMode.value
                        ? 'Edit Video'
                        : 'Upload Videos',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: Color(0xff1F2A37),
                  ),
                ],
              ),
            ),

            Divider(color: Color(0xff9DA4AE)),
            SizedBox(height: 16),

            // Banner label
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CustomText(
                text: controller.selectedSource.value == 'YouTube'
                    ? 'Thumbnail Preview'
                    : 'Banner',
                fontWeight: FontWeight.w400,
                fontSize: 17,
                color: Color(0xff1F2A37),
              ),
            ),
            SizedBox(height: 6),

            // Banner / YouTube thumbnail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBannerImage(),
            ),
            if (controller.selectedSource.value == 'Device Storage')
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text: 'Upload Video',
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  color: Color(0xff1F2A37),
                ),
              ),
            if (controller.selectedSource.value == 'Device Storage')
              SizedBox(height: 6),
            if (controller.selectedSource.value == 'Device Storage')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => controller.pickVideo(),
                  child: controller.pickedVideo.value == null
                      ? Container(
                          height: 196,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xffFEF6FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/camra.png',
                              height: 48,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: controller.videoThumbnail.value.isNotEmpty
                              ? Image.file(
                                  File(controller.videoThumbnail.value),
                                  width: double.infinity,
                                  height: 196,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  // fallback while thumbnail missing
                                  width: double.infinity,
                                  height: 196,
                                  color: Colors.black12,
                                  child: Center(
                                    child: Text('Video picked — no thumbnail'),
                                  ),
                                ),
                        ),
                ),
              ),
            SizedBox(height: 16),
            if (controller.selectedSource.value == 'YouTube')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomField(
                  controller: controller.youtubeUrlController,
                  lable: 'Video URL',
                  hintText: 'https://youtube.com/watch?v=...',
                  changeBorderColor: false,
                  changeTextColor: Color(0xff4D5761),
                  onChange: (val) => controller.onYoutubeUrlChanged(val ?? ''),
                ),
              ),
            SizedBox(height: 16),
            // Title field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomField(
                controller: controller.videoTitleController,
                lable: 'Video Title',
                hintText: 'Enter video title',
                changeBorderColor: false,
                changeTextColor: Color(0xff4D5761),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.videoTextController,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add description text (optional)',
                  hintStyle: TextStyle(
                    color: Color(0xff9DA4AE),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Color(0xffFEF6FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xffE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xffE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff851653)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomDropdown(
                items: ['YouTube', 'Device Storage'],
                value: controller.selectedSource.value,
                onChanged: (val) {
                  controller.selectedSource.value = val!;
                },
                label: 'Source',
                isRounded: true,
                suffixIconColor: Color(0xff1E1E1E),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'Set Visible to User',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xff384250),
                  ),

                  // Custom switch
                  GestureDetector(
                    onTap: () {
                      controller.isVideoBannerSelected.value =
                          !controller.isVideoBannerSelected.value;
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: 60,
                      height: 31,
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: controller.isVideoBannerSelected.value
                            ? Color(0xff851653)
                            : Colors.transparent,
                        border: Border.all(
                          color: controller.isVideoBannerSelected.value
                              ? Color(0xff851653)
                              : Color(0xffCCCCCC),
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: AnimatedAlign(
                        duration: Duration(milliseconds: 200),
                        alignment: controller.isVideoBannerSelected.value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: controller.isVideoBannerSelected.value
                                ? Colors.white
                                : Color(0xffCCCCCC),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: controller.isVideoSaving.value
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff851653),
                      ),
                    )
                  : CustomButton(
                      onTap: () => controller.isEditMode.value
                          ? controller.updateVideoById()
                          : controller.addVideo(),
                      text: controller.isEditMode.value
                          ? 'Save Changes'
                          : 'Add Video',
                      isOutline: false,
                      fontSize: 14,
                    ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Builds the banner/thumbnail preview image
  Widget _buildBannerImage() {
    // If user picked a custom banner, show it (for both YouTube & Device)
    if (controller.pickedVideoBannerImage.value != null) {
      return GestureDetector(
        onTap: () => controller.pickVideoBannerImage(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(controller.pickedVideoBannerImage.value!.path),
            width: double.infinity,
            height: 196,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // If YouTube source and thumbnail URL available, show it
    if (controller.selectedSource.value == 'YouTube' &&
        controller.youtubeThumbnailUrl.value.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              controller.youtubeThumbnailUrl.value,
              width: double.infinity,
              height: 196,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 196,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xff851653)),
                  ),
                );
              },
              errorBuilder: (context, error, stack) {
                return Container(
                  height: 196,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Color(0xff9DA4AE),
                        ),
                        SizedBox(height: 8),
                        CustomText(
                          text: 'Could not load thumbnail',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff6C737F),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Play icon overlay — opens in-app YouTube player
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    final videoId = controller.extractYoutubeVideoId(
                      controller.youtubeUrl.value,
                    );
                    if (videoId != null) {
                      Get.to(() => YoutubePlayerScreen(videoId: videoId));
                    }
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
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
            ),
            // Tap to change banner
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => controller.pickVideoBannerImage(),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tap to upload custom',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default empty state — tap to pick banner
    return GestureDetector(
      onTap: () => controller.pickVideoBannerImage(),
      child: Container(
        height: 196,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icons/camra.png', height: 48),
              if (controller.selectedSource.value == 'YouTube') ...[
                SizedBox(height: 8),
                CustomText(
                  text: 'Paste YouTube URL to auto-load thumbnail',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff6C737F),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
