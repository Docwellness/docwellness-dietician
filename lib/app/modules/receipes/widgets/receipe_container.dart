import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class ReceipeContainer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subTitle;
  final VoidCallback onTap;

  const ReceipeContainer({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subTitle,
    required this.onTap,
  });

  bool get _isNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: 121.33,
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
                maxLines: 1,
              ),
            ),
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
