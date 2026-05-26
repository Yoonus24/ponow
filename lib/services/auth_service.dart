import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:purchaseorders2/core/config/env.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/core/storage/secure_storage_service.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/session_service.dart';

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

      // STORE TOKEN SECURELY
      await SecureStorageService.saveToken(data['access_token']);

      // STORE USER DATA SECURELY
      await SecureStorageService.saveUsername(data['username'] ?? '');

      await SecureStorageService.saveRole(data['role_name'] ?? '');

      await SecureStorageService.savePermissions(
        jsonEncode(data['permissions'] ?? {}),
      );

      await SecureStorageService.saveBrowserSessionId(browserSessionId);

      return data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        throw const AppException(
          "Invalid username or password",
          statusCode: 401,
        );
      }

      if (statusCode == 403) {
        throw const AppException(
          "Already logged in another device",
          statusCode: 403,
        );
      }

      if (statusCode == 404) {
        throw const AppException("Tenant not found", statusCode: 404);
      }

      rethrow;
    } catch (_) {
      throw const AppException("Login failed. Please try again");
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    try {
      final browserId = await SecureStorageService.getBrowserSessionId();

      await DioClient.dio.post(
        "/logout",
        options: Options(
          headers: {"x-browser-session-id": browserId, "x-domain": domain},
        ),
      );
    } catch (_) {
      throw const AppException("Logout failed");
    }

    // Stop session ping
    SessionService.stop();

    // Clear local session
    await clearSession();
  }

  // KEEP SESSION ALIVE (PING)
  static Future<void> ping() async {
    try {
      final browserId = await SecureStorageService.getBrowserSessionId();

      await DioClient.dio.post(
        "/ping",
        options: Options(
          headers: {"x-domain": domain, "x-browser-session-id": browserId},
        ),
      );
    } catch (_) {
      // silent fail
    }
  }

  // CHECK LOGIN STATE
  static Future<bool> isLoggedIn() async {
    final token = await SecureStorageService.getToken();

    return token != null;
  }

  // CLEAR SESSION (LOCAL)
  static Future<void> clearSession() async {
    await SecureStorageService.clearAll();
  }
}
