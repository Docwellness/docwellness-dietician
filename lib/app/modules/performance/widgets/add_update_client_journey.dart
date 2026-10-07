import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/modules/performance/controllers/client_journey_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _kPlum = Color(0xff851653);
const _kDeep = Color(0xff530630);
const _kTint = Color(0xffFEF6FB);
const _kBorder = Color(0xffF3D3E4);

Future<void> showAddUpdateClientJourney(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 1,
      maxChildSize: 1,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) =>
          AddUpdateClientJourney(scrollController: scrollController),
    ),
  );
}

class AddUpdateClientJourney extends StatelessWidget {
  final ScrollController scrollController;
  const AddUpdateClientJourney({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ClientJourneyController>();

    return Obx(() {
      final mode = c.reviewMode.value;
      return SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    text: c.isEditMode ? 'Edit Client Journey' : 'Add Client Journey',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: const Color(0xff1F2A37),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xff9DA4AE)),
            const SizedBox(height: 8),

            _label('Photos'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _PhotoTile(
                      label: 'Before',
                      picked: c.beforeImage.value,
                      existingUrl: c.existingBeforeUrl.value,
                      onTap: () => c.pickImage(JourneyImageSlot.before),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoTile(
                      label: 'After',
                      picked: c.afterImage.value,
                      existingUrl: c.existingAfterUrl.value,
                      onTap: () => c.pickImage(JourneyImageSlot.after),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _label('Caption (optional)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: c.titleController,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('e.g. 12 weeks · 8 kg lighter'),
              ),
            ),

            const SizedBox(height: 8),
            _label('Client review (optional)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<JourneyReviewMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: _kTint,
                    selectedForegroundColor: _kPlum,
                    foregroundColor: const Color(0xff4D5761),
                    side: const BorderSide(color: _kBorder),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: JourneyReviewMode.none,
                      label: Text('None'),
                    ),
                    ButtonSegment(
                      value: JourneyReviewMode.image,
                      icon: Icon(Icons.image_outlined, size: 18),
                      label: Text('Image'),
                    ),
                    ButtonSegment(
                      value: JourneyReviewMode.text,
                      icon: Icon(Icons.notes_rounded, size: 18),
                      label: Text('Text'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => c.reviewMode.value = s.first,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: const Cubic(0.23, 1, 0.32, 1),
              alignment: Alignment.topCenter,
              child: switch (mode) {
                JourneyReviewMode.image => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _PhotoTile(
                    label: 'Review screenshot or photo',
                    picked: c.reviewImage.value,
                    existingUrl: c.existingReviewUrl.value,
                    aspectRatio: 1.6,
                    onTap: () => c.pickImage(JourneyImageSlot.review),
                  ),
                ),
                JourneyReviewMode.text => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: c.reviewTextController,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 600,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration("What the client said about their journey"),
                  ),
                ),
                JourneyReviewMode.none => const SizedBox(width: double.infinity),
              },
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Visible to clients',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kDeep,
                      ),
                    ),
                  ),
                  Switch(
                    value: c.isActive.value,
                    activeThumbColor: _kPlum,
                    onChanged: (v) => c.isActive.value = v,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: c.isEditMode ? 'Save changes' : 'Add journey',
                isOutline: false,
                isLoading: c.isSaving.value,
                onTap: () async {
                  final saved = await c.save();
                  if (saved && context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kDeep,
      ),
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: Color(0xff9DA4AE)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPlum, width: 1.5),
    ),
  );
}

/// A tappable photo slot: shows the newly picked file, else the saved image
/// (when editing), else an "add" prompt.
class _PhotoTile extends StatelessWidget {
  final String label;
  final dynamic picked; // XFile?
  final String existingUrl;
  final double aspectRatio;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.label,
    required this.picked,
    required this.existingUrl,
    required this.onTap,
    this.aspectRatio = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (picked != null) {
      content = Image.file(File(picked.path as String), fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      content = CachedNetworkImage(imageUrl: existingUrl, fit: BoxFit.cover);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined, color: _kPlum, size: 30),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _kDeep),
            ),
          ),
        ],
      );
    }

    final hasImage = picked != null || existingUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: _kTint, child: content),
              if (hasImage)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${label.split(' ').first.toUpperCase()}  ·  TAP TO CHANGE',
                      style: const TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder, width: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
