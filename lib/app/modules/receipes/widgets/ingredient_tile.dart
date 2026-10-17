import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class IngredientTile extends StatelessWidget {
  final Ingredient? ingredient;
  final double servingsMultiplier;
  final VoidCallback? onRefreshImageTap;
  final bool isUploading;
  final String? translatedName;
  final String? translatedDescription;

  const IngredientTile({
    super.key,
    this.ingredient,
    this.servingsMultiplier = 1.0,
    this.onRefreshImageTap,
    this.isUploading = false,
    this.translatedName,
    this.translatedDescription,
  });

  /// Formats a quantity for display without ever collapsing a real nonzero
  /// value down to "0" - whole numbers show with no decimals, fractional
  /// values (common for cup/tbsp/tsp, e.g. 0.25 cup) show with up to 2
  /// decimals, trailing zeros trimmed.
  static String _formatQuantity(double q) {
    if (q == q.roundToDouble()) return q.toStringAsFixed(0);
    var s = q.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  /// Opens the admin-set sponsor link in the external browser. Only plain
  /// http(s) links are ever launched.
  static Future<void> _openBuyLink(String link) async {
    final uri = Uri.tryParse(link.trim());
    final ok = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    var launched = false;
    if (ok) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (!launched) {
      Get.snackbar(
        'Could not open link',
        'The buy link could not be opened.',
        backgroundColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = translatedName ?? ingredient?.name ?? 'Ingredient';
    final category = ingredient?.category ?? 'Other';
    final priceLevel = ingredient?.priceLevel ?? '₹₹';
    final quantity = (ingredient?.quantity ?? 100) * servingsMultiplier;
    final unit = ingredient?.unit ?? 'g';
    final description =
        translatedDescription ??
        ingredient?.description ??
        'Supporting line text lorem ipsum dolor sit amet, consectetur.';
    final uploadedImage = ingredient?.image;
    final hasNetworkImage =
        uploadedImage != null && uploadedImage.trim().isNotEmpty;
    final buyLink = ingredient?.buyLink?.trim();
    final hasBuyLink = buyLink != null && buyLink.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
      child: Column(
        children: [
          SizedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 80,
                        width: 80,
                        child: hasNetworkImage
                            ? Image.network(
                                uploadedImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xffF9FAFB),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 36,
                                    color: Color(0xff98A2B3),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xffF9FAFB),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 36,
                                  color: Color(0xff98A2B3),
                                ),
                              ),
                      ),
                    ),
                    if (onRefreshImageTap != null)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: InkWell(
                          onTap: isUploading ? null : onRefreshImageTap,
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xff530630),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isUploading
                                ? const Padding(
                                    padding: EdgeInsets.all(5),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: name,

                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff384250),

                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 10),
                      CustomText(
                        text:
                            "$category • $priceLevel • ${_formatQuantity(quantity)}$unit",

                        color: Color(0xff6C737F),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,

                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 1),
                      CustomText(
                        text: description,

                        color: Color(0xff6C737F),
                        fontWeight: FontWeight.w400,

                        fontSize: 13,

                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (hasBuyLink) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _openBuyLink(buyLink),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffFEF6FB),
                              border: Border.all(color: const Color(0xffFCCEEF)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 14,
                                  color: Color(0xff530630),
                                ),
                                SizedBox(width: 4),
                                CustomText(
                                  text: 'Buy',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff530630),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Divider(thickness: 0.7, color: Color(0xffFCCEEF)),
        ],
      ),
    );
  }
}
