import 'package:flutter/material.dart';
import 'package:masjid_app/examples/data/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  static late SharedPreferences _preferences;

  static const _keyEmail = 'email';
  static const _displayName = 'displayName';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setEmail(String email) async =>
      await _preferences.setString(_keyEmail, email);

  static String? getUserEmail() => _preferences.getString(_keyEmail);

  static Future setDisplayName(String displayName) async =>
      await _preferences.setString(_displayName, displayName);

  static String? getDisplayName() => _preferences.getString(_displayName);

  // Method to clear user data on logout
  static Future clearThePreferences() async {
    await _preferences.remove(_keyEmail);
    await _preferences.remove(_displayName);
  }

  Future<int> fetchNotificationCountFromApi() async {
    try {
      CollectionReference newsCollection =
          FirebaseFirestore.instance.collection('news');

      QuerySnapshot querySnapshot =
          await newsCollection.where('seen', isEqualTo: false).get();

      int notificationCount = querySnapshot.size;

      return notificationCount;
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
      return 0;
    }
  }

  Future<NotificationCountNotifier> initializeNotifier() async {
    int firestoreNotificationCount = await fetchNotificationCountFromApi();
    return NotificationCountNotifier()
      ..setNotificationCount(firestoreNotificationCount);
  }
}
