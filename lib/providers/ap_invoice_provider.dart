// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';

class APInvoiceProvider extends ChangeNotifier {
  List<ApInvoice> _apInvoices = [];
  final List<Outgoing> _outgoings = [];
  List<GRN> _grns = [];
  bool _loading = false;
  String? _error;
  String _filterStatus = 'Pending';

  List<ApInvoice> get apInvoices => _apInvoices;
  List<Outgoing> get outgoings => _outgoings;
  List<GRN> get grns => _grns;
  bool get loading => _loading;
  String get filterStatus => _filterStatus;

  set filterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  String? get error => _error;

  final String baseUrl = 'http://192.168.29.252:8000/nextjstestapi';

  // Fetch AP Invoices
  Future<void> fetchAPInvoices({String? status}) async {
    print("🚀 fetchAPInvoices CALLED");
    _setLoading(true);
    _setError(null);

    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      Map<String, dynamic> queryParams = {};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      print("🌐 GET $baseUrl/apinvoices/getAll");

      final response = await dio.get(
        '$baseUrl/apinvoices/getAll',
        queryParameters: queryParams,
      );
      print("🌐 AP RAW RESPONSE: ${response.data}");

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _apInvoices = data.map((json) => ApInvoice.fromJson(json)).toList();
        print("✅ Fetched ${_apInvoices.length} AP invoices");
      } else {
        _setError('Failed to load invoices: ${response.statusMessage}');
      }
    } catch (e) {
      print("❌ fetchAPInvoices error: $e");
      _setError('Failed to load invoices: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update in APInvoiceProvider - convertGrnToApAndOutgoing method
  Future<Map<String, dynamic>> postOutgoingAndUpdateDiscount(
    String invoiceId, {
    required double apDiscountPrice,
    required double roundOffAdjustment, // ADD THIS PARAMETER
    required Function(bool) setLoading,
    required Function(String?) setError,
  }) async {
    setLoading(true);
    setError(null);

    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.29.252:8000/nextjstestapi/',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    try {
      final currentDateTime = DateTime.now().toIso8601String();
      final requestBody = {
        'invoiceId': invoiceId,
        'apDiscountPrice': apDiscountPrice,
        'roundOffAdjustment': roundOffAdjustment, // ADD THIS
        'lastUpdatedDate': currentDateTime,
        'outgoingDate': currentDateTime,
      };

      print(
        'Sending PATCH to: /apinvoices/$invoiceId/convert-to-outgoing-and-discount',
      );
      print('Request Body: $requestBody');

      final response = await dio.patch(
        '/apinvoices/$invoiceId/convert-to-outgoing-and-discount',
        data: requestBody,
      );

      print('Response: ${response.statusCode} ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final removedIndex = _apInvoices.indexWhere(
          (inv) => inv.invoiceId == invoiceId,
        );
        if (removedIndex != -1) {
          _apInvoices.removeAt(removedIndex);
          notifyListeners();
          print('✅ Payment success - Card removed from UI');
        }

        return data;
      } else {
        throw Exception('Payment failed: ${response.statusCode}');
      }
    } catch (e) {
      // ❌ CARD STAYS IN UI
      print('❌ Payment failed - Card remains');
      throw e;
    } finally {
      setLoading(false);
    }
  }

  Future<void> convertToGrnFromApReturned(
    String invoiceId,
    BuildContext context,
  ) async {
    _setLoading(true);
    _setError(null);

    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.29.252:8000/nextjstestapi',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    try {
      final response = await dio.patch(
        '/apinvoices/convert-to-grn-from-returned/$invoiceId',
      );

      if (response.statusCode == 200) {
        // 🔥 remove AP from UI
        _apInvoices.removeWhere((inv) => inv.invoiceId == invoiceId);
        notifyListeners();

        // 🔄 refresh related lists
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
        throw Exception('Return failed');
      }
    } catch (e) {
      _setError(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Return failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool isLoading) {
    _loading = isLoading;
    notifyListeners();
  }

  // Set error state
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
      print('Retrying request, attempt ${attempt + 1}');
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
