import 'package:shared_preferences/shared_preferences.dart';

class LocalDatasource {
  static const _keyNotificationsEnabled = 'notifications_enabled';

  final SharedPreferences _prefs;

  LocalDatasource(this._prefs);

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_keyNotificationsEnabled, enabled);
}
