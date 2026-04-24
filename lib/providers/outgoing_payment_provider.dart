// ignore_for_file: prefer_final_fields

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:purchaseorders2/services/dio_client.dart'; // Import DioClient
import 'package:purchaseorders2/services/server_time_service.dart';

class OutgoingPaymentProvider extends ChangeNotifier {
  OutgoingPaymentProvider() {
    _ensureDioInitialized();
  }

  Future<void> _ensureDioInitialized() async {
    await DioClient.init();
  }

  List<Outgoing> _payments = [];
  List<Outgoing> _allPayments = [];
  List<GRN> _grnList = [];
  List<ApInvoice> _apInvoices = [];
  final ValueNotifier<List<String>> _vendorNamesNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> _invoiceNumbersNotifier =
      ValueNotifier<List<String>>([]);
  bool _isLoading = false;
  bool _isLoadingOutgoings = false;
  final bool _isLoadingVendors = false;
  bool _isLoadingInvoices = false;
  String _error = '';
  final List<String> _validationWarnings = [];
  Map<int, bool> _loadingPdfMap = {};

  List<Outgoing> get payments => _payments;
  List<Outgoing> get allPayments => _payments;
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
  bool _isTableLoading = false;
  bool get isTableLoading => _isTableLoading;

  void clearError() {
    _error = '';
    notifyListeners();
  }

  bool isPdfLoading(int index) {
    return _loadingPdfMap[index] ?? false;
  }

  Future<void> generatePdf(int index, Outgoing payment) async {
    _loadingPdfMap[index] = true;
    notifyListeners();

    try {
      final poService = OutgoingPdf();
      final pdfFile = await poService.generateOutgoingPdf(payment.outgoingId);

      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());
    } catch (e) {
      debugPrint("PDF Error: $e");
    } finally {
      _loadingPdfMap[index] = false;
      notifyListeners();
    }
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
      _error = _getReadableError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGrnList() async {
    try {
      final response = await DioClient.dio.get(
        '/grns/getAll',
        options: Options(validateStatus: (status) => (status ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        _grnList = (response.data as List)
            .map((json) => GRN.fromJson(json))
            .toList();
      } else {}
    } catch (e) {
      _error = _getReadableError(e);
    }
    notifyListeners();
  }

  Future<void> fetchApInvoices() async {
    try {
      if (kDebugMode) {
        print('🚀 fetchAPInvoices CALLED');
      }

      final response = await DioClient.dio.get(
        '/apinvoices/getAll',
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        _apInvoices = (response.data as List)
            .map((json) => ApInvoice.fromJson(json))
            .toList();

        if (kDebugMode) {
          print('✅ Fetched ${_apInvoices.length} AP invoices');
        }
      } else {
        _apInvoices = [];
      }
    } catch (e) {
      _apInvoices = [];
      _error = _getReadableError(e);
    }

    notifyListeners();
  }

  void setLoadingOutgoings(bool value) {
    _isLoadingOutgoings = value;
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
  }

  Future<void> fetchInvoiceNumbers() async {
    if (_isLoadingInvoices) return;

    _isLoadingInvoices = true;
    notifyListeners();

    try {
      final response = await DioClient.dio.get(
        '/outgoingpayments/outgoing/getAll',
        queryParameters: {
          'status': 'active,Pending,Partially Paid',
          'limit': 500,
        },
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];

        final invoiceNumbers =
            data
                .map((e) => e['invoiceNo'] ?? e['apRandomId'] ?? e['invoiceId'])
                .where((v) => v != null && v.toString().isNotEmpty)
                .map((v) => v.toString())
                .toSet()
                .toList()
              ..sort();

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
    bool isTableRefresh = false,
  }) async {
    if (skip == 0) {
      if (isTableRefresh) {
        _isTableLoading = true;
      } else {
        _isLoadingOutgoings = true;
      }
      notifyListeners();
    }

    _error = '';

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

      final Map<String, dynamic> queryParams = {
        'filterBy': filterBy,
        'sortOrder': sortOrder,
        'skip': skip,
        'limit': limit,
        if (filterByAmount) 'filterByAmount': true,
        if (backendStatus != null) 'status': backendStatus,
        if (fromDate != null)
          'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),

        if (toDate != null) 'toDate': DateFormat('yyyy-MM-dd').format(toDate),
        if (vendorName != null && vendorName.trim().isNotEmpty)
          'vendorName': vendorName.trim(),
        if (invoiceNo != null && invoiceNo.trim().isNotEmpty)
          'invoiceNo': invoiceNo.trim(),
      };

      final response = await DioClient.dio.get(
        '/outgoingpayments',
        queryParameters: queryParams,
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List ? raw : (raw['outgoings'] ?? []);

        var fetched = data.map((e) => Outgoing.fromJson(e)).toList();
        if (fromDate != null && toDate != null && filterBy == 'paymentDate') {
          fetched = fetched.where((p) {
            final date = p.paymentDate;
            if (date == null) return false;

            return date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
                date.isBefore(toDate.add(const Duration(days: 1)));
          }).toList();
        }

        /// LOCAL FILTER
        if (invoiceNo != null && invoiceNo.isNotEmpty) {
          fetched = fetched
              .where(
                (p) => (p.invoiceNo ?? '').toLowerCase().contains(
                  invoiceNo.toLowerCase(),
                ),
              )
              .toList();
        }
        // Pagination logic
        if (skip == 0) {
          _payments = fetched;
        } else {
          _payments.addAll(fetched);
        }

        // Sync backup list
        _allPayments = List.from(_payments);

        _error = '';
      } else {
        _payments = [];
        _allPayments = [];
        _error = 'Unable to load outgoings. Please try again.';
      }
    } catch (e) {
      _payments = [];
      _allPayments = [];
      _error = _getReadableError(e);
    } finally {
      _isLoadingOutgoings = false;
      _isTableLoading = false;
      notifyListeners();
    }

    return _payments;
  }

  Future<List<Outgoing>> fetchByPaymentDate({
    required DateTime fromDate,
    required DateTime toDate,
    String status = 'Fully Paid,Partially Paid',
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await DioClient.dio.get(
        '/outgoingpayments',
        queryParameters: {
          'filterBy': 'paymentDate', // ✅ IMPORTANT
          'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
          'toDate': DateFormat('yyyy-MM-dd').format(toDate),
          'status': status,
          'skip': skip,
          'limit': limit,
        },
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List ? raw : (raw['outgoings'] ?? []);

        final fetched = data.map((e) => Outgoing.fromJson(e)).toList();

        _payments = fetched;
        notifyListeners();

        return fetched;
      } else {
        _payments = [];
        notifyListeners();
        return [];
      }
    } catch (e) {
      _payments = [];
      notifyListeners();
      return [];
    }
  }

  Future<void> fetchAllOutgoings({DateTime? fromDate, DateTime? toDate}) async {
    _isLoading = true;
    _error = "";
    notifyListeners();

    try {
      final response = await DioClient.dio.get(
        '/outgoingpayments/outgoing/getAll',
        queryParameters: {
          if (fromDate != null)
            'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
          if (toDate != null) 'toDate': DateFormat('yyyy-MM-dd').format(toDate),
        },
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final List list = raw is List ? raw : raw['outgoings'] ?? [];

        _payments = list.map((e) => Outgoing.fromJson(e)).toList();
        _allPayments = List.from(_payments);

        _error = "";
      } else {
        _payments = [];
        _allPayments = [];
        _error = "Unable to load ledger data";
      }
    } catch (e) {
      _payments = [];
      _allPayments = [];
      _error = _getReadableError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> saveOutgoingPayment(Outgoing outgoing) async {
    try {
      final data = outgoing.toJson();
      data['createdDate'] = ServerTimeService.now.toIso8601String();

      final response = await DioClient.dio.post(
        '/outgoingpayments/',
        data: data,
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
      final response = await DioClient.dio.post(
        '/outgoingpayments/$outgoingId/process',
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

      final currentDateTime = ServerTimeService.now.toIso8601String();
      requestData['paymentDate'] = currentDateTime;

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

      final response = await DioClient.dio.patch(
        '/outgoingpayments/$outgoingId/payment',
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
      _error = _getReadableError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processBulkPayments(
    List<BulkPayment> bulkPayments,
    List<Outgoing> outgoing,
  ) async {
    try {
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

      final serverDate = ServerTimeService.now;

      final requestData = {
        'paymentDate': serverDate.toIso8601String().split('T').first,
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

      final response = await DioClient.dio.patch(
        '/outgoingpayments/bulk/bulk-payment',
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

  String _getReadableError(dynamic e) {
    final error = e.toString().toLowerCase();

    if (error.contains('socket') || error.contains('network')) {
      return "No internet connection";
    } else if (error.contains('timeout')) {
      return "Request timed out. Please try again";
    } else if (error.contains('500')) {
      return "Server error. Please try again later";
    } else if (error.contains('404')) {
      return "Data not found";
    } else {
      return "Something went wrong. Please try again";
    }
  }

  @override
  void dispose() {
    _vendorNamesNotifier.dispose();
    _invoiceNumbersNotifier.dispose();
    super.dispose();
  }

  Future<void> fetchPayments() async {}
}
