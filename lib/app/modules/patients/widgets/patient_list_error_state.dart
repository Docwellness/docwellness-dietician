import 'package:flutter/material.dart';

/// Shared error state for the Ongoing/New/Past patient list tabs
/// (AI_EXECUTION_PLAN.md Phase 7, P7-04) - a fetch failure previously just
/// debugPrint'd and left the list empty, rendering identically to
/// "genuinely no patients" with no retry affordance.
class PatientListErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String message;

  const PatientListErrorState({
    super.key,
    required this.onRetry,
    this.message = "Couldn't load patients. Check your connection and try again.",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xffDC2626),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff6C737F), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Retry',
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: const Color(0xff851653),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
