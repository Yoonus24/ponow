import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/services/dio_client.dart';

class ImportProvider extends ChangeNotifier {
  bool _isLoading = false;
  double? _uploadProgress;
  String? _uploadStatus;
  String? _currentFileName;
  List<String> _importErrors = [];
  bool get isLoading => _isLoading;
  double? get uploadProgress => _uploadProgress;
  String? get uploadStatus => _uploadStatus;
  String? get currentFileName => _currentFileName;
  List<String> get importErrors => _importErrors;
  // ImportProvider() {
  //   _ensureDioInitialized();
  // }

  // Ensure DioClient is initialized
  // Future<void> _ensureDioInitialized() async {
  //   await DioClient.init();
  // }

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

      final response = await DioClient.dio.post(
        "/poimport/import-items-csv",
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status < 500,
        ),
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            double progress = sent / total;

            if (progress > 0.9) {
              progress = 0.9;
            }

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
          List<dynamic> importedItems = [];

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
            'errors': <String>[],
          };
        } else {
          List<String> errors = [];

          if (data['errors'] != null) {
            if (data['errors'] is List) {
              errors = (data['errors'] as List)
                  .map((e) => e.toString())
                  .toList();
            } else {
              errors = [data['errors'].toString()];
            }
          } else if (data['message'] != null) {
            errors = [data['message'].toString()];
          }

          _importErrors = errors;

          return {
            'success': false,
            'imported_items': <dynamic>[],
            'errors': errors,
          };
        }
      }

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'imported_items': <dynamic>[],
        'errors': <String>[],
      };
    } catch (e, stackTrace) {
      if (e is DioException) {
        final data = e.response?.data;

        if (data is Map<String, dynamic>) {
          final backendErrors = data['errors'];

          if (backendErrors is List && backendErrors.isNotEmpty) {
            _importErrors = backendErrors.map((e) => e.toString()).toList();

            return {
              'success': false,
              'imported_items': <dynamic>[],
              'errors': _importErrors,
            };
          }
        }
      }

      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("Import error: ${exception.message}");

      _importErrors = [exception.message];

      return {
        'success': false,
        'imported_items': <dynamic>[],
        'errors': [exception.message],
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
