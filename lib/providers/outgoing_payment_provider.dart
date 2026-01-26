// lib/providers/outgoing_payment_provider.dart
// CLEAN VERSION – keeps same public API but removes extra complexity.

// ignore_for_file: avoid_print, prefer_final_fields, unused_field, unnecessary_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/outgoing.dart';

class OutgoingPaymentProvider extends ChangeNotifier {


  final Dio dio = Dio();
  final String _baseUrl = 'http://192.168.29.252:8000/nextjstestapi';

  List<Outgoing> _payments = [];
  List<Outgoing> _allPayments = [];

  List<GRN> _grnList = [];
  List<ApInvoice> _apInvoices = [];

  final ValueNotifier<List<String>> _vendorNamesNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> _invoiceNumbersNotifier =
      ValueNotifier<List<String>>([]);

  List<String> _vendorNames = [];
  List<String> _invoiceNumbers = [];

  // Flags
  bool _isLoading = false;
  bool _isLoadingOutgoings = false;
  bool _isLoadingVendors = false;
  bool _isLoadingInvoices = false;

  String _error = '';
  List<String> _validationWarnings = [];


  List<Outgoing> get payments => _payments;
  List<Outgoing> get allPayments => _allPayments;

  List<GRN> get grnList => _grnList;
  List<ApInvoice> get apInvoices => _apInvoices;

  List<String> get vendorNames => _vendorNamesNotifier.value;
  List<String> get invoiceNumbers => _invoiceNumbersNotifier.value;

  bool get isLoading => _isLoading;
  bool get isLoadingOutgoings => _isLoadingOutgoings;
  bool get isLoadingVendors => _isLoadingVendors;
  bool get isLoadingInvoices => _isLoadingInvoices;

  String get error => _error;
  List<String> get validationWarnings => _validationWarnings;


  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> loadAllRequiredData({
    required bool filterByAmount,
    required String status,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await Future.wait([
        fetchFilteredOutgoings(status: status, filterByAmount: filterByAmount),
        fetchGrnList(),
        fetchApInvoices(),
      ]);
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGrnList() async {
    try {
      final response = await dio.get(
        '$_baseUrl/grns/getAll',
        options: Options(validateStatus: (status) => (status ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        _grnList = (response.data as List)
            .map((json) => GRN.fromJson(json))
            .toList();
      } else {}
    } catch (e) {}
    notifyListeners();
  }

  Future<void> fetchApInvoices() async {
    try {
      final response = await dio.get(
        '$_baseUrl/apinvoices/getAll',
        options: Options(validateStatus: (status) => (status ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        _apInvoices = (response.data as List)
            .map((json) => ApInvoice.fromJson(json))
            .toList();
      } else {
        _apInvoices = [];
        _error = 'Failed to load AP Invoice data: ${response.statusCode}';
      }
    } catch (e) {
      _apInvoices = [];
      _error = 'Failed to load AP Invoice data: $e';
    }
    notifyListeners();
  }

  Future<void> fetchVendors() async {
    final payments = _allPayments;

    final vendors =
        payments
            .map((p) => p.vendorName)
            .where((v) => v != null && v.trim().isNotEmpty)
            .map((v) => v!)
            .toSet()
            .toList()
          ..sort();

    _vendorNamesNotifier.value = vendors;
    notifyListeners();
  }

  Future<void> fetchInvoiceNumbers() async {
    if (_isLoadingInvoices) return;

    _isLoadingInvoices = true;
    notifyListeners();

    try {
      final response = await dio.get(
        '$_baseUrl/outgoingpayments/',
        queryParameters: {
          'status': 'Active,Pending,Partially Paid',
          'limit': 500,
        },

        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        final dynamic raw = response.data;

        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map && raw['outgoings'] is List)
            ? raw['outgoings']
            : [];

        final List<String> invoiceNumbers =
            data
                .map((e) => e['invoiceNo'] ?? e['apRandomId'] ?? e['invoiceId'])
                .where((v) => v != null && v.toString().isNotEmpty)
                .map((v) => v.toString())
                .toSet()
                .toList()
              ..sort();

        _invoiceNumbers = invoiceNumbers;
        _invoiceNumbersNotifier.value = invoiceNumbers;

        if (kDebugMode) {
          print('✅ Pending invoice list: $invoiceNumbers');
        }
      } else {
        _invoiceNumbersNotifier.value = [];
      }
    } catch (e) {
      _invoiceNumbersNotifier.value = [];
      if (kDebugMode) {
        print('❌ fetchInvoiceNumbers error: $e');
      }
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
    }
  }

  Future<void> removeOutgoingPayment(String outgoingId) async {
    try {
      _payments.removeWhere((outgoing) => outgoing.outgoingId == outgoingId);
      _allPayments.removeWhere((outgoing) => outgoing.outgoingId == outgoingId);

      final response = await dio.delete(
        '$_baseUrl/outgoingpayments/$outgoingId',
      );

      if (response.statusCode == 200) {
        print('✅ Outgoing payment removed from backend');
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error removing outgoing: $e');
    }
  }

  Future<List<Outgoing>> fetchFilteredOutgoings({
    DateTime? fromDate,
    DateTime? toDate,
    String? vendorName,
    String? filterBy = 'invoiceDate',
    String? status,
    bool filterByAmount = false,
    String sortOrder = 'ascending',
    int skip = 0,
    int limit = 50,
    String? invoiceNo,
  }) async {
    _isLoadingOutgoings = true;
    _error = '';
    notifyListeners();

    try {
      String? backendStatus;

      if (status != null && status.trim().isNotEmpty) {
        final uiStatus = status.toLowerCase().trim();
        if (uiStatus == 'pending') {
          backendStatus = 'active,Pending,Partially Paid';
        } else if (uiStatus == 'partial') {
          backendStatus = 'Partially Paid';
        } else if (uiStatus == 'paid') {
          backendStatus = 'Fully Paid';
        } else {
          backendStatus = status;
        }
      }

      String? cleanedInvoiceNo;
      if (invoiceNo != null && invoiceNo.trim().isNotEmpty) {
        cleanedInvoiceNo = invoiceNo.trim();
      }

      final Map<String, dynamic> queryParams = {
        'filterBy': filterBy,
        'sortOrder': sortOrder,
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (filterByAmount) 'filterByAmount': 'true',
        if (backendStatus != null) 'status': backendStatus,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
        if (vendorName != null && vendorName.isNotEmpty)
          'vendorName': vendorName,
        if (cleanedInvoiceNo != null) 'invoiceNo': cleanedInvoiceNo,
      };

      if (kDebugMode) {
        print('=== FETCHING OUTGOINGS ===');
        print('UI Status      : $status');
        print('Backend Status : $backendStatus');
        print('Query Params   : $queryParams');
      }

      final response = await dio.get(
        '$_baseUrl/outgoingpayments/',
        queryParameters: queryParams,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => (status ?? 500) < 500,
        ),
      );

      if (response.statusCode == 200) {
        final dynamic raw = response.data;

        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map && raw['outgoings'] is List)
            ? raw['outgoings']
            : [];

        final fetched = data.map((json) => Outgoing.fromJson(json)).toList();

        final Map<String, Outgoing> localMap = {
          for (final p in _payments) p.outgoingId: p,
        };

        _payments = fetched.map((server) {
          final local = localMap[server.outgoingId];

          if (local == null) return server;

          return server.copyWith(
            totalPaidAmount: server.totalPaidAmount,
            remainingPayableAmount: server.remainingPayableAmount,
            paymentHistory: server.paymentHistory,

            partialAmount: local.partialAmount ?? server.partialAmount,
            advanceAmount: local.advanceAmount ?? server.advanceAmount,
            fullPaymentAmount:
                local.fullPaymentAmount ?? server.fullPaymentAmount,
            status: server.status,
          );
        }).toList();

        _allPayments = List.from(_payments);

        _allPayments = List.from(_payments);

        if (kDebugMode) {
          print('✅ Loaded ${_payments.length} outgoing payments');
        }
      } else {
        _payments = [];
        _allPayments = [];
        _error = 'Failed to load outgoings';
      }
    } catch (e) {
      _payments = [];
      _allPayments = [];
      _error = 'Error loading outgoings: $e';
    } finally {
      _isLoadingOutgoings = false;
      notifyListeners();
    }
    await fetchVendors();
    await fetchInvoiceNumbers();
    return _payments;
  }

  Future<void> testBackendResponse() async {
    try {
      if (kDebugMode) {
        print('🧪 TESTING BACKEND RESPONSE DIRECTLY');
      }

      final response = await dio.get(
        '$_baseUrl/outgoingpayments/?status=Pending&limit=2',
      );

      if (kDebugMode) {
        print('🧪 Test Response status: ${response.statusCode}');
        print('🧪 Test Response type: ${response.data.runtimeType}');

        if (response.data is List) {
          print('🧪 Response is List with ${response.data.length} items');
          for (int i = 0; i < response.data.length; i++) {
            print('🧪 Item $i: ${response.data[i]}');
            if (response.data[i] is Map) {
              print(
                '🧪 Item $i keys: ${(response.data[i] as Map).keys.toList()}',
              );
            }
          }
        } else if (response.data is Map) {
          print(
            '🧪 Response is Map with keys: ${(response.data as Map).keys.toList()}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🧪 Test failed: $e');
      }
    }
  }

  Future<String> saveOutgoingPayment(Outgoing outgoing) async {
    try {
      final response = await dio.post(
        '$_baseUrl/outgoingpayments/',
        data: jsonEncode(outgoing.toJson()),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (kDebugMode) {
        print(
          '[API] Save outgoing payment response status: ${response.statusCode}',
        );
        print('[API] Save outgoing payment response body: ${response.data}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save outgoing payment: ${response.data}');
      }

      final responseData = response.data;
      return responseData['outgoingId'] ?? outgoing.outgoingId;
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<void> processOutgoingPayment(String outgoingId) async {
    try {
      if (kDebugMode) {
        print('[API] Processing payment for ID: $outgoingId');
      }
      final response = await dio.post(
        '$_baseUrl/outgoingpayments/$outgoingId/process',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (kDebugMode) {
        print('[API] Response status: ${response.statusCode}');
        print('[API] Response body: ${response.data}');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to process payment: ${response.data} (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[API ERROR] Payment processing failed: $e');
      }
      rethrow;
    }
  }

  Future<void> processPayment({
    required String outgoingId,
    required String paymentType,
    required double amount,
    required String paymentMode,
    required String paymentMethod,
    required Map<String, dynamic> transactionDetails,
  }) async {
    if (kDebugMode) {
      print('processPayment -> outgoingId=$outgoingId');
      print(
        'paymentType=$paymentType, amount=$amount, paymentMode=$paymentMode, '
        'paymentMethod=$paymentMethod, tx=$transactionDetails',
      );
    }

    try {
      final Dio dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 10)
        ..options.receiveTimeout = const Duration(seconds: 10);

      String backendPaymentMethod;
      if (paymentMode == 'Cash') {
        if (paymentMethod == 'petty_cash') {
          backendPaymentMethod = 'pettyCash';
        } else if (paymentMethod == 'ho_cash') {
          backendPaymentMethod = 'hoCash';
        } else {
          throw Exception('Invalid cash payment method');
        }
      } else {
        backendPaymentMethod = paymentMethod.toLowerCase();
      }

      final Map<String, dynamic> requestData = {
        'paymentType': paymentType,
        'paymentMode': paymentMode,
        'paymentMethod': backendPaymentMethod,

        'totalPayableAmount': _payments
            .firstWhere((p) => p.outgoingId == outgoingId)
            .totalPayableAmount,

        if (paymentType == 'partial') 'partialAmount': amount,
        if (paymentType == 'advance') 'advanceAmount': amount,
        if (paymentType == 'full') 'fullPaymentAmount': amount,
      };

      if (paymentMode == 'Bank') {
        requestData.addAll({
          if (transactionDetails['bankName'] != null)
            'bankName': transactionDetails['bankName'],
          if (transactionDetails['neftNo'] != null)
            'neftNo': transactionDetails['neftNo'],
          if (transactionDetails['rtgsNo'] != null)
            'rtgsNo': transactionDetails['rtgsNo'],
          if (transactionDetails['impsNo'] != null)
            'impsNo': transactionDetails['impsNo'],
          if (transactionDetails['upi'] != null)
            'upi': transactionDetails['upi'],
        });
      } else {
        requestData.addAll({
          if (transactionDetails['pettyCashAmount'] != null)
            'pettyCashAmount': transactionDetails['pettyCashAmount'],
          if (transactionDetails['hoCash'] != null)
            'hoCash': transactionDetails['hoCash'],
        });
      }

      if (kDebugMode) {
        print('processPayment -> requestData=$requestData');
      }

      final response = await dio.patch(
        '$_baseUrl/outgoingpayments/$outgoingId/payment',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Payment failed with status ${response.statusCode}');
      }

      final Map<String, dynamic> data = response.data;

      final double remaining =
          (data['remainingPayableAmount'] as num?)?.toDouble() ?? 0.0;

      final double totalPaid =
          (data['totalPaidAmount'] as num?)?.toDouble() ?? 0.0;

      final String newStatus = data['status'] ?? 'Pending';

      final List<PaymentHistory> history =
          (data['paymentHistory'] as List? ?? [])
              .map((e) => PaymentHistory.fromJson(e))
              .toList();

      final int index = _payments.indexWhere((p) => p.outgoingId == outgoingId);

      if (index != -1) {
        final old = _payments[index];

        final updatedOutgoing = old.copyWith(
          status: newStatus,
          remainingPayableAmount: remaining,
          totalPaidAmount: totalPaid,
          paymentHistory: history,
          partialAmount: paymentType == 'partial' ? amount : old.partialAmount,
          advanceAmount: paymentType == 'advance' ? amount : old.advanceAmount,
          fullPaymentAmount: paymentType == 'full'
              ? amount
              : old.fullPaymentAmount,
        );

        _payments[index] = updatedOutgoing;
      }

      notifyListeners();

      if (kDebugMode) {
        print('✅ Payment processed & UI updated instantly');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ processPayment error: $e');
      }
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processBulkPayments(
    List<BulkPayment> bulkPayments,
    List<Outgoing> outgoing,
  ) async {
    try {
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final Map<String, Outgoing> outgoingMap = {
        for (var o in outgoing) o.outgoingId: o,
      };

      double perOutgoingPartialAmount = 0.0;

      if (bulkPayments.isNotEmpty &&
          bulkPayments.first.paymentType == 'partial') {
        final totalEnteredAmount = bulkPayments.first.partialAmount ?? 0.0;

        if (totalEnteredAmount <= 0) {
          throw Exception('Partial amount must be greater than zero');
        }

        perOutgoingPartialAmount = double.parse(
          (totalEnteredAmount / bulkPayments.length).toStringAsFixed(2),
        );
      }

      for (final payment in bulkPayments) {
        final match = outgoingMap[payment.outgoingId];
        if (match == null) {
          throw Exception('Outgoing not found: ${payment.outgoingId}');
        }

        final totalPayable = match.totalPayableAmount ?? 0;
        if (totalPayable <= 0) {
          throw Exception('Invalid payable for ${payment.outgoingId}');
        }

        if (payment.paymentType == 'full') {
          if (payment.fullPaymentAmount == null ||
              payment.fullPaymentAmount! <= 0) {
            throw Exception('Invalid full amount for ${payment.outgoingId}');
          }
        }

        if (payment.paymentType == 'partial') {
          if (perOutgoingPartialAmount >= totalPayable) {
            throw Exception(
              'Partial amount exceeds payable for ${payment.outgoingId}',
            );
          }
        }
      }

      final requestData = {
        'paymentDate': DateTime.now().toIso8601String().split('T').first,

        'outgoingIds': bulkPayments.map((p) => p.outgoingId).toList(),

        'payments': bulkPayments.map((p) {
          final bool isCash = p.paymentMode == 'Cash';
          final match = outgoingMap[p.outgoingId]!;

          return {
            'outgoingId': p.outgoingId,
            'totalPayableAmount': match.totalPayableAmount,

            'paymentType': p.paymentType,
            'paymentMode': p.paymentMode,
            'paymentMethod': isCash ? 'cash' : p.paymentMethod,

            'cashAmount': isCash
                ? (p.paymentType == 'full'
                      ? p.fullPaymentAmount
                      : perOutgoingPartialAmount)
                : 0.0,

            'selectedDebitNotes': [],
            'selectedAdvancePayments': [],

            if (p.paymentType == 'full')
              'fullPaymentAmount': p.fullPaymentAmount,

            if (p.paymentType == 'partial')
              'partialAmount': perOutgoingPartialAmount,

            if (p.paymentMode == 'Bank') ...{
              'bankName': p.bankName,
              if (p.paymentMethod == 'neft') 'neftNo': p.transactionReference,
              if (p.paymentMethod == 'rtgs') 'rtgsNo': p.transactionReference,
              if (p.paymentMethod == 'imps') 'impsNo': p.transactionReference,
              if (p.paymentMethod == 'upi') 'upi': p.transactionReference,
            },
          };
        }).toList(),
      };

      debugPrint('✅ BULK REQUEST => $requestData');

      final response = await dio.patch(
        '$_baseUrl/outgoingpayments/bulk/bulk-payment',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 207) {
        throw Exception('Bulk payment failed: ${response.statusCode}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ processBulkPayments ERROR => $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _vendorNamesNotifier.dispose();
    _invoiceNumbersNotifier.dispose();
    dio.close();
    super.dispose();
  }
}
