import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../home/controllers/home_controller.dart' as home;
import '../services/coupon_service.dart';
import '../services/performance_stats_service.dart';
import '../services/quote_service.dart';
import '../services/video_service.dart';

class PerformanceController extends GetxController {
  final ImagePicker picker = ImagePicker();
  final VideoService _videoService = VideoService();
  final QuoteService _quoteService = QuoteService();
  final PerformanceStatsService _statsService = PerformanceStatsService();
  final CouponService _couponService = CouponService();

  RxBool isSelected = false.obs;
  RxBool isQuotesSelected = false.obs;
  RxBool isVideoBannerSelected = false.obs;

  RxString selectedSource = ''.obs;
  RxString videoThumbnail = ''.obs;

  // YouTube
  final TextEditingController youtubeUrlController = TextEditingController();
  final TextEditingController videoTitleController = TextEditingController();
  final TextEditingController videoTextController = TextEditingController();
  RxString youtubeUrl = ''.obs;
  RxString youtubeThumbnailUrl = ''.obs;

  // Edit mode
  RxBool isEditMode = false.obs;
  RxString editingVideoId = ''.obs;

  Rx<XFile?> pickedQuoteImage = Rx<XFile?>(null);
  Rx<XFile?> pickedVideoBannerImage = Rx<XFile?>(null);
  Rx<XFile?> pickedVideo = Rx<XFile?>(null);

  // Video save state
  RxBool isVideoSaving = false.obs;
  RxBool isVideosLoading = false.obs;
  RxList<Map<String, dynamic>> videosList = <Map<String, dynamic>>[].obs;

  // Quote state
  RxBool isQuoteSaving = false.obs;
  RxBool isQuotesLoading = false.obs;
  RxList<Map<String, dynamic>> quotesList = <Map<String, dynamic>>[].obs;
  RxBool isQuoteEditMode = false.obs;
  RxString editingQuoteId = ''.obs;
  final TextEditingController quoteTextController = TextEditingController();

  // Coupon state
  RxBool isCouponSaving = false.obs;
  RxBool isCouponsLoading = false.obs;
  RxList<Map<String, dynamic>> couponsList = <Map<String, dynamic>>[].obs;
  RxBool isCouponEditMode = false.obs;
  RxString editingCouponId = ''.obs;
  final TextEditingController couponNameController = TextEditingController();
  final TextEditingController couponCodeController = TextEditingController();
  final TextEditingController couponPercentageController =
      TextEditingController();
  final TextEditingController couponValidTillController =
      TextEditingController();
  RxBool isCouponActive = true.obs;

  // Performance cards state
  RxBool isStatsLoading = false.obs;
  RxInt totalPatients = 0.obs;
  RxDouble totalRevenue = 0.0.obs;
  RxDouble patientsChangePercent = 0.0.obs;
  RxDouble revenueChangePercent = 0.0.obs;
  RxList<double> patientsTrend = <double>[].obs;
  RxList<double> revenueTrend = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPerformanceStats();
    fetchVideos();
    fetchQuotes();
    fetchCoupons();
  }

  @override
  void onClose() {
    youtubeUrlController.dispose();
    videoTitleController.dispose();
    videoTextController.dispose();
    quoteTextController.dispose();
    couponNameController.dispose();
    couponCodeController.dispose();
    couponPercentageController.dispose();
    couponValidTillController.dispose();
    super.onClose();
  }

  Future<void> fetchPerformanceStats({bool silent = false}) async {
    if (!silent) {
      isStatsLoading.value = true;
    }

    try {
      final data = await _statsService.getPerformanceTrends();
      if (data == null) return;

      totalPatients.value = (data['totalPatients'] as num?)?.toInt() ?? 0;
      totalRevenue.value = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
      patientsChangePercent.value =
          (data['patientsChangePercent'] as num?)?.toDouble() ?? 0.0;
      revenueChangePercent.value =
          (data['revenueChangePercent'] as num?)?.toDouble() ?? 0.0;

      final pWeekly = List<num>.from(data['patientWeekly'] ?? []);
      final rWeekly = List<num>.from(data['revenueWeekly'] ?? []);

      patientsTrend.value = _normalize(pWeekly);
      revenueTrend.value = _normalize(rWeekly);
    } finally {
      if (!silent) {
        isStatsLoading.value = false;
      }
    }
  }

  /// Normalize a list of numbers to 0.0–1.0 range for the chart painters.
  List<double> _normalize(List<num> values) {
    if (values.isEmpty) return [];
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) return values.map((_) => 0.0).toList();
    return values.map((v) => v.toDouble() / maxVal).toList();
  }

  // ── Fetch all videos from server ──────────────────────────────
  Future<void> fetchVideos() async {
    isVideosLoading.value = true;
    try {
      final data = await _videoService.getVideos();
      videosList.value = data;
    } finally {
      isVideosLoading.value = false;
    }
  }

  /// Reset the upload form fields for a fresh upload
  void resetUploadForm() {
    selectedSource.value = '';
    youtubeUrl.value = '';
    youtubeThumbnailUrl.value = '';
    youtubeUrlController.clear();
    videoTitleController.clear();
    videoTextController.clear();
    pickedVideoBannerImage.value = null;
    pickedVideo.value = null;
    videoThumbnail.value = '';
    isVideoBannerSelected.value = false;
    isEditMode.value = false;
    editingVideoId.value = '';
  }

  /// Pre-fill form for editing an existing video
  void prefillForEdit(Map<String, dynamic> video) {
    resetUploadForm();
    isEditMode.value = true;
    editingVideoId.value = video['_id'] as String? ?? '';
    final title = video['title'] as String? ?? '';
    videoTitleController.text = title;
    videoTextController.text = video['text'] as String? ?? '';
    selectedSource.value = video['source'] as String? ?? '';
    isVideoBannerSelected.value = video['visibleToUser'] == true;

    if (selectedSource.value == 'YouTube') {
      final ytUrl = video['youtubeUrl'] as String? ?? '';
      youtubeUrlController.text = ytUrl;
      youtubeUrl.value = ytUrl;
      final thumbUrl = video['thumbnailUrl'] as String? ?? '';
      if (thumbUrl.isNotEmpty) {
        youtubeThumbnailUrl.value = thumbUrl;
      } else {
        onYoutubeUrlChanged(ytUrl);
      }
    }
  }

  // ── Add video ─────────────────────────────────────────────────
  Future<void> addVideo() async {
    if (selectedSource.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a source',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedSource.value == 'YouTube' && youtubeUrl.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a YouTube URL',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedSource.value == 'Device Storage' && pickedVideo.value == null) {
      Get.snackbar(
        'Error',
        'Please pick a video',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isVideoSaving.value = true;

    try {
      final result = await _videoService.addVideo(
        source: selectedSource.value,
        youtubeUrl: youtubeUrl.value,
        thumbnailUrl: youtubeThumbnailUrl.value,
        visibleToUser: isVideoBannerSelected.value,
        bannerImagePath: pickedVideoBannerImage.value?.path,
        videoFilePath: pickedVideo.value?.path,
        text: videoTextController.text.trim(),
      );

      if (result != null) {
        await fetchVideos(); // refresh the list
        resetUploadForm();
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Video added successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to add video',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('addVideo error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isVideoSaving.value = false;
    }
  }

  // ── Delete video ──────────────────────────────────────────────
  Future<void> deleteVideoById(String videoId) async {
    isVideoSaving.value = true;
    try {
      final success = await _videoService.deleteVideo(videoId);
      if (success) {
        videosList.removeWhere((v) => v['_id'] == videoId);
        Get.snackbar(
          'Success',
          'Video deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete video',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('deleteVideo error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isVideoSaving.value = false;
    }
  }

  // ── Update video ──────────────────────────────────────────────
  Future<void> updateVideoById() async {
    if (editingVideoId.value.isEmpty) return;

    isVideoSaving.value = true;
    try {
      final result = await _videoService.updateVideo(
        videoId: editingVideoId.value,
        source: selectedSource.value.isNotEmpty ? selectedSource.value : null,
        title: videoTitleController.text.isNotEmpty
            ? videoTitleController.text
            : null,
        youtubeUrl: youtubeUrl.value.isNotEmpty ? youtubeUrl.value : null,
        thumbnailUrl: youtubeThumbnailUrl.value.isNotEmpty
            ? youtubeThumbnailUrl.value
            : null,
        visibleToUser: isVideoBannerSelected.value,
        bannerImagePath: pickedVideoBannerImage.value?.path,
        videoFilePath: pickedVideo.value?.path,
        text: videoTextController.text.trim(),
      );

      if (result != null) {
        await fetchVideos();
        resetUploadForm();
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Video updated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to update video',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('updateVideo error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isVideoSaving.value = false;
    }
  }

  // ── Toggle visibility ─────────────────────────────────────────
  Future<void> toggleVideoVisibility(
    String videoId,
    bool currentVisibility,
  ) async {
    try {
      final result = await _videoService.toggleVisibility(
        videoId,
        !currentVisibility,
      );
      if (result != null) {
        // Update local list
        final idx = videosList.indexWhere((v) => v['_id'] == videoId);
        if (idx != -1) {
          videosList[idx] = Map<String, dynamic>.from(videosList[idx])
            ..['visibleToUser'] = !currentVisibility;
          videosList.refresh();
        }
        Get.snackbar(
          'Success',
          !currentVisibility ? 'Video is now visible' : 'Video is now hidden',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update visibility',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('toggleVisibility error: $e');
    }
  }

  /// Extract YouTube video ID from various URL formats
  String? extractYoutubeVideoId(String url) {
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?.*v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// Called when YouTube URL text changes
  void onYoutubeUrlChanged(String url) {
    youtubeUrl.value = url;
    final videoId = extractYoutubeVideoId(url);
    if (videoId != null) {
      youtubeThumbnailUrl.value =
          'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    } else {
      youtubeThumbnailUrl.value = '';
    }
  }

  Future pickQuoteImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedQuoteImage.value = img;
    }
  }

  Future pickVideoBannerImage() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedVideoBannerImage.value = img;
    }
  }

  Future pickVideo() async {
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      pickedVideo.value = video;

      // generate thumbnail
      final thumb = await VideoThumbnail.thumbnailFile(
        video: video.path,
        imageFormat: ImageFormat.PNG,
        quality: 80,
      );

      if (thumb != null) {
        videoThumbnail.value = thumb;
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // QUOTES CRUD
  // ══════════════════════════════════════════════════════════════

  /// Fetch all quotes from server
  Future<void> fetchQuotes() async {
    isQuotesLoading.value = true;
    try {
      final data = await _quoteService.getQuotes();
      quotesList.value = data;
    } finally {
      isQuotesLoading.value = false;
    }
  }

  /// Reset the quote form for a fresh add
  void resetQuoteForm() {
    pickedQuoteImage.value = null;
    isQuotesSelected.value = false;
    isQuoteEditMode.value = false;
    editingQuoteId.value = '';
    quoteTextController.clear();
  }

  /// Pre-fill form for editing an existing quote
  void prefillForQuoteEdit(Map<String, dynamic> quote) {
    resetQuoteForm();
    isQuoteEditMode.value = true;
    editingQuoteId.value = quote['_id'] as String? ?? '';
    isQuotesSelected.value = quote['isActive'] == true;
    quoteTextController.text = quote['text'] as String? ?? '';
    // Don't prefill image — user must pick new or keep existing
  }

  /// Add a new quote
  Future<void> addQuote() async {
    if (pickedQuoteImage.value == null) {
      Get.snackbar(
        'Error',
        'Please select an image',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isQuoteSaving.value = true;
    try {
      final result = await _quoteService.addQuote(
        imagePath: pickedQuoteImage.value!.path,
        isActive: isQuotesSelected.value,
        text: quoteTextController.text.trim(),
      );

      if (result != null) {
        await fetchQuotes();
        resetQuoteForm();
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Quote added successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to add quote',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('addQuote error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isQuoteSaving.value = false;
    }
  }

  /// Update an existing quote
  Future<void> updateQuoteById() async {
    if (editingQuoteId.value.isEmpty) return;

    isQuoteSaving.value = true;
    try {
      final result = await _quoteService.updateQuote(
        quoteId: editingQuoteId.value,
        imagePath: pickedQuoteImage.value?.path,
        isActive: isQuotesSelected.value,
        text: quoteTextController.text.trim(),
      );

      if (result != null) {
        await fetchQuotes();
        resetQuoteForm();
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Quote updated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to update quote',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('updateQuote error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isQuoteSaving.value = false;
    }
  }

  /// Delete a quote by ID
  Future<void> deleteQuoteById(String quoteId) async {
    isQuoteSaving.value = true;
    try {
      final success = await _quoteService.deleteQuote(quoteId);
      if (success) {
        quotesList.removeWhere((q) => q['_id'] == quoteId);
        Get.snackbar(
          'Success',
          'Quote deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete quote',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('deleteQuote error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isQuoteSaving.value = false;
    }
  }

  /// Toggle active status
  Future<void> toggleQuoteActive(String quoteId, bool currentActive) async {
    try {
      final result = await _quoteService.toggleActive(quoteId, !currentActive);
      if (result != null) {
        final idx = quotesList.indexWhere((q) => q['_id'] == quoteId);
        if (idx != -1) {
          quotesList[idx] = Map<String, dynamic>.from(quotesList[idx])
            ..['isActive'] = !currentActive;
          quotesList.refresh();
        }
        Get.snackbar(
          'Success',
          !currentActive ? 'Quote is now active' : 'Quote is now hidden',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update status',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('toggleQuoteActive error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // COUPONS CRUD
  // ══════════════════════════════════════════════════════════════

  Future<void> fetchCoupons() async {
    isCouponsLoading.value = true;
    try {
      final data = await _couponService.getCoupons();
      couponsList.value = data;
      // Sync count with HomeController
      _syncCouponCount();
    } finally {
      isCouponsLoading.value = false;
    }
  }

  void _syncCouponCount() {
    try {
      final homeController = Get.find<home.HomeController>();
      homeController.activeCouponCount.value = couponsList.length;
    } catch (_) {
      // HomeController may not be registered
    }
  }

  void resetCouponForm() {
    couponNameController.clear();
    couponCodeController.clear();
    couponPercentageController.clear();
    couponValidTillController.clear();
    isCouponActive.value = true;
    isCouponEditMode.value = false;
    editingCouponId.value = '';
  }

  /// Convert DD/MM/YYYY from DatePickerField to YYYY-MM-DD for the API
  String _convertDateToISO(String ddmmyyyy) {
    final parts = ddmmyyyy.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return ddmmyyyy; // fallback
  }

  void prefillForCouponEdit(Map<String, dynamic> coupon) {
    resetCouponForm();
    isCouponEditMode.value = true;
    editingCouponId.value = coupon['_id'] as String? ?? '';
    couponNameController.text = coupon['name'] as String? ?? '';
    couponCodeController.text = coupon['code'] as String? ?? '';
    couponPercentageController.text = (coupon['discountPercentage'] ?? '')
        .toString();
    if (coupon['validTill'] != null) {
      final date = DateTime.tryParse(coupon['validTill'].toString());
      if (date != null) {
        couponValidTillController.text =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    }
    isCouponActive.value = coupon['isActive'] == true;
  }

  Future<void> addCoupon() async {
    if (couponNameController.text.trim().isEmpty ||
        couponCodeController.text.trim().isEmpty ||
        couponPercentageController.text.trim().isEmpty ||
        couponValidTillController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final percentage = int.tryParse(couponPercentageController.text.trim());
    if (percentage == null || percentage < 1 || percentage > 100) {
      Get.snackbar(
        'Error',
        'Discount must be between 1 and 100',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isCouponSaving.value = true;
    try {
      final result = await _couponService.addCoupon(
        name: couponNameController.text.trim(),
        code: couponCodeController.text.trim(),
        discountPercentage: percentage,
        validTill: _convertDateToISO(couponValidTillController.text.trim()),
        isActive: isCouponActive.value,
      );

      if (result != null) {
        await fetchCoupons();
        resetCouponForm();
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Coupon added successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to add coupon',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('addCoupon error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCouponSaving.value = false;
    }
  }

  Future<void> updateCouponById() async {
    if (editingCouponId.value.isEmpty) return;

    final percentage = int.tryParse(couponPercentageController.text.trim());
    if (percentage != null && (percentage < 1 || percentage > 100)) {
      Get.snackbar(
        'Error',
        'Discount must be between 1 and 100',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isCouponSaving.value = true;
    try {
      final result = await _couponService.updateCoupon(
        couponId: editingCouponId.value,
        name: couponNameController.text.trim(),
        code: couponCodeController.text.trim(),
        discountPercentage: percentage,
        validTill: _convertDateToISO(couponValidTillController.text.trim()),
        isActive: isCouponActive.value,
      );

      if (result != null) {
        await fetchCoupons();
        resetCouponForm();
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Coupon updated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to update coupon',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('updateCoupon error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCouponSaving.value = false;
    }
  }

  Future<void> deleteCouponById(String couponId) async {
    isCouponSaving.value = true;
    try {
      final success = await _couponService.deleteCoupon(couponId);
      if (success) {
        couponsList.removeWhere((c) => c['_id'] == couponId);
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Coupon deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete coupon',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      log('deleteCoupon error: $e');
      Get.snackbar(
        'Error',
        'Something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCouponSaving.value = false;
    }
  }
}
