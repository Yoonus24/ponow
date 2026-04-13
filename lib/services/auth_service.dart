// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/session_service.dart';

class AuthService {
  // IMPORTANT: match this with backend expectation
  static const String domain = "localhost:3000";

  /// =========================
  /// LOGIN
  /// =========================
  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
    required String browserSessionId,
  }) async {
    try {
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';

      final cleanDomain = domain.trim().toLowerCase();

      print("🔥 LOGIN DEBUG");
      print("USERNAME: $username");
      print("DOMAIN SENT: $cleanDomain");

      final response = await DioClient.dio.post(
        "/login",
        options: Options(
          headers: {
            "Authorization": basicAuth,
            "x-domain": cleanDomain,
            "x-browser-session-id": browserSessionId,
          },
        ),
      );

      final data = response.data;
      print("✅ LOGIN RESPONSE: $data");

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', data['access_token']);
      await prefs.setString('username', data['username']);
      await prefs.setString('role', data['role_name'] ?? '');
      await prefs.setString(
        'permissions',
        jsonEncode(data['permissions'] ?? {}),
      );
      await prefs.setString('browser_session_id', browserSessionId);

      return data;
    } on DioException catch (e) {
      final error = e.response?.data;
      print("❌ Login failed: $error");

      if (e.response?.statusCode == 401) {
        throw Exception("INVALID_CREDENTIALS");
      } else if (e.response?.statusCode == 403) {
        throw Exception("SESSION_EXISTS");
      } else if (e.response?.statusCode == 404) {
        throw Exception("TENANT_NOT_FOUND");
      } else {
        throw Exception("LOGIN_FAILED");
      }
    } catch (e) {
      print("❌ Unexpected login error: $e");
      throw Exception("LOGIN_FAILED");
    }
  }

  /// =========================
  /// LOGOUT
  /// =========================
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final browserId = prefs.getString('browser_session_id');

      await DioClient.dio.post(
        "/logout",
        options: Options(
          headers: {"x-browser-session-id": browserId, "x-domain": domain},
        ),
      );
    } catch (e) {
      print("❌ Logout failed: $e");

      // Do NOT clear session if backend logout fails
      throw Exception("LOGOUT_FAILED");
    }

    // Stop session ping
    SessionService.stop();

    //  Clear local session
    await clearSession();
  }

  /// =========================
  /// KEEP SESSION ALIVE (PING)
  /// =========================
  static Future<void> ping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final browserId = prefs.getString('browser_session_id');
      final token = prefs.getString('token');

      print("🔄 PING START");
      print("TOKEN: $token");
      print("BROWSER ID: $browserId");

      await DioClient.dio.post(
        "/ping",
        options: Options(
          headers: {
            "x-domain": domain,
            "x-browser-session-id": browserId,
            // Authorization handled by interceptor
          },
        ),
      );

      print("✅ PING SUCCESS");
    } catch (e) {
      // ❌ Do NOT logout here
      print("⚠️ Ping failed, ignoring: $e");
    }
  }

  /// =========================
  /// CHECK LOGIN STATE
  /// =========================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  /// =========================
  /// CLEAR SESSION (LOCAL)
  /// =========================
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('permissions');
    await prefs.remove('token');
    await prefs.remove('username');
    await prefs.remove('browser_session_id');

    print("🧹 Session cleared");
  }
}
