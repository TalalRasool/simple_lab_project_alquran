import 'package:cloud_firestore/cloud_firestore.dart';

/// Owner-only profile documents at `users/{uid}`.
class UserProfileStore {
  UserProfileStore({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Creates `users/{uid}` the first time this Google account signs in.
  ///
  /// A later sign-in leaves the existing document, including `createdAt`, as it is.
  Future<void> createGoogleUserIfNeeded({
    required String uid,
    required String name,
    required String email,
  }) async {
    final ref = _users.doc(uid);
    final existing = await ref.get();
    if (existing.exists) return;

    await ref.set({
      'uid': uid,
      'name': name,
      'email': email,
      'provider': 'google',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasCompleteProfile(String uid) async {
    final data = (await _users.doc(uid).get()).data();
    final username = data?['username'];
    if (username is String && username.trim().length >= 3) return true;
    final nationalId = data?['nationalId'];
    return nationalId is String && RegExp(r'^\d{13}$').hasMatch(nationalId);
  }

  /// Reserves [username] without changing the Firebase UID.
  ///
  /// Older accounts keep their 13-digit `nationalId`. New accounts store a
  /// separate `username`.
  Future<void> reserveUsername({
    required String uid,
    required String username,
    required String email,
  }) async {
    final trimmed = username.trim();
    final key = trimmed.toLowerCase();
    if (!RegExp(r'^[a-z][a-z0-9_]{2,19}$').hasMatch(key)) {
      throw ArgumentError('Invalid User ID');
    }
    final nameRef = _db.collection('usernames').doc(key);
    final userRef = _users.doc(uid);
    await _db.runTransaction((transaction) async {
      final taken = await transaction.get(nameRef);
      final owner = taken.data()?['uid'];
      if (taken.exists && owner != uid) {
        throw const UsernameTakenException();
      }
      final existing = await transaction.get(userRef);
      transaction.set(nameRef, {'uid': uid});
      transaction.set(userRef, {
        'uid': uid,
        'username': trimmed,
        'name': trimmed,
        'email': email,
        'provider': 'password',
        'updatedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> save({
    required String uid,
    required String name,
    required String nationalId,
    required String email,
    required String provider,
    String? photoUrl,
  }) async {
    final ref = _users.doc(uid);
    final existing = await ref.get();
    await ref.set({
      'name': name,
      'nationalId': nationalId,
      'email': email,
      'provider': provider,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}
