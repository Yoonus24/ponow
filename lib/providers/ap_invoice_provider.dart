// ignore_for_file: prefer_final_fields, use_build_context_synchronously, avoid_print, use_rethrow_when_possible

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

class APInvoiceProvider extends ChangeNotifier {
  List<ApInvoice> _apInvoices = [];
  final List<Outgoing> _outgoings = [];
  List<GRN> _grns = [];
  bool _loading = false;
  String? _error;
  String _filterStatus = 'Pending';
  bool _isFetching = false;
  List<ApInvoice> get apInvoices => _apInvoices;
  List<Outgoing> get outgoings => _outgoings;
  List<GRN> get grns => _grns;
  bool get loading => _loading;
  String get filterStatus => _filterStatus;
  bool _isInitialLoad = true;
  bool get isInitialLoad => _isInitialLoad;

  set filterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  String? get error => _error;

  final String baseUrl = 'http://192.168.29.184:8000/nextjstestapi';
  late Dio _dio;

  APInvoiceProvider() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
  }

  Future<void> fetchAPInvoices({
    String? status,
    String? vendorName,
    DateTime? date,
    int skip = 0,
    int limit = 50,
  }) async {
    if (_isFetching) return;

    _isFetching = true;
    _setLoading(true);
    _setError(null);

    try {
      final queryParams = {
        'skip': skip,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (vendorName != null && vendorName.isNotEmpty)
          'vendorName': vendorName,
        if (date != null) 'fromDate': date.toIso8601String(),
        if (date != null) 'toDate': date.toIso8601String(),
      };

      final response = await _dio.get(
        '/apinvoices/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        _apInvoices = data.map((e) => ApInvoice.fromJson(e)).toList();
      }
    } catch (e) {
      _setError("Failed to fetch AP invoices");
    } finally {
      _loading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> convertToGrnFromApReturned(
    String invoiceId,
    BuildContext context,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _dio.patch(
        '/apinvoices/convert-to-grn-from-returned/$invoiceId',
      );

      if (response.statusCode == 200) {
        _apInvoices.removeWhere((inv) => inv.invoiceId == invoiceId);
        notifyListeners();

        final grnProvider = Provider.of<GRNProvider>(context, listen: false);
        final outgoingProvider = Provider.of<OutgoingPaymentProvider>(
          context,
          listen: false,
        );

        await Future.wait([
          fetchAPInvoices(),
          grnProvider.fetchFilteredGRNs(),
          outgoingProvider.fetchFilteredOutgoings(),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AP returned to GRN successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Return failed.");
      }
    } on DioException catch (e) {
      final message = _getReadableError(e);

      _setError(message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey.shade200,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      const message = "Something went wrong.";
      _setError(message);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  String _getReadableError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
        return "No internet connection.";
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return "Request timed out.";
      case DioExceptionType.badResponse:
        return "Server error.";
      default:
        return "Unexpected error.";
    }
  }

  void _setLoading(bool isLoading, {bool force = false}) {
    if (!force && _apInvoices.isNotEmpty) return;
    _loading = isLoading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void postOutgoingAndUpdateStatus(String s) {}
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    required this.retries,
    required this.retryDelays,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = err.requestOptions.extra['retry_attempt'] ?? 0;
    if (attempt < retries && err.type == DioExceptionType.connectionTimeout) {
      err.requestOptions.extra['retry_attempt'] = attempt + 1;
      await Future.delayed(retryDelays[attempt]);
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.reject(err);
      }
    } else {
      handler.reject(err);
    }
  }
}
