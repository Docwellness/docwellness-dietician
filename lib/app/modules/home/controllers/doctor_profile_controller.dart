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

  final youtubeUrlController = TextEditingController();
  final youtubeCaptionController = TextEditingController();
  final instagramUrlController = TextEditingController();
  final instagramCaptionController = TextEditingController();

  final articleTitleController = TextEditingController();
  final articleCategoryController = TextEditingController();
  final articleExcerptController = TextEditingController();
  final articleContentController = TextEditingController();

  /// Options for the title dropdown above Full Name - fullName is saved to
  /// the backend as "$selectedTitlePrefix $nameController.text" (there's no
  /// separate prefix field in the backend schema), and split back apart in
  /// loadProfile so the dropdown and name field don't show the title
  /// twice-concatenated on the next load.
  static const List<String> titlePrefixOptions = [
    'Dr.',
    'Mr.',
    'Ms.',
    'Mrs.',
    'Prof.',
  ];
  RxString selectedTitlePrefix = 'Dr.'.obs;

  RxString selectedGender = ''.obs;
  RxString profileImageUrl = ''.obs;
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;
  RxBool isPostsLoading = false.obs;
  RxBool isPostSaving = false.obs;
  RxBool isPostActive = true.obs;
  Rx<XFile?> pickedPostImage = Rx<XFile?>(null);

  RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;

  // Social media
  RxBool isSocialLoading = false.obs;
  RxBool isSocialSaving = false.obs;
  Rx<XFile?> pickedInstagramImage = Rx<XFile?>(null);
  RxList<Map<String, dynamic>> youtubePosts = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> instagramPosts = <Map<String, dynamic>>[].obs;

  // Articles
  RxBool isArticlesLoading = false.obs;
  RxBool isArticleSaving = false.obs;
  Rx<XFile?> pickedArticleImage = Rx<XFile?>(null);
  RxList<Map<String, dynamic>> articles = <Map<String, dynamic>>[].obs;

  // Reviews (read/reorder/delete only - patients write these)
  RxBool isReviewsLoading = false.obs;
  RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;

  // Photo gallery (About Doctor page carousel)
  RxBool isGalleryLoading = false.obs;
  RxBool isGalleryUploading = false.obs;
  RxList<Map<String, dynamic>> galleryImages = <Map<String, dynamic>>[].obs;

  Rx<DoctorProfileModel?> profile = Rx<DoctorProfileModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadProfile();
    fetchPosts();
    fetchSocialPosts();
    fetchArticles();
    fetchReviews();
    fetchGalleryImages();
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
    youtubeUrlController.dispose();
    youtubeCaptionController.dispose();
    instagramUrlController.dispose();
    instagramCaptionController.dispose();
    articleTitleController.dispose();
    articleCategoryController.dispose();
    articleExcerptController.dispose();
    articleContentController.dispose();
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
        final rawName = data.fullName.trim();
        String? matchedPrefix;
        for (final p in titlePrefixOptions) {
          if (rawName.startsWith('$p ')) {
            matchedPrefix = p;
            break;
          }
        }
        if (matchedPrefix != null) {
          selectedTitlePrefix.value = matchedPrefix;
          nameController.text = rawName.substring(matchedPrefix.length).trim();
        } else {
          nameController.text = rawName;
        }
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
      final prefix = selectedTitlePrefix.value.trim();
      final name = nameController.text.trim();
      final data = <String, dynamic>{
        'fullName': prefix.isEmpty ? name : '$prefix $name',
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

  // ---- Social Media ----

  Future<void> fetchSocialPosts() async {
    isSocialLoading.value = true;
    try {
      final data = await _service.getSocialPosts();
      youtubePosts.value = data.where((p) => p['platform'] == 'youtube').toList();
      instagramPosts.value = data.where((p) => p['platform'] == 'instagram').toList();
    } catch (e) {
      log('❌ Error loading social posts: $e');
    } finally {
      isSocialLoading.value = false;
    }
  }

  Future<void> pickInstagramImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) pickedInstagramImage.value = image;
  }

  Future<void> addYoutubePost() async {
    if (youtubeUrlController.text.trim().isEmpty) {
      showAppToast(Get.overlayContext!, message: 'Paste a YouTube link first', type: AppToastType.warning);
      return;
    }
    isSocialSaving.value = true;
    try {
      final success = await _service.addSocialPost(
        platform: 'youtube',
        url: youtubeUrlController.text.trim(),
        caption: youtubeCaptionController.text.trim(),
      );
      if (success) {
        youtubeUrlController.clear();
        youtubeCaptionController.clear();
        await fetchSocialPosts();
        showAppToast(Get.overlayContext!, message: 'YouTube link added', type: AppToastType.success);
      } else {
        showAppToast(Get.overlayContext!, message: 'Failed to add YouTube link', type: AppToastType.error);
      }
    } finally {
      isSocialSaving.value = false;
    }
  }

  Future<void> addInstagramPost() async {
    if (instagramUrlController.text.trim().isEmpty || pickedInstagramImage.value == null) {
      showAppToast(
        Get.overlayContext!,
        message: 'An Instagram link and a thumbnail image are both required',
        type: AppToastType.warning,
      );
      return;
    }
    isSocialSaving.value = true;
    try {
      final success = await _service.addSocialPost(
        platform: 'instagram',
        url: instagramUrlController.text.trim(),
        imagePath: pickedInstagramImage.value!.path,
        caption: instagramCaptionController.text.trim(),
      );
      if (success) {
        instagramUrlController.clear();
        instagramCaptionController.clear();
        pickedInstagramImage.value = null;
        await fetchSocialPosts();
        showAppToast(Get.overlayContext!, message: 'Instagram post added', type: AppToastType.success);
      } else {
        showAppToast(Get.overlayContext!, message: 'Failed to add Instagram post', type: AppToastType.error);
      }
    } finally {
      isSocialSaving.value = false;
    }
  }

  Future<void> deleteSocialPost(String id, String platform) async {
    final success = await _service.deleteSocialPost(id);
    if (success) {
      if (platform == 'youtube') {
        youtubePosts.removeWhere((p) => p['_id'] == id);
      } else {
        instagramPosts.removeWhere((p) => p['_id'] == id);
      }
    }
  }

  Future<void> reorderYoutube(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<Map<String, dynamic>>.from(youtubePosts);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    youtubePosts.value = list;
    await _service.reorderSocialPosts('youtube', list.map((p) => p['_id'].toString()).toList());
  }

  Future<void> reorderInstagram(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<Map<String, dynamic>>.from(instagramPosts);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    instagramPosts.value = list;
    await _service.reorderSocialPosts('instagram', list.map((p) => p['_id'].toString()).toList());
  }

  // ---- Articles ----

  Future<void> fetchArticles() async {
    isArticlesLoading.value = true;
    try {
      articles.value = await _service.getArticles();
    } catch (e) {
      log('❌ Error loading articles: $e');
    } finally {
      isArticlesLoading.value = false;
    }
  }

  Future<void> pickArticleImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image != null) pickedArticleImage.value = image;
  }

  void clearArticleComposer() {
    pickedArticleImage.value = null;
    articleTitleController.clear();
    articleCategoryController.clear();
    articleExcerptController.clear();
    articleContentController.clear();
  }

  Future<void> addArticle() async {
    if (articleTitleController.text.trim().isEmpty || pickedArticleImage.value == null) {
      showAppToast(
        Get.overlayContext!,
        message: 'A title and an image are both required',
        type: AppToastType.warning,
      );
      return;
    }
    isArticleSaving.value = true;
    try {
      final success = await _service.addArticle(
        title: articleTitleController.text.trim(),
        imagePath: pickedArticleImage.value!.path,
        category: articleCategoryController.text.trim(),
        excerpt: articleExcerptController.text.trim(),
        content: articleContentController.text.trim(),
      );
      if (success) {
        clearArticleComposer();
        await fetchArticles();
        showAppToast(Get.overlayContext!, message: 'Article added', type: AppToastType.success);
      } else {
        showAppToast(Get.overlayContext!, message: 'Failed to add article', type: AppToastType.error);
      }
    } finally {
      isArticleSaving.value = false;
    }
  }

  Future<void> deleteArticle(String id) async {
    final success = await _service.deleteArticle(id);
    if (success) articles.removeWhere((a) => a['_id'] == id);
  }

  Future<void> reorderArticles(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<Map<String, dynamic>>.from(articles);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    articles.value = list;
    await _service.reorderArticles(list.map((a) => a['_id'].toString()).toList());
  }

  // ---- Reviews ----

  Future<void> fetchReviews() async {
    isReviewsLoading.value = true;
    try {
      reviews.value = await _service.getReviews();
    } catch (e) {
      log('❌ Error loading reviews: $e');
    } finally {
      isReviewsLoading.value = false;
    }
  }

  Future<void> deleteReview(String id) async {
    final success = await _service.deleteReview(id);
    if (success) reviews.removeWhere((r) => r['_id'] == id);
  }

  /// Drag-to-reorder on the dietician app is how reviews get "sorted" -
  /// the patient app then renders them in whatever order she leaves them.
  Future<void> reorderReviews(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<Map<String, dynamic>>.from(reviews);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    reviews.value = list;
    await _service.reorderReviews(list.map((r) => r['_id'].toString()).toList());
  }

  // ---- Photo Gallery ----

  Future<void> fetchGalleryImages() async {
    isGalleryLoading.value = true;
    try {
      galleryImages.value = await _service.getGalleryImages();
    } catch (e) {
      log('❌ Error loading gallery images: $e');
    } finally {
      isGalleryLoading.value = false;
    }
  }

  Future<void> addGalleryImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image == null) return;

    isGalleryUploading.value = true;
    try {
      final success = await _service.addGalleryImage(image.path);
      if (success) {
        await fetchGalleryImages();
        showAppToast(Get.overlayContext!, message: 'Photo added', type: AppToastType.success);
      } else {
        showAppToast(Get.overlayContext!, message: 'Failed to add photo', type: AppToastType.error);
      }
    } finally {
      isGalleryUploading.value = false;
    }
  }

  Future<void> deleteGalleryImage(String id) async {
    final success = await _service.deleteGalleryImage(id);
    if (success) galleryImages.removeWhere((g) => g['id'] == id);
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
