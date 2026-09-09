import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:docwellnesdoc/app/modules/performance/controllers/performance_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _kPlum = Color(0xff851653);
const _kTint = Color(0xffFEF6FB);

class AddUpdateQuotes extends StatefulWidget {
  final ScrollController scrollController;
  const AddUpdateQuotes({super.key, required this.scrollController});

  @override
  State<AddUpdateQuotes> createState() => _AddUpdateQuotesState();
}

class _AddUpdateQuotesState extends State<AddUpdateQuotes> {
  final PerformanceController controller = Get.find<PerformanceController>();
  final CropController _crop = CropController();
  Uint8List? _rawBytes;
  String? _rawForPath;
  bool _cropping = false;

  Future<void> _loadRaw(String path) async {
    _rawForPath = path;
    final bytes = await File(path).readAsBytes();
    if (mounted) setState(() => _rawBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final raw = controller.quoteRawImage.value;
      final cropped = controller.pickedQuoteImage.value;
      if (raw != null && _rawForPath != raw.path) {
        _rawBytes = null;
        _loadRaw(raw.path);
      }

      return SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: const Color(0xff79747E),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18, left: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  const SizedBox(width: 10),
                  CustomText(
                    text: controller.isQuoteEditMode.value
                        ? 'Edit Quote'
                        : 'Add Quote',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: const Color(0xff1F2A37),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xff9DA4AE)),
            const SizedBox(height: 16),

            // ── Image: crop step / cropped preview / empty ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: raw != null
                  ? _cropStep()
                  : cropped != null
                  ? _croppedPreview(cropped.path)
                  : _emptyImage(),
            ),
            if (cropped == null && raw == null)
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Text(
                  'Optional — add a quote image, text, or both. Images are '
                  'cropped to fit the client carousel.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xff6C737F)),
                ),
              ),

            const SizedBox(height: 16),
            // ── Quote text (3 languages, all shown on one card) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.quoteTextController,
                maxLines: 3,
                minLines: 2,
                decoration: _fieldDecoration('Quote — English'),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.quoteTextHiController,
                maxLines: 3,
                minLines: 2,
                decoration: _fieldDecoration('Quote — हिन्दी'),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.quoteTextMrController,
                maxLines: 3,
                minLines: 2,
                decoration: _fieldDecoration('Quote — मराठी'),
              ),
            ),
            const SizedBox(height: 12),
            // ── Author ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.quoteAuthorController,
                decoration: _fieldDecoration('Author (defaults to DocWellness)'),
              ),
            ),
            const SizedBox(height: 12),
            // ── Category ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: controller.quoteCategory.value,
                decoration: _fieldDecoration('Category'),
                items: PerformanceController.quoteCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.quoteCategory.value = v;
                },
              ),
            ),

            // ── Active toggle ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    text: 'Set Active',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xff384250),
                  ),
                  GestureDetector(
                    onTap: () => controller.isQuotesSelected.value =
                        !controller.isQuotesSelected.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 31,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: controller.isQuotesSelected.value
                            ? _kPlum
                            : Colors.transparent,
                        border: Border.all(
                          color: controller.isQuotesSelected.value
                              ? _kPlum
                              : const Color(0xffCCCCCC),
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: controller.isQuotesSelected.value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: controller.isQuotesSelected.value
                                ? Colors.white
                                : const Color(0xffCCCCCC),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: controller.isQuoteSaving.value
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPlum),
                    )
                  : CustomButton(
                      onTap: () => controller.isQuoteEditMode.value
                          ? controller.updateQuoteById()
                          : controller.addQuote(),
                      text: controller.isQuoteEditMode.value
                          ? 'Save Changes'
                          : 'Add Quote',
                      isOutline: false,
                      fontSize: 14,
                    ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      );
    });
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xff9DA4AE),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: _kTint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xffE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPlum),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  Widget _emptyImage() {
    return GestureDetector(
      onTap: () => controller.pickQuoteImage(),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _kTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 40, color: _kPlum),
              SizedBox(height: 6),
              Text(
                'Add image',
                style: TextStyle(fontSize: 12, color: Color(0xff6C737F)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cropStep() {
    if (_rawBytes == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: _kPlum)),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: Crop(
              controller: _crop,
              image: _rawBytes!,
              aspectRatio: PerformanceController.quoteImageAspect,
              baseColor: const Color(0xff2A1420),
              maskColor: Colors.black.withValues(alpha: 0.55),
              cornerDotBuilder: (size, index) =>
                  const DotControl(color: _kPlum),
              onCropped: (result) {
                setState(() => _cropping = false);
                if (result is CropSuccess) {
                  controller.applyQuoteCrop(result.croppedImage);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag to frame it — locked to the carousel shape',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.clearQuoteImage(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kPlum),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(color: _kPlum)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _cropping
                    ? null
                    : () {
                        setState(() => _cropping = true);
                        _crop.crop();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _kPlum,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cropping
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Use this crop'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _croppedPreview(String path) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: PerformanceController.quoteImageAspect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => controller.pickQuoteImage(),
              icon: const Icon(Icons.crop_rotate, size: 18, color: _kPlum),
              label: const Text('Change', style: TextStyle(color: _kPlum)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => controller.clearQuoteImage(),
              icon: const Icon(
                Icons.close,
                size: 18,
                color: Color(0xffB42318),
              ),
              label: const Text(
                'Remove',
                style: TextStyle(color: Color(0xffB42318)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
