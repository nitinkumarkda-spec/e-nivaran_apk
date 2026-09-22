import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = "https://kdakota.rajasthan.gov.in/enivaran";

  static String baseUrl = defaultBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString("dept_server_url") ?? defaultBaseUrl;
  }

  static Future<void> updateBaseUrl(String newUrl) async {
    baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("dept_server_url", baseUrl);
  }

  static String get apiBase => "$baseUrl/api";
  static String get departmentLoginUrl => "$baseUrl/auth/department-login?dept_app=1";
  static String get adminDashboardUrl => "$baseUrl/admin/dashboard";
  static String get complaintsUrl => "$baseUrl/admin/complaints";
  static String get profileUrl => "$baseUrl/admin/profile";
}
