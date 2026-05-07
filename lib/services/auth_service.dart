// ignore_for_file: unused_local_variable, avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:purchaseorders2/core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/session_service.dart';
import 'package:purchaseorders2/core/storage/secure_storage_service.dart';

class AuthService {
   static String get domain => Env.domain;

  // LOGIN
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

      final prefs = await SharedPreferences.getInstance();

      //  STORE TOKEN SECURELY
      await SecureStorageService.saveToken(data['access_token']);

      //  KEEP NON-SENSITIVE DATA IN PREFS
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

  // LOGOUT
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

    // Clear local session
    await clearSession();
  }

  // KEEP SESSION ALIVE (PING)
  static Future<void> ping() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final browserId = prefs.getString('browser_session_id');

      //  GET TOKEN FROM SECURE STORAGE (if needed later)
      final token = await SecureStorageService.getToken();

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
    } catch (e) {
      // Do NOT logout here
      print("⚠️ Ping failed, ignoring: $e");
    }
  }

  // CHECK LOGIN STATE
  static Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.getToken();
    return token != null;
  }

  // CLEAR SESSION (LOCAL)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // CLEAR SECURE TOKEN
    await SecureStorageService.clearToken();

    // CLEAR OTHER DATA
    await prefs.remove('permissions');
    await prefs.remove('username');
    await prefs.remove('browser_session_id');

    print("🧹 Session cleared");
  }
}
