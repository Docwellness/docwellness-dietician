import 'dart:io';

import 'package:docwellnesdoc/app/modules/home/controllers/doctor_profile_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorProfileView extends StatelessWidget {
  DoctorProfileView({super.key});

  final DoctorProfileController controller = Get.put(DoctorProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xff851653)),
            tooltip: 'Log out',
            onPressed: () {
              Get.defaultDialog(
                title: 'Log Out',
                middleText: 'Are you sure you want to log out?',
                textConfirm: 'Log Out',
                textCancel: 'Cancel',
                confirmTextColor: Colors.white,
                buttonColor: const Color(0xff851653),
                onConfirm: () {
                  Get.back();
                  controller.logout();
                },
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.profile.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff851653)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              GestureDetector(
                onTap: controller.pickAndUploadImage,
                child: Stack(
                  children: [
                    Obx(
                      () => CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xffFDF2FA),
                        backgroundImage:
                            controller.profileImageUrl.value.isNotEmpty
                            ? NetworkImage(controller.profileImageUrl.value)
                            : null,
                        child: controller.profileImageUrl.value.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xff851653),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xff851653),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              CustomText(
                text: 'Tap to change photo',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Colors.grey,
              ),

              const SizedBox(height: 24),

              // Title
              Obx(
                () => CustomDropdown(
                  label: 'Title',
                  items: DoctorProfileController.titlePrefixOptions,
                  value: controller.selectedTitlePrefix.value,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedTitlePrefix.value = value;
                    }
                  },
                  isRounded: true,
                  suffixIconColor: const Color(0xff851653),
                ),
              ),

              const SizedBox(height: 16),

              // Full Name
              CustomField(
                lable: 'Full Name',
                controller: controller.nameController,
                hintText: 'Enter your full name',
              ),

              const SizedBox(height: 16),

              // Date of Birth
              GestureDetector(
                onTap: () => controller.pickDate(context),
                child: AbsorbPointer(
                  child: CustomField(
                    lable: 'Date of Birth',
                    controller: controller.dobController,
                    hintText: 'DD-MM-YYYY',
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: Color(0xff851653),
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gender
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  text: 'Gender',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: const Color(0xff1F2A37),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final isSelected = controller.selectedGender.value == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: isSelected,
                        selectedColor: const Color(0xffFDF2FA),
                        backgroundColor: Colors.white,
                        // Unselected options must still read as enabled/
                        // tappable, not disabled - previously
                        // Colors.grey/grey.shade300 (very light, washed-out)
                        // made Male/Other look inactive next to whichever
                        // option was actually selected. Uses the same
                        // neutral text/border colors as the rest of this
                        // form (0xff1F2A37 heading text, 0xffD0D5DD border)
                        // so all three read as equally selectable by
                        // default, with only the selected one getting the
                        // brand-colored border/checkmark/fill.
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xff851653)
                              : const Color(0xffD0D5DD),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xff851653)
                              : const Color(0xff1F2A37),
                        ),
                        onSelected: (_) => controller.selectedGender.value = g,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Specialization
              CustomField(
                lable: 'Specialization',
                controller: controller.specializationController,
                hintText: 'e.g. Nutrition Expert',
              ),

              const SizedBox(height: 16),

              // Experience
              CustomField(
                lable: 'Experience (years)',
                controller: controller.experienceController,
                hintText: 'e.g. 10',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Qualification
              CustomField(
                lable: 'Qualification',
                controller: controller.qualificationController,
                hintText: 'e.g. MSc in Nutrition',
              ),

              const SizedBox(height: 16),

              // Bio / Description
              CustomField(
                lable: 'About / Description',
                controller: controller.bioController,
                hintText: 'Tell patients about yourself...',
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              // Save Button
              Obx(
                () => CustomButton(
                  text: 'Save Profile',
                  isOutline: false,
                  isLoading: controller.isSaving.value,
                  onTap: controller.saveProfile,
                ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  text: 'Add Post',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: const Color(0xff1F2A37),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: controller.pickPostImage,
                child: Obx(
                  () => Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF6FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffF3D9E9)),
                    ),
                    child: controller.pickedPostImage.value == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: Color(0xff851653),
                                size: 34,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select post image',
                                style: TextStyle(
                                  color: Color(0xff6C737F),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(controller.pickedPostImage.value!.path),
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              CustomField(
                lable: 'Caption (optional)',
                controller: controller.postTextController,
                hintText: 'Write something about this post...',
                maxLines: 3,
              ),

              const SizedBox(height: 10),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomText(
                      text: 'Visible to patients',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xff1F2A37),
                    ),
                    Switch(
                      value: controller.isPostActive.value,
                      activeThumbColor: const Color(0xff851653),
                      onChanged: (v) => controller.isPostActive.value = v,
                    ),
                  ],
                ),
              ),

              Obx(
                () => CustomButton(
                  text: 'Add Post',
                  isOutline: true,
                  isLoading: controller.isPostSaving.value,
                  onTap: controller.addPost,
                ),
              ),

              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  text: 'Your Posts',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: const Color(0xff1F2A37),
                ),
              ),
              const SizedBox(height: 10),

              Obx(() {
                if (controller.isPostsLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff851653),
                      ),
                    ),
                  );
                }

                if (controller.posts.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF6FB),
                      borderRadius: BorderRadius.circular(12),
                      border: cardBorder,
                      boxShadow: cardShadow,
                    ),
                    child: const CustomText(
                      text: 'No posts yet. Add your first post above.',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff6C737F),
                    ),
                  );
                }

                return Column(
                  children: controller.posts.map((post) {
                    final postId = post['_id']?.toString() ?? '';
                    final imageUrl = post['imageUrl']?.toString() ?? '';
                    final text = post['text']?.toString() ?? '';
                    final isActive = post['isActive'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: cardBorder,
                        boxShadow: cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: const Color(0xffFEF6FB),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Color(0xff9DA4AE),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (text.isNotEmpty)
                                  CustomText(
                                    text: text,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    color: const Color(0xff4D5761),
                                  ),
                                if (text.isNotEmpty) const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xffECFDF3)
                                            : const Color(0xffF2F4F7),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        isActive ? 'Visible' : 'Hidden',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isActive
                                              ? const Color(0xff027A48)
                                              : const Color(0xff667085),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: postId.isEmpty
                                          ? null
                                          : () =>
                                                controller.togglePostVisibility(
                                                  postId: postId,
                                                  currentIsActive: isActive,
                                                ),
                                      child: Text(isActive ? 'Hide' : 'Show'),
                                    ),
                                    TextButton(
                                      onPressed: postId.isEmpty
                                          ? null
                                          : () {
                                              Get.defaultDialog(
                                                title: 'Delete Post',
                                                middleText:
                                                    'Are you sure you want to delete this post?',
                                                textConfirm: 'Delete',
                                                textCancel: 'Cancel',
                                                confirmTextColor: Colors.white,
                                                buttonColor: Colors.red,
                                                onConfirm: () {
                                                  Get.back();
                                                  controller.deletePost(postId);
                                                },
                                              );
                                            },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: 30),
              const Divider(color: Color(0xffE5E7EB)),
              const SizedBox(height: 20),

              _PhotoGalleryManager(controller: controller),

              const SizedBox(height: 30),
              const Divider(color: Color(0xffE5E7EB)),
              const SizedBox(height: 20),

              _SocialMediaManager(controller: controller),

              const SizedBox(height: 30),
              const Divider(color: Color(0xffE5E7EB)),
              const SizedBox(height: 20),

              _ArticlesManager(controller: controller),

              const SizedBox(height: 30),
              const Divider(color: Color(0xffE5E7EB)),
              const SizedBox(height: 20),

              _ReviewsManager(controller: controller),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

class _PhotoGalleryManager extends StatelessWidget {
  final DoctorProfileController controller;
  const _PhotoGalleryManager({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Photo Gallery',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'Auto-scrolling carousel at the top of your About Doctor page - add 5-6 photos of yourself for the best effect.',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: const Color(0xff6C737F),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final images = controller.galleryImages;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...images.map((img) {
                final id = img['id']?.toString() ?? '';
                final url = img['url']?.toString() ?? '';
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: const Color(0xffFEF6FB),
                          child: const Icon(Icons.image_outlined, color: Color(0xff9DA4AE)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => controller.deleteGalleryImage(id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              GestureDetector(
                onTap: controller.isGalleryUploading.value ? null : controller.addGalleryImage,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffF3D9E9)),
                  ),
                  child: controller.isGalleryUploading.value
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff851653)),
                          ),
                        )
                      : const Icon(Icons.add_a_photo_outlined, color: Color(0xff851653)),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _SocialMediaManager extends StatelessWidget {
  final DoctorProfileController controller;
  const _SocialMediaManager({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Social Media',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'Shown on your About Doctor page - YouTube scrolls horizontally, Instagram as vertical cards. Drag to reorder.',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: const Color(0xff6C737F),
        ),
        const SizedBox(height: 16),

        // --- YouTube ---
        CustomText(
          text: 'YouTube',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: const Color(0xff851653),
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'YouTube link',
          controller: controller.youtubeUrlController,
          hintText: 'https://youtube.com/watch?v=...',
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Caption (optional)',
          controller: controller.youtubeCaptionController,
          hintText: 'What is this video about?',
        ),
        const SizedBox(height: 10),
        Obx(
          () => controller.isSocialSaving.value
              ? const Center(child: CircularProgressIndicator(color: Color(0xff851653)))
              : CustomButton(
                  text: 'Add YouTube Link',
                  isOutline: true,
                  onTap: controller.addYoutubePost,
                ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final list = controller.youtubePosts;
          if (list.isEmpty) return const SizedBox.shrink();
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            onReorder: controller.reorderYoutube,
            itemBuilder: (context, index) {
              final post = list[index];
              return _SocialPostTile(
                key: ValueKey(post['_id']),
                thumbnailUrl: post['thumbnailUrl']?.toString() ?? '',
                caption: post['caption']?.toString() ?? '',
                onDelete: () => controller.deleteSocialPost(post['_id'].toString(), 'youtube'),
              );
            },
          );
        }),

        const SizedBox(height: 20),

        // --- Instagram ---
        CustomText(
          text: 'Instagram',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: const Color(0xff851653),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.pickInstagramImage,
          child: Obx(
            () => Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffF3D9E9)),
              ),
              child: controller.pickedInstagramImage.value == null
                  ? const Center(
                      child: Icon(Icons.add_a_photo_outlined, color: Color(0xff851653), size: 30),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(controller.pickedInstagramImage.value!.path),
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Instagram link',
          controller: controller.instagramUrlController,
          hintText: 'https://instagram.com/...',
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Caption (optional)',
          controller: controller.instagramCaptionController,
          hintText: 'What is this post about?',
        ),
        const SizedBox(height: 10),
        Obx(
          () => controller.isSocialSaving.value
              ? const Center(child: CircularProgressIndicator(color: Color(0xff851653)))
              : CustomButton(
                  text: 'Add Instagram Post',
                  isOutline: true,
                  onTap: controller.addInstagramPost,
                ),
        ),
        const SizedBox(height: 14),
        Obx(() {
          final list = controller.instagramPosts;
          if (list.isEmpty) return const SizedBox.shrink();
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            onReorder: controller.reorderInstagram,
            itemBuilder: (context, index) {
              final post = list[index];
              return _SocialPostTile(
                key: ValueKey(post['_id']),
                thumbnailUrl: post['thumbnailUrl']?.toString() ?? '',
                caption: post['caption']?.toString() ?? '',
                onDelete: () => controller.deleteSocialPost(post['_id'].toString(), 'instagram'),
              );
            },
          );
        }),
      ],
    );
  }
}

class _SocialPostTile extends StatelessWidget {
  final String thumbnailUrl;
  final String caption;
  final VoidCallback onDelete;

  const _SocialPostTile({
    super.key,
    required this.thumbnailUrl,
    required this.caption,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Color(0xff9DA4AE)),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: thumbnailUrl.isNotEmpty
                ? Image.network(
                    thumbnailUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xffFEF6FB),
                      child: const Icon(Icons.image_outlined, color: Color(0xff9DA4AE)),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xffFEF6FB),
                    child: const Icon(Icons.image_outlined, color: Color(0xff9DA4AE)),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              text: caption.isNotEmpty ? caption : '(no caption)',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: const Color(0xff4D5761),
              maxLines: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ArticlesManager extends StatelessWidget {
  final DoctorProfileController controller;
  const _ArticlesManager({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Articles',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'Nutrition/wellness articles shown on your About Doctor page. Drag to reorder.',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: const Color(0xff6C737F),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: controller.pickArticleImage,
          child: Obx(
            () => Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffF3D9E9)),
              ),
              child: controller.pickedArticleImage.value == null
                  ? const Center(
                      child: Icon(Icons.add_a_photo_outlined, color: Color(0xff851653), size: 30),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(controller.pickedArticleImage.value!.path),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Title',
          controller: controller.articleTitleController,
          hintText: 'e.g. 5 Sustainable Weight-Loss Habits',
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Category',
          controller: controller.articleCategoryController,
          hintText: 'e.g. Weight Loss',
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Excerpt',
          controller: controller.articleExcerptController,
          hintText: 'One or two sentence teaser',
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        CustomField(
          lable: 'Full content',
          controller: controller.articleContentController,
          hintText: 'The full article text patients will read',
          maxLines: 6,
        ),
        const SizedBox(height: 10),
        Obx(
          () => controller.isArticleSaving.value
              ? const Center(child: CircularProgressIndicator(color: Color(0xff851653)))
              : CustomButton(
                  text: 'Add Article',
                  isOutline: true,
                  onTap: controller.addArticle,
                ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.articles.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(12),
                border: cardBorder,
                boxShadow: cardShadow,
              ),
              child: const CustomText(
                text: 'No articles yet. Add your first one above.',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xff6C737F),
              ),
            );
          }
          final list = controller.articles;
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            onReorder: controller.reorderArticles,
            itemBuilder: (context, index) {
              final article = list[index];
              return Container(
                key: ValueKey(article['_id']),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: cardBorder,
                  boxShadow: cardShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, color: Color(0xff9DA4AE)),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        article['imageUrl']?.toString() ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xffFEF6FB),
                          child: const Icon(Icons.image_outlined, color: Color(0xff9DA4AE)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        text: article['title']?.toString() ?? '',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: const Color(0xff1F2A37),
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => controller.deleteArticle(article['_id'].toString()),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _ReviewsManager extends StatelessWidget {
  final DoctorProfileController controller;
  const _ReviewsManager({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'Reviews',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'Submitted by patients. Drag to reorder how they appear on your About Doctor page.',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: const Color(0xff6C737F),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isReviewsLoading.value) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff851653)));
          }
          if (controller.reviews.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(12),
                border: cardBorder,
                boxShadow: cardShadow,
              ),
              child: const CustomText(
                text: 'No reviews yet.',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xff6C737F),
              ),
            );
          }
          final list = controller.reviews;
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            onReorder: controller.reorderReviews,
            itemBuilder: (context, index) {
              final review = list[index];
              final rating = (review['rating'] as num?)?.toInt() ?? 0;
              return Container(
                key: ValueKey(review['_id']),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: cardBorder,
                  boxShadow: cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.drag_indicator, color: Color(0xff9DA4AE)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: review['patientName']?.toString() ?? 'Patient',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: const Color(0xff1F2A37),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating ? Icons.star : Icons.star_border,
                                    size: 14,
                                    color: const Color(0xffF670CA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((review['text']?.toString() ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            CustomText(
                              text: review['text'].toString(),
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: const Color(0xff4D5761),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => controller.deleteReview(review['_id'].toString()),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
