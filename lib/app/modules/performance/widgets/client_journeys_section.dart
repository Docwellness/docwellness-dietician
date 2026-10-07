import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/modules/performance/controllers/client_journey_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/widgets/add_update_client_journey.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _kPlum = Color(0xff851653);
const _kDeep = Color(0xff530630);
const _kTint = Color(0xffFDF2FA);

/// Performance > "Client Journeys": the before/after stories (with an
/// optional image or text review) shown on the dietician's patients' Home
/// screens. Patients only see the before/after pair on Home and open the
/// review in a bottom sheet.
class ClientJourneysSection extends StatelessWidget {
  const ClientJourneysSection({super.key});

  static const double _cardWidth = 196;
  static const double _cardHeight = 176;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ClientJourneyController>()
        ? Get.find<ClientJourneyController>()
        : Get.put(ClientJourneyController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CustomText(
                text: 'Client Journeys',
                fontWeight: FontWeight.w400,
                fontSize: 17,
                color: Color(0xff9F1561),
              ),
              SizedBox(width: 15),
              Icon(Icons.arrow_forward, color: _kDeep, size: 21),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Before & after stories your clients see on Home',
            style: TextStyle(fontSize: 12, color: Color(0xff6C737F)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: _cardHeight,
            child: Obx(() {
              final items = controller.journeys.toList();
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _AddTile(
                    onTap: () {
                      controller.resetForm();
                      showAddUpdateClientJourney(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  if (controller.isLoading.value && items.isEmpty)
                    const SizedBox(
                      width: _cardWidth,
                      child: Center(
                        child: CircularProgressIndicator(color: _kPlum),
                      ),
                    )
                  else
                    for (final journey in items) ...[
                      _JourneyTile(journey: journey, controller: controller),
                      const SizedBox(width: 8),
                    ],
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: ClientJourneysSection._cardHeight,
        decoration: BoxDecoration(
          color: _kTint,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xffFCFCFD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffF3F4F6)),
              ),
              child: const Icon(Icons.add, color: Color(0xffEF45B2), size: 34),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add journey',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _kDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final Map<String, dynamic> journey;
  final ClientJourneyController controller;
  const _JourneyTile({required this.journey, required this.controller});

  @override
  Widget build(BuildContext context) {
    final id = journey['_id'] as String? ?? '';
    final title = (journey['title'] as String? ?? '').trim();
    final isActive = journey['isActive'] != false;
    final reviewType = journey['reviewType'] as String? ?? 'none';

    return Opacity(
      opacity: isActive ? 1 : 0.6,
      child: Container(
        width: ClientJourneysSection._cardWidth,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _kTint,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _thumb(journey['beforeImageUrl'])),
                  const SizedBox(width: 4),
                  Expanded(child: _thumb(journey['afterImageUrl'])),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.isEmpty ? 'Untitled' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDeep,
                    ),
                  ),
                ),
                if (reviewType != 'none')
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      reviewType == 'image'
                          ? Icons.image_outlined
                          : Icons.format_quote_rounded,
                      size: 16,
                      color: _kPlum,
                    ),
                  ),
                if (!isActive)
                  const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.visibility_off_outlined,
                      size: 16,
                      color: Color(0xff6C737F),
                    ),
                  ),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: const Icon(Icons.more_vert, color: _kDeep),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          controller.prefillForEdit(journey);
                          showAddUpdateClientJourney(context);
                        case 'toggle':
                          controller.toggleActive(id, !isActive);
                        case 'delete':
                          _confirmDelete(context, id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(isActive ? 'Hide from clients' : 'Show to clients'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(dynamic url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: (url as String?) ?? '',
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Color(0xffF8E3F0)),
        errorWidget: (_, __, ___) => const ColoredBox(
          color: Color(0xffF8E3F0),
          child: Icon(Icons.image_outlined, color: Color(0xffC48AAA)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const CustomText(
          text: 'Delete client journey',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
        content: const CustomText(
          text: 'This removes its photos and review. Clients will no longer see it.',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Color(0xff4D5761),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const CustomText(
              text: 'Cancel',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _kPlum,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.deleteJourney(id);
            },
            child: const CustomText(
              text: 'Delete',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xffB42318),
            ),
          ),
        ],
      ),
    );
  }
}
