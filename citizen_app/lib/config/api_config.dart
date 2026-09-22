import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = "https://kdakota.rajasthan.gov.in/enivaran";

  static String baseUrl = defaultBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString("server_url") ?? defaultBaseUrl;
  }

  static Future<void> updateBaseUrl(String newUrl) async {
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("server_url", newUrl);
  }

  static String get apiBase => "$baseUrl/api";
  static String get citizenLoginUrl => "$baseUrl/auth/login";
  static String get citizenRegisterComplaintUrl => "$baseUrl/citizen/store";
  static String get citizenComplaintsUrl => "$baseUrl/citizen/complaints/data";
}
