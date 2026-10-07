import 'package:docwellnesdoc/app/modules/performance/services/client_journey_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

enum JourneyImageSlot { before, after, review }

/// How the review is attached to a client journey.
enum JourneyReviewMode { none, image, text }

/// Owns Performance > Client Journeys: the list plus the add/edit form.
class ClientJourneyController extends GetxController {
  final ClientJourneyService _service = ClientJourneyService();
  final ImagePicker _picker = ImagePicker();

  final RxList<Map<String, dynamic>> journeys = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // ── Form state ──
  final RxString editingId = ''.obs;
  bool get isEditMode => editingId.value.isNotEmpty;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController reviewTextController = TextEditingController();
  final Rx<XFile?> beforeImage = Rx<XFile?>(null);
  final Rx<XFile?> afterImage = Rx<XFile?>(null);
  final Rx<XFile?> reviewImage = Rx<XFile?>(null);
  // Already-saved URLs while editing, shown until a new photo replaces them.
  final RxString existingBeforeUrl = ''.obs;
  final RxString existingAfterUrl = ''.obs;
  final RxString existingReviewUrl = ''.obs;
  final Rx<JourneyReviewMode> reviewMode = JourneyReviewMode.none.obs;
  final RxBool isActive = true.obs;
  // What the saved journey's review was when editing began - decides whether
  // switching to "no review" needs to tell the server to clear it.
  String _savedReviewType = 'none';

  @override
  void onInit() {
    super.onInit();
    fetchJourneys();
  }

  @override
  void onClose() {
    titleController.dispose();
    reviewTextController.dispose();
    super.onClose();
  }

  Future<void> fetchJourneys() async {
    isLoading.value = true;
    journeys.value = await _service.getJourneys();
    isLoading.value = false;
  }

  void resetForm() {
    editingId.value = '';
    titleController.clear();
    reviewTextController.clear();
    beforeImage.value = null;
    afterImage.value = null;
    reviewImage.value = null;
    existingBeforeUrl.value = '';
    existingAfterUrl.value = '';
    existingReviewUrl.value = '';
    reviewMode.value = JourneyReviewMode.none;
    isActive.value = true;
    _savedReviewType = 'none';
  }

  void prefillForEdit(Map<String, dynamic> journey) {
    resetForm();
    editingId.value = journey['_id'] as String? ?? '';
    titleController.text = journey['title'] as String? ?? '';
    existingBeforeUrl.value = journey['beforeImageUrl'] as String? ?? '';
    existingAfterUrl.value = journey['afterImageUrl'] as String? ?? '';
    existingReviewUrl.value = journey['reviewImageUrl'] as String? ?? '';
    reviewTextController.text = journey['reviewText'] as String? ?? '';
    isActive.value = journey['isActive'] != false;
    _savedReviewType = journey['reviewType'] as String? ?? 'none';
    reviewMode.value = switch (_savedReviewType) {
      'image' => JourneyReviewMode.image,
      'text' => JourneyReviewMode.text,
      _ => JourneyReviewMode.none,
    };
  }

  Future<void> pickImage(JourneyImageSlot slot) async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (img == null) return;
    switch (slot) {
      case JourneyImageSlot.before:
        beforeImage.value = img;
      case JourneyImageSlot.after:
        afterImage.value = img;
      case JourneyImageSlot.review:
        reviewImage.value = img;
    }
  }

  void _toast(String message, AppToastType type) {
    final ctx = Get.overlayContext;
    if (ctx != null) showAppToast(ctx, message: message, type: type);
  }

  /// Returns true when saved (so the sheet can close).
  Future<bool> save() async {
    final hasBefore = beforeImage.value != null || existingBeforeUrl.isNotEmpty;
    final hasAfter = afterImage.value != null || existingAfterUrl.isNotEmpty;
    if (!hasBefore || !hasAfter) {
      _toast('Add both a before and an after photo', AppToastType.error);
      return false;
    }
    final mode = reviewMode.value;
    final text = reviewTextController.text.trim();
    if (mode == JourneyReviewMode.text && text.isEmpty) {
      _toast('Write the review, or choose another review type', AppToastType.error);
      return false;
    }
    if (mode == JourneyReviewMode.image &&
        reviewImage.value == null &&
        existingReviewUrl.isEmpty) {
      _toast('Add the review image, or choose another review type', AppToastType.error);
      return false;
    }

    isSaving.value = true;
    try {
      final Map<String, dynamic>? saved;
      if (isEditMode) {
        saved = await _service.updateJourney(
          journeyId: editingId.value,
          title: titleController.text.trim(),
          isActive: isActive.value,
          beforePath: beforeImage.value?.path,
          afterPath: afterImage.value?.path,
          reviewImagePath: mode == JourneyReviewMode.image
              ? reviewImage.value?.path
              : null,
          reviewText: mode == JourneyReviewMode.text ? text : null,
          removeReview:
              mode == JourneyReviewMode.none && _savedReviewType != 'none',
        );
      } else {
        saved = await _service.addJourney(
          beforePath: beforeImage.value!.path,
          afterPath: afterImage.value!.path,
          title: titleController.text.trim(),
          reviewImagePath: mode == JourneyReviewMode.image
              ? reviewImage.value?.path
              : null,
          reviewText: mode == JourneyReviewMode.text ? text : '',
          isActive: isActive.value,
        );
      }
      if (saved == null) {
        _toast('Could not save. Please try again', AppToastType.error);
        return false;
      }
      _toast(
        isEditMode ? 'Client journey updated' : 'Client journey added',
        AppToastType.success,
      );
      await fetchJourneys();
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleActive(String id, bool value) async {
    final saved = await _service.updateJourney(journeyId: id, isActive: value);
    if (saved == null) {
      _toast('Could not update visibility', AppToastType.error);
      return;
    }
    final i = journeys.indexWhere((j) => j['_id'] == id);
    if (i >= 0) journeys[i] = {...journeys[i], 'isActive': value};
  }

  Future<void> deleteJourney(String id) async {
    final ok = await _service.deleteJourney(id);
    if (ok) {
      journeys.removeWhere((j) => j['_id'] == id);
      _toast('Client journey deleted', AppToastType.success);
    } else {
      _toast('Could not delete', AppToastType.error);
    }
  }
}
