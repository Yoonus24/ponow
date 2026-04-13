import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchaseorders2/services/navigation_service.dart';
import 'package:flutter/material.dart';

bool _isRedirecting = false;

class DioClient {
  static const String baseUrl = "http://192.168.29.184:8000/purchasetestapi/";
  static const String domain = "localhost:3000";

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  static Future<void> init() async {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (!options.path.contains("/login") && token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          options.headers["x-domain"] = domain;
          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },

        onError: (e, handler) async {
          final path = e.requestOptions.path;

          if (path.contains("/login")) {
            return handler.next(e);
          }

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

  static void _showSessionExpiredDialog() async {
    final context = NavigationService.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

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

                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                await prefs.remove('username');
                await prefs.remove('browser_session_id');

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
