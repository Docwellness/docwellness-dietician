import 'dart:async';

import 'package:flutter/foundation.dart';

/// Disposes [notifiers] (TextEditingControllers etc.) after the route
/// transition has finished.
///
/// GetX deletes a route's controller the moment the route is removed, but the
/// outgoing screen keeps building/animating for the length of the transition
/// (and its text fields keep listening to their controllers). Disposing
/// synchronously in GetxController.onClose therefore throws "A
/// TextEditingController was used after being disposed" and render-object
/// 'attached' assertions on a screen that's about to vanish.
void disposeAfterTransition(Iterable<ChangeNotifier> notifiers) {
  final list = notifiers.toList();
  Timer(const Duration(seconds: 2), () {
    for (final n in list) {
      n.dispose();
    }
  });
}
