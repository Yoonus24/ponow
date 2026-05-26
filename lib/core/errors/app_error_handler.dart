import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_exception.dart';

class AppErrorHandler {
  static AppException handle(Object error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint("========== APP ERROR ==========");
      debugPrint(error.toString());

      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }

      debugPrint("================================");
    }

    // CUSTOM
    if (error is AppException) {
      return error;
    }

    // DIO
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return const AppException('Connection timeout. Please try again.');

        case DioExceptionType.sendTimeout:
          return const AppException('Request timeout. Please try again.');

        case DioExceptionType.receiveTimeout:
          return const AppException('Server took too long to respond.');

        case DioExceptionType.badCertificate:
          return const AppException('Secure connection failed.');

        case DioExceptionType.cancel:
          return const AppException('Request cancelled.');

        case DioExceptionType.connectionError:
          return const AppException('No internet connection.');

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;

          String? message;

          // MAP RESPONSE
          if (data is Map<String, dynamic>) {
            message =
                data['message']?.toString() ??
                data['error']?.toString() ??
                data['detail']?.toString();
          }
          // STRING RESPONSE
          else if (data != null) {
            message = data.toString();
          }

          final normalizedMessage = message?.toLowerCase().trim() ?? '';

          // LOGIN ERRORS
          if (normalizedMessage.contains("invalid_credentials") ||
              normalizedMessage.contains("invalid credentials")) {
            return const AppException("Invalid username or password");
          }

          if (normalizedMessage.contains("session_exists") ||
              normalizedMessage.contains("session exists")) {
            return const AppException("Already logged in another device");
          }

          if (normalizedMessage.contains("login_failed") ||
              normalizedMessage.contains("login failed")) {
            return const AppException("Login failed. Please try again");
          }

          switch (statusCode) {
            case 400:
              return AppException(
                message?.trim().isNotEmpty == true ? message! : 'Bad request.',
                statusCode: 400,
              );

            case 401:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Session expired. Please login again.',
                statusCode: 401,
              );

            case 403:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Access denied.',
                statusCode: 403,
              );

            case 404:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Requested data not found.',
                statusCode: 404,
              );

            case 409:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Data already exists.',
                statusCode: 409,
              );

            case 422:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Invalid data provided.',
                statusCode: 422,
              );

            case 500:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Internal server error.',
                statusCode: 500,
              );

            default:
              return AppException(
                message?.trim().isNotEmpty == true
                    ? message!
                    : 'Unexpected server response.',
                statusCode: statusCode,
              );
          }

        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return const AppException('No internet connection.');
          }

          return const AppException('Unexpected network error occurred.');
      }
    }

    // SOCKET
    if (error is SocketException) {
      return const AppException('No internet connection.');
    }

    // FORMAT
    if (error is FormatException) {
      return const AppException('Invalid data format received.');
    }

    // FILE SYSTEM
    if (error is FileSystemException) {
      return const AppException('File operation failed.');
    }

    // TIMEOUT
    if (error is TimeoutException) {
      return const AppException('Operation timeout. Please try again.');
    }

    // NORMAL EXCEPTION
    if (error is Exception) {
      final rawMessage = error.toString();
      final normalizedMessage = rawMessage.toLowerCase();

      // LOGIN ERRORS
      if (normalizedMessage.contains("session_exists")) {
        return const AppException("Already logged in another device");
      }

      if (normalizedMessage.contains("invalid_credentials")) {
        return const AppException("Invalid username or password");
      }

      if (normalizedMessage.contains("login_failed")) {
        return const AppException("Login failed. Please try again");
      }

      return AppException(rawMessage.replaceFirst("Exception: ", ""));
    }

    return const AppException('Unexpected error occurred.');
  }
}
