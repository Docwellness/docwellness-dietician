import 'dart:developer';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Requests the photo-library and microphone permissions together, at app
/// launch - called right after the notification permission prompt in
/// main.dart's _bootstrap so all of the app's runtime permissions surface
/// as one sequence on first launch instead of trickling in later (photos on
/// first Photo Gallery upload, microphone on first chat voice note).
Future<void> requestStartupPermissions() async {
  try {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (!photos.isGranted && !photos.isLimited) {
        await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      await Permission.photosAddOnly.request();
    }

    await Permission.microphone.request();
  } catch (e) {
    log('requestStartupPermissions failed: $e');
  }
}
