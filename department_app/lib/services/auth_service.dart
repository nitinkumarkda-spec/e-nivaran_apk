import 'package:shared_preferences/shared_preferences.dart';

/// Service class to handle officer authentication session and preferences locally.
class AuthService {
  static const String keyIsLoggedIn = 'is_dept_logged_in';
  static const String keyUserEmail = 'dept_user_email';
  static const String keyUserRole = 'dept_user_role';

  /// Check whether the department officer is currently logged in.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  /// Get the stored officer email/username.
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserEmail) ?? 'officer@kda.rajasthan.gov.in';
  }

  /// Get the stored officer role/designation code (e.g., JEN, AEN, XEN).
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserRole) ?? 'JEN';
  }

  /// Persist officer credentials upon successful login.
  static Future<void> saveSession({
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserEmail, email);
    await prefs.setString(keyUserRole, role);
    await prefs.setBool(keyIsLoggedIn, true);
  }

  /// Clear the login session when logging out.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsLoggedIn);
  }
}
