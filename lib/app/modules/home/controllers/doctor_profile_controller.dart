import 'dart:developer';

import 'package:docwellnesdoc/app/models/doctor_profile_model.dart';
import 'package:docwellnesdoc/app/modules/home/services/doctor_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class DoctorProfileController extends GetxController {
  final DoctorProfileService _service = DoctorProfileService();
  final ImagePicker _picker = ImagePicker();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final specializationController = TextEditingController();
  final experienceController = TextEditingController();
  final qualificationController = TextEditingController();
  final bioController = TextEditingController();
  final postTextController = TextEditingController();

  RxString selectedGender = ''.obs;
  RxString profileImageUrl = ''.obs;
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;
  RxBool isPostsLoading = false.obs;
  RxBool isPostSaving = false.obs;
  RxBool isPostActive = true.obs;
  Rx<XFile?> pickedPostImage = Rx<XFile?>(null);

  RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;

  Rx<DoctorProfileModel?> profile = Rx<DoctorProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    fetchPosts();
  }

  @override
  void onClose() {
    nameController.dispose();
    dobController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    qualificationController.dispose();
    bioController.dispose();
    postTextController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final data = await _service.getProfile();
      if (data != null) {
        profile.value = data;
        nameController.text = data.fullName;
        if (data.dateOfBirth != null) {
          dobController.text =
              '${data.dateOfBirth!.day.toString().padLeft(2, '0')}-${data.dateOfBirth!.month.toString().padLeft(2, '0')}-${data.dateOfBirth!.year}';
        }
        selectedGender.value = data.gender;
        profileImageUrl.value = data.profileImage;
        specializationController.text = data.specialization;
        experienceController.text = data.experience > 0
            ? data.experience.toString()
            : '';
        qualificationController.text = data.qualification;
        bioController.text = data.bio;
      }
    } catch (e) {
      log('❌ Error loading profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    isSaving.value = true;
    try {
      final data = <String, dynamic>{
        'fullName': nameController.text.trim(),
        'gender': selectedGender.value,
        'specialization': specializationController.text.trim(),
        'qualification': qualificationController.text.trim(),
        'bio': bioController.text.trim(),
      };

      if (experienceController.text.trim().isNotEmpty) {
        data['experience'] =
            int.tryParse(experienceController.text.trim()) ?? 0;
      }

      if (dobController.text.trim().isNotEmpty) {
        // Parse DD-MM-YYYY to ISO
        final parts = dobController.text.trim().split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          data['dateOfBirth'] = date.toIso8601String();
        }
      }

      final success = await _service.updateProfile(data);
      if (success) {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff851653),
          colorText: Colors.white,
        );
        await loadProfile();
        await fetchPosts();
      } else {
        Get.snackbar(
          'Error',
          'Failed to update profile',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❌ Error saving profile: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchPosts() async {
    isPostsLoading.value = true;
    try {
      final data = await _service.getPosts();
      posts.value = data ?? [];
    } catch (e) {
      log('❌ Error loading doctor posts: $e');
      posts.clear();
    } finally {
      isPostsLoading.value = false;
    }
  }

  Future<void> pickPostImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      pickedPostImage.value = image;
    }
  }

  void clearPostComposer() {
    pickedPostImage.value = null;
    postTextController.clear();
    isPostActive.value = true;
  }

  Future<void> addPost() async {
    if (pickedPostImage.value == null) {
      Get.snackbar(
        'Image required',
        'Please select an image for the post.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isPostSaving.value = true;
    try {
      final result = await _service.addPost(
        imagePath: pickedPostImage.value!.path,
        text: postTextController.text.trim(),
        isActive: isPostActive.value,
      );

      if (result != null) {
        await fetchPosts();
        clearPostComposer();
        Get.snackbar(
          'Success',
          'Post added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff851653),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to add post',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❌ Error adding post: $e');
      Get.snackbar(
        'Error',
        'Something went wrong while adding post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPostSaving.value = false;
    }
  }

  Future<void> togglePostVisibility({
    required String postId,
    required bool currentIsActive,
  }) async {
    try {
      final result = await _service.updatePost(
        postId: postId,
        isActive: !currentIsActive,
      );

      if (result != null) {
        await fetchPosts();
        Get.snackbar(
          'Success',
          !currentIsActive
              ? 'Post is now visible to patients'
              : 'Post is now hidden from patients',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update post visibility',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('❌ Error toggling post visibility: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final success = await _service.deletePost(postId);
      if (success) {
        posts.removeWhere((p) => (p['_id']?.toString() ?? '') == postId);
        Get.snackbar(
          'Success',
          'Post deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete post',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('❌ Error deleting post: $e');
    }
  }

  Future<void> pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    isLoading.value = true;
    try {
      final imageUrl = await _service.uploadProfileImage(image.path);
      if (imageUrl != null) {
        profileImageUrl.value = imageUrl;
        Get.snackbar(
          'Success',
          'Profile image updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff851653),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: profile.value?.dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff851653),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dobController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }
}
