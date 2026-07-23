import 'package:flutter/material.dart';

enum AppToastType { success, error, warning }

class _ToastStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _ToastStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}

const Map<AppToastType, _ToastStyle> _toastStyles = {
  AppToastType.success: _ToastStyle(
    background: Color(0xffE7F8EF),
    foreground: Color(0xff15803D),
    icon: Icons.check_circle_rounded,
  ),
  AppToastType.error: _ToastStyle(
    background: Color(0xffFDECEC),
    foreground: Color(0xffB42318),
    icon: Icons.error_rounded,
  ),
  AppToastType.warning: _ToastStyle(
    background: Color(0xffFEF7E0),
    foreground: Color(0xff92600B),
    icon: Icons.warning_rounded,
  ),
};

OverlayEntry? _currentToastEntry;

/// Small, auto-dismissing (2s) notification anchored to the bottom of the
/// screen - the single in-app replacement for Get.snackbar() everywhere in
/// this app. Pass Get.overlayContext! from a GetxController (no local
/// BuildContext available) or the local context from a View/Widget - both
/// resolve to the same root overlay, so it works identically either way,
/// including right after a Get.back() pop.
void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.error,
}) {
  // Only one toast on screen at a time - a fast double-tap shouldn't stack
  // duplicate banners.
  _currentToastEntry?.remove();
  _currentToastEntry = null;

  // Overlay.of(context) throws "No Overlay widget found" if called during a
  // route transition or right after the context's tree has been torn down -
  // this happened for real in production (Sentry: FlutterError: No Overlay
  // widget found, in showAppToast) when this was called from inside a catch
  // block right as a screen was mid-navigation. A dropped toast is much
  // better than an uncaught exception that skips whatever cleanup (e.g.
  // resetting a loading flag) was supposed to run right after this call.
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) {
    debugPrint('showAppToast: no Overlay found, dropping message: $message');
    return;
  }
  final style = _toastStyles[type]!;
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _AppToast(
      message: message,
      style: style,
      onDismissed: () {
        if (_currentToastEntry == entry) {
          _currentToastEntry = null;
        }
        entry.remove();
      },
    ),
  );

  _currentToastEntry = entry;
  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  final String message;
  final _ToastStyle style;
  final VoidCallback onDismissed;

  const _AppToast({
    required this.message,
    required this.style,
    required this.onDismissed,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.style.background,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      widget.style.icon,
                      color: widget.style.foreground,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.style.foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
