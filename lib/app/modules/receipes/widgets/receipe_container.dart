import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class ReceipeContainer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subTitle;
  final VoidCallback onTap;
  // Defaults to the historical fixed size so the Home screen's horizontal
  // list (which gives this widget unbounded width) keeps its current layout.
  // Callers laid out in a constrained cell (e.g. a GridView column) should
  // pass the cell's actual width so the image fills it instead of floating
  // at a fixed size that only coincidentally matches one screen width.
  final double imageWidth;
  // Compact per-ingredient portion strings from the backend, e.g.
  // ["Puffed Rice 40g", "Peanuts 15g"]. When non-empty the widget shows
  // up to 2 ingredients with portions below the title instead of just
  // the "N ingredients" count. Falls back to subTitle when empty.
  final List<String> ingredientSummary;
  // Total card height. Defaults to the historical 192 (matches the Home
  // screen's recipe-category rail, whose short category names/counts
  // never needed more room). A caller whose title text runs longer (e.g.
  // full recipe names in a browse grid) should pass more - see
  // recipe_list_by_filter_view.dart, which found 192 too tight to
  // reliably fit a 2-line title plus the ingredient-summary subtitle
  // without cropping text early (real Roboto line-height ran past what
  // that budget assumed).
  final double height;

  const ReceipeContainer({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subTitle,
    required this.onTap,
    this.imageWidth = 121.33,
    this.ingredientSummary = const [],
    this.height = 192,
  });

  bool get _isNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: imageWidth,
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isEmpty
                    ? _buildPlaceholder()
                    : _isNetworkImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xffFCCEEF),
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      ),
              ),
            ),
            SizedBox(height: 4),
            Flexible(
              child: CustomText(
                text: title,
                color: Color(0xff1D1B20),
                fontWeight: FontWeight.w500,
                fontSize: 15.5,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 2),
            if (ingredientSummary.isNotEmpty)
              Flexible(
                child: CustomText(
                  text: ingredientSummary.take(2).join(' • '),
                  color: Color(0xff49454F),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            else
              Flexible(
                child: CustomText(
                  text: subTitle,
                  color: Color(0xff49454F),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xffFDF2FA),
      child: const Center(
        child: Icon(Icons.restaurant_menu, size: 40, color: Color(0xffFCCEEF)),
      ),
    );
  }
}
