import 'dart:io';

import 'package:docwellnesdoc/app/modules/home/controllers/doctor_profile_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
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
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xff851653)
                              : Colors.grey.shade300,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xff851653)
                              : Colors.grey,
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
                        border: Border.all(color: const Color(0xffF3D9E9)),
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

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}
