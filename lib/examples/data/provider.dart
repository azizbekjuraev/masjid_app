import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationCountNotifier with ChangeNotifier {
  int _notificationCount = 0;

  int get notificationCount => _notificationCount;

  void setNotificationCount(int count) async {
    _notificationCount = count;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('notificationCount', count);
  }
}
