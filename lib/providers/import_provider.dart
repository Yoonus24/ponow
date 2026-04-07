import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/services/dio_client.dart'; // Import DioClient

class ImportProvider extends ChangeNotifier {
  bool _isLoading = false;
  double? _uploadProgress;
  String? _uploadStatus;
  String? _currentFileName;
  List _importErrors = [];

  bool get isLoading => _isLoading;
  double? get uploadProgress => _uploadProgress;
  String? get uploadStatus => _uploadStatus;
  String? get currentFileName => _currentFileName;
  List get importErrors => _importErrors;

  // Remove local Dio instance - we'll use DioClient.dio instead
  // Note: The base URL is already configured in DioClient, but we need the import endpoint
  // The full URL will be: DioClient.baseUrl + "/poimport/import-items-csv"

  ImportProvider() {
    _ensureDioInitialized();
  }

  // Ensure DioClient is initialized
  Future<void> _ensureDioInitialized() async {
    await DioClient.init();
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = "Preparing file...";
      _currentFileName = filePath.split(Platform.pathSeparator).last;
      _importErrors = [];
      notifyListeners();

      String fileName = _currentFileName!;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      _uploadStatus = "Uploading...";
      notifyListeners();

      // Use DioClient.dio instead of local Dio instance
      // Note: The full endpoint is /poimport/import-items-csv
      final response = await DioClient.dio.post(
        "/poimport/import-items-csv", // Path relative to DioClient.baseUrl
        data: formData,
        options: Options(
          // Increase timeout for file uploads since default is 10 seconds
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          // Don't validate status strictly - we handle it ourselves
          validateStatus: (status) => status != null && status < 500,
        ),
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            double progress = sent / total;

            if (progress > 0.9) progress = 0.9;

            _uploadProgress = progress;
            _uploadStatus = "Uploading ${(progress * 100).toStringAsFixed(0)}%";

            notifyListeners();
          }
        },
        onReceiveProgress: (int received, int total) {
          _uploadProgress = 0.95;
          _uploadStatus = "Processing...";
          notifyListeners();
        },
      );

      _uploadProgress = 1.0;
      _uploadStatus = "Completed!";
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        bool isSuccess = data['success'] == true || response.statusCode == 200;

        if (isSuccess) {
          List importedItems = [];

          if (data['imported_items'] != null) {
            importedItems = data['imported_items'] is List
                ? data['imported_items']
                : [];
          } else if (data['data'] != null && data['data']['items'] != null) {
            importedItems = data['data']['items'];
          }

          return {
            'success': true,
            'imported_items': importedItems,
            'errors': [],
          };
        } else {
          List errors = [];
          if (data['errors'] != null) {
            errors = data['errors'] is List ? data['errors'] : [data['errors']];
          } else if (data['message'] != null) {
            errors = [data['message']];
          }

          _importErrors = errors;

          return {'success': false, 'imported_items': [], 'errors': errors};
        }
      }

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'imported_items': [],
        'errors': [],
      };
    } on DioException catch (e) {
      List errors = [];

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errors = ["Request timed out. Please check your connection."];
      } else if (e.response?.statusCode == 400 ||
          e.response?.statusCode == 422) {
        final errData = e.response?.data;

        if (errData is Map && errData['errors'] != null) {
          errors = errData['errors'] is List
              ? errData['errors']
              : [errData['errors'].toString()];
        } else {
          errors = [errData?['message'] ?? "Invalid file format or data"];
        }
      } else if (e.response?.statusCode == 401) {
        // Session expired - handled by DioClient interceptor
        errors = ["Session expired. Please login again."];
      } else if (e.response?.statusCode == 413) {
        errors = ["File is too large"];
      } else {
        errors = ["Upload failed: ${e.message}"];
      }

      _importErrors = errors;

      return {'success': false, 'imported_items': [], 'errors': errors};
    } catch (e) {
      _importErrors = ["Unexpected error: ${e.toString()}"];

      return {
        'success': false,
        'imported_items': [],
        'errors': ["Unexpected error: ${e.toString()}"],
      };
    } finally {
      await Future.delayed(const Duration(milliseconds: 400));

      _isLoading = false;
      _uploadProgress = null;
      _uploadStatus = null;
      _currentFileName = null;

      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _uploadProgress = null;
    _uploadStatus = null;
    _currentFileName = null;
    _importErrors = [];
    notifyListeners();
  }
}
