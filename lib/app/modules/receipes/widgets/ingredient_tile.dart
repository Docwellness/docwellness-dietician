import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

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
