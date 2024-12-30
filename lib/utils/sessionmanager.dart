import 'package:shared_preferences/shared_preferences.dart';

// Taken from Lee's github repo lectures

class SessionManager {
  static const String _sessionKey = 'sessionToken';
  static const String _usernameKey = 'usernameToken';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString(_sessionKey);
    return sessionToken != null;
  }

  static Future<String> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey) ?? '';
  }

  static Future<String> getUsernameString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? '';
  }

  static Future<void> setSessionToken(String token, String user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, token);
    await prefs.setString(_usernameKey, user);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_usernameKey);
  }
}
