import 'dart:developer';

import 'package:docwellnesdoc/app/models/doctor_profile_model.dart';
import 'package:docwellnesdoc/app/modules/home/services/doctor_profile_service.dart';
import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/core/session/session_service.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Only logout entry point in the app - see auth/controllers/auth_controller.dart
  /// for the login side of this. Clears the Supabase session (best-effort;
  /// a network failure here shouldn't block the user from getting logged out
  /// locally) and local session state, then sends the dietician back to the
  /// real login screen instead of leaving stale credentials usable.
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Best-effort - proceed with clearing local state regardless.
    }
    token = null;
    userId = null;
    await SessionService.to.clear();
    Get.offAllNamed(Routes.AUTH);
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
        showAppToast(
          Get.overlayContext!,
          message: 'Profile updated successfully',
          type: AppToastType.success,
        );
        await loadProfile();
        await fetchPosts();
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to update profile',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      log('❌ Error saving profile: $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong',
        type: AppToastType.error,
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
      showAppToast(
        Get.overlayContext!,
        message: 'Image required: Please select an image for the post.',
        type: AppToastType.warning,
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
        showAppToast(
          Get.overlayContext!,
          message: 'Post added successfully',
          type: AppToastType.success,
        );
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to add post',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      log('❌ Error adding post: $e');
      showAppToast(
        Get.overlayContext!,
        message: 'Something went wrong while adding post',
        type: AppToastType.error,
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
        showAppToast(
          Get.overlayContext!,
          message: !currentIsActive
              ? 'Post is now visible to patients'
              : 'Post is now hidden from patients',
          type: AppToastType.success,
        );
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to update post visibility',
          type: AppToastType.error,
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
        showAppToast(
          Get.overlayContext!,
          message: 'Post deleted successfully',
          type: AppToastType.success,
        );
      } else {
        showAppToast(
          Get.overlayContext!,
          message: 'Failed to delete post',
          type: AppToastType.error,
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
        showAppToast(
          Get.overlayContext!,
          message: 'Profile image updated',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      log('❌ Error uploading image: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    // Branding comes from ThemeData.datePickerTheme (main.dart) - no local
    // override needed.
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: profile.value?.dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }
}
