import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Detects offline->online transitions and notifies whoever's currently
/// listening - this is how a screen that loaded with empty/cached data
/// while offline gets a chance to refetch once the connection actually
/// comes back, instead of staying stale until the user manually
/// pulls-to-refresh or navigates away and back.
///
/// Screens register their own refresh callback (typically in onInit) and
/// unregister it (in onClose) - only whichever screen is currently mounted
/// ends up listening, so this refreshes "whatever's visible" without a
/// central registry of every controller in the app.
class ConnectivityService extends GetxService {
  final _callbacks = <VoidCallback>{};
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOffline = false;

  Future<ConnectivityService> init() async {
    final initial = await Connectivity().checkConnectivity();
    _wasOffline = _isOffline(initial);
    _sub = Connectivity().onConnectivityChanged.listen(_onChange);
    return this;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  bool _isOffline(List<ConnectivityResult> results) =>
      results.every((r) => r == ConnectivityResult.none);

  void _onChange(List<ConnectivityResult> results) {
    final offline = _isOffline(results);
    if (_wasOffline && !offline) {
      for (final cb in [..._callbacks]) {
        cb();
      }
    }
    _wasOffline = offline;
  }

  void registerOnReconnected(VoidCallback onReconnected) {
    _callbacks.add(onReconnected);
  }

  void unregister(VoidCallback onReconnected) {
    _callbacks.remove(onReconnected);
  }
}
