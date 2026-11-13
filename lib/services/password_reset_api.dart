import 'package:cloud_functions/cloud_functions.dart';

/// Calls the password-reset Cloud Functions. The app never sees the OTP hash
/// or the mail credentials.
class PasswordResetApi {
  PasswordResetApi({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<int> requestCode(String email) {
    return _call('requestPasswordResetCode', {'email': email.trim()});
  }

  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    final data = await _raw('verifyPasswordResetCode', {
      'email': email.trim(),
      'code': code.trim(),
    });
    final token = data['resetToken'];
    if (token is! String || token.isEmpty) {
      throw PasswordResetException('That code is incorrect or has expired.');
    }
    return token;
  }

  Future<void> confirmPassword({
    required String resetToken,
    required String password,
  }) async {
    await _raw('confirmPasswordReset', {
      'resetToken': resetToken,
      'password': password,
    });
  }

  Future<int> _call(String name, Map<String, Object?> body) async {
    final data = await _raw(name, body);
    final retry = data['retryAfterSeconds'];
    if (retry is num) return retry.toInt();
    return 60;
  }

  Future<Map<String, Object?>> _raw(
    String name,
    Map<String, Object?> body,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(body);
      final data = result.data;
      if (data is Map) {
        return Map<String, Object?>.from(data);
      }
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw PasswordResetException(_message(error));
    }
  }

  String _message(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'failed-precondition':
        return 'Password reset email is not configured on the server yet.';
      case 'invalid-argument':
        return error.message ?? 'Check the details and try again.';
      case 'resource-exhausted':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'not-found':
      case 'unavailable':
        return 'Password reset is not available yet. The reset service still needs to be deployed.';
      case 'permission-denied':
        return 'That code is incorrect or has expired.';
      default:
        return error.message ?? 'Could not complete the password reset.';
    }
  }
}

class PasswordResetException implements Exception {
  const PasswordResetException(this.message);

  final String message;
}
