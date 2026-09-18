import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyServerIP = 'serverIP';
  static const String _keyPort = 'port';
  static const String _keyDbName = 'dbName';
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyUserId = 'userId';
  static const String _keyDeviceId = 'deviceId';
  static const String _keyIsUserAdd = 'isUserAdd';

  Future<String?> getServerIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerIP);
  }

  Future<void> setServerIP(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerIP, value);
  }

  Future<int> getPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPort) ?? 3306;
  }

  Future<void> setPort(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPort, value);
  }

  Future<String?> getDbName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDbName);
  }

  Future<void> setDbName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDbName, value);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<void> setUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, value);
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  Future<void> setPassword(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, value);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<void> setUserId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, value);
  }

  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeviceId);
  }

  Future<void> setDeviceId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceId, value);
  }

  Future<bool> getIsUserAdd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsUserAdd) ?? false;
  }

  Future<void> setIsUserAdd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsUserAdd, value);
  }

  Future<bool> hasConnectionSettings() async {
    final serverIP = await getServerIP();
    final dbName = await getDbName();
    final username = await getUsername();
    final password = await getPassword();

    return serverIP != null &&
           serverIP.isNotEmpty &&
           dbName != null &&
           dbName.isNotEmpty &&
           username != null &&
           username.isNotEmpty &&
           password != null &&
           password.isNotEmpty;
  }
}