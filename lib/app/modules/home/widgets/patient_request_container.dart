import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class PatientRequestContainer extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final String status;
  final String? avatarUrl;
  final String goal;
  const PatientRequestContainer({
    super.key,
    required this.title,
    required this.onTap,
    required this.status,
    this.avatarUrl,
    required this.goal,
  });

  // Get status label based on status
  String _getStatusLabel() {
    switch (status) {
      case 'Paid':
        return 'PAID';
      case 'PaymentSubmitted':
        return 'PENDING REVIEW';
      case 'PaymentRequested':
        return 'AWAITING PAYMENT';
      case 'Unpaid':
      default:
        return 'UNPAID';
    }
  }

  // Get status colors based on status
  Map<String, Color> _getStatusColors() {
    switch (status) {
      case 'Paid':
        return {
          'bg': Color(0xffD1FAE5),
          'border': Color(0xff10B981),
          'text': Color(0xff059669),
        };
      case 'PaymentSubmitted':
        return {
          'bg': Color(0xffFEF3C7),
          'border': Color(0xffF59E0B),
          'text': Color(0xffD97706),
        };
      case 'PaymentRequested':
        return {
          'bg': Color(0xffFDF2FA),
          'border': Color(0xffFCE7F6),
          'text': Color(0xffEF45B2),
        };
      case 'Unpaid':
      default:
        return {
          'bg': Color(0xffF9FAFB),
          'border': Color(0xffF3F4F6),
          'text': Color(0xff4D5761),
        };
    }
  }

  // Colorful background based on first letter
  static const List<Color> _avatarColors = [
    Color(0xffE8D5F5), // lavender
    Color(0xffD5EAF5), // sky blue
    Color(0xffF5D5E8), // pink
    Color(0xffD5F5E8), // mint
    Color(0xffF5EAD5), // peach
    Color(0xffF5D5D5), // salmon
    Color(0xffD5F5F5), // cyan
    Color(0xffF5F5D5), // lemon
    Color(0xffE5D5F5), // purple
    Color(0xffD5F5DA), // green
  ];

  static const List<Color> _avatarTextColors = [
    Color(0xff6B21A8), // purple
    Color(0xff1D4ED8), // blue
    Color(0xffBE185D), // pink
    Color(0xff047857), // green
    Color(0xffC2410C), // orange
    Color(0xffDC2626), // red
    Color(0xff0E7490), // teal
    Color(0xff854D0E), // amber
    Color(0xff7C3AED), // violet
    Color(0xff15803D), // emerald
  ];

  Color _getAvatarBg() {
    final idx = title.isNotEmpty
        ? title.codeUnitAt(0) % _avatarColors.length
        : 0;
    return _avatarColors[idx];
  }

  Color _getAvatarTextColor() {
    final idx = title.isNotEmpty
        ? title.codeUnitAt(0) % _avatarTextColors.length
        : 0;
    return _avatarTextColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors();
    final letter = (title.isNotEmpty ? title[0] : 'U').toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _getAvatarBg(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          placeholder: (context, url) => Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getAvatarTextColor(),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getAvatarTextColor(),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getAvatarTextColor(),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: title,
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff1F2A37),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  CustomText(
                    text: goal,
                    fontWeight: FontWeight.w400,
                    fontSize: 14.5,
                    color: Color(0xff6C737F),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colors['bg'],
                      border: Border.all(color: colors['border']!, width: 1.3),
                    ),
                    child: CustomText(
                      text: _getStatusLabel(),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: colors['text']!,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xff851653)),
            SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
