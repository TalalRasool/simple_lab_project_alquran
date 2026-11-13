import 'package:firebase_core/firebase_core.dart';

/// True when Firebase was initialized. Widget tests and desktop runs may not have it.
bool firebaseAppsReady() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
