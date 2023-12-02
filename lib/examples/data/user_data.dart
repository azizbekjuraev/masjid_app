import 'package:shared_preferences/shared_preferences.dart';

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
}
