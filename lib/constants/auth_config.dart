/// Values you copy from the Firebase console. No backend scripts live here.
class AuthConfig {
  const AuthConfig._();

  /// Web client ID created when Google sign-in is enabled.
  ///
  /// Firebase Console → Authentication → Sign-in method → Google →
  /// Web SDK configuration → Web client ID.
  ///
  /// Leave this empty until that client exists. Android needs it to return
  /// an ID token that Firebase Auth can verify.
  static const String googleWebClientId =
      '559873790659-uhi0gs0gecbllmjgkfa041vk6b6pbfmt.apps.googleusercontent.com';
}
