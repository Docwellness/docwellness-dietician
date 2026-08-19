package fit.docdesk.app

import io.flutter.embedding.android.FlutterFragmentActivity

// Phase 9, P9-D7: local_auth's Android implementation requires the host
// Activity to be a FlutterFragmentActivity (it shows the biometric prompt
// as a DialogFragment) - a plain FlutterActivity throws at runtime the
// first time authenticate() is called.
class MainActivity : FlutterFragmentActivity()
