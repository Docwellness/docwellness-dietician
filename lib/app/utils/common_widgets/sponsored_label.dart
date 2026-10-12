import 'package:flutter/material.dart';

/// Disclosure for a paid product placement. The backend sends `sponsoredLabel`
/// only while a commercial image is live, so this renders nothing otherwise.
///
/// [SponsoredLabel] is the quiet inline pill used next to a thumbnail's text.
/// [SponsoredBadge] is the overlay used on top of a large image.
class SponsoredLabel extends StatelessWidget {
  final String? label;
  const SponsoredLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = label?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xffF2F4F7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: Color(0xff475467),
        ),
      ),
    );
  }
}

class SponsoredBadge extends StatelessWidget {
  final String? label;
  const SponsoredBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = label?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC1F2A37),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
