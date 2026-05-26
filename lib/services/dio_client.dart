import 'package:dio/dio.dart';
import 'package:purchaseorders2/core/config/env.dart';
import 'package:purchaseorders2/services/navigation_service.dart';
import 'package:purchaseorders2/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

bool _isRedirecting = false;

class DioClient {
  static final Dio dio = Dio();

  // INIT (MUST CALL IN main)
  static Future<void> init() async {
    // Set options AFTER dotenv is loaded
    dio.options = BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {"Content-Type": "application/json"},
    );

    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token securely
          final token = await SecureStorageService.getToken();

          if (!options.path.contains("/login") && token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          // Add domain from env
          options.headers["x-domain"] = Env.domain;

          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },

        onError: (e, handler) async {
          final path = e.requestOptions.path;

          // Skip login errors
          if (path.contains("/login")) {
            return handler.next(e);
          }

          // Handle session expiry
          if (e.response?.statusCode == 401 && !_isRedirecting) {
            _isRedirecting = true;

            Future.delayed(const Duration(milliseconds: 300), () {
              _showSessionExpiredDialog();
            });

            Future.delayed(const Duration(seconds: 1), () {
              _isRedirecting = false;
            });
          }

          return handler.next(e);
        },
      ),
    );
  }

  // SESSION EXPIRED DIALOG
  static void _showSessionExpiredDialog() async {
    final context = NavigationService.navigatorKey.currentContext;

    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Session Expired",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Your session has expired. Please login again.",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);

                // Clear all secure data
                await SecureStorageService.clearAll();

                NavigationService.navigateToLogin();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
