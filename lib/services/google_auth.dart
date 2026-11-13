import 'package:google_sign_in/google_sign_in.dart';

import '../constants/auth_config.dart';

/// One-time Google Sign-In setup for the mobile app.
class GoogleAuth {
  const GoogleAuth._();

  static bool _ready = false;

  static Future<GoogleSignInAccount> authenticate() async {
    if (!_ready) {
      final webClientId = AuthConfig.googleWebClientId.trim();
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );
      _ready = true;
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
        description: 'Google sign-in is available on the Android and iOS apps.',
      );
    }

    return GoogleSignIn.instance.authenticate();
  }

  static Future<void> signOut() async {
    if (!_ready) return;
    await GoogleSignIn.instance.signOut();
  }
}
