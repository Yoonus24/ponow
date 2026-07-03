import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/models/ap/ap.dart';
import 'package:purchaseorders2/models/grn/grn.dart';
import 'package:purchaseorders2/models/outgoing/outgoing.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

class OutgoingPaymentProvider extends ChangeNotifier {
  OutgoingPaymentProvider() {
    if (kDebugMode) {
      debugPrint('🏗️ OutgoingPaymentProvider initialized');
    }
    _ensureDioInitialized();
  }

  Future<void> _ensureDioInitialized() async {
    if (kDebugMode) {
      debugPrint('🔄 Ensuring Dio client is initialized...');
    }
    await DioClient.init();
    if (kDebugMode) {
      debugPrint('✅ Dio client initialized successfully');
    }
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
  final Map<int, bool> _loadingPdfMap = {};

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
    if (kDebugMode) {
      debugPrint('🧹 Clearing error: $_error');
    }
    _error = '';
    notifyListeners();
  }

  bool isPdfLoading(int index) {
    return _loadingPdfMap[index] ?? false;
  }

  Future<void> generatePdf(int index, Outgoing payment) async {
    if (kDebugMode) {
      debugPrint(
        '📄 Generating PDF for outgoingId: ${payment.outgoingId} at index: $index',
      );
    }

    _loadingPdfMap[index] = true;
    notifyListeners();

    try {
      final poService = OutgoingPdf();
      if (kDebugMode) {
        debugPrint('📄 PDF service created, generating PDF...');
      }

      final pdfFile = await poService.generateOutgoingPdf(payment.outgoingId);

      if (kDebugMode) {
        debugPrint(
          '📄 PDF generated successfully, file size: ${pdfFile.lengthSync()} bytes',
        );
      }

      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());

      if (kDebugMode) {
        debugPrint('📄 PDF layout completed successfully');
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (kDebugMode) {
        debugPrint('❌ PDF Error: ${exception.message}');
        debugPrint('❌ Stack trace: $stackTrace');
      }
    } finally {
      _loadingPdfMap[index] = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('📄 PDF generation process completed for index: $index');
      }
    }
  }

  Future<void> loadAllRequiredData({
    required bool filterByAmount,
    required String status,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '🔄 Loading all required data - filterByAmount: $filterByAmount, status: $status',
      );
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('⏳ Starting parallel data fetch operations...');
      }

      await Future.wait([
        fetchFilteredOutgoings(status: status, filterByAmount: filterByAmount),
        fetchGrnList(),
        fetchApInvoices(),
      ]);

      if (kDebugMode) {
        debugPrint('✅ All required data loaded successfully');
        debugPrint('📊 Payments count: ${_payments.length}');
        debugPrint('📊 GRN count: ${_grnList.length}');
        debugPrint('📊 AP Invoices count: ${_apInvoices.length}');
      }
    } catch (e) {
      final exception = AppErrorHandler.handle(e);

      if (kDebugMode) {
        debugPrint('❌ Error loading required data: ${exception.message}');
        debugPrint('❌ Original error: $e');
      }

      _error = exception.message;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🏁 loadAllRequiredData completed');
      }
    }
  }

  Future<void> fetchGrnList() async {
    if (kDebugMode) {
      debugPrint('📋 Fetching GRN list...');
    }

    try {
      final response = await DioClient.dio.get(
        '/grns/getAll',
        options: Options(validateStatus: (status) => (status ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        _grnList = (response.data as List)
            .map((json) => GRN.fromJson(json))
            .toList();

        if (kDebugMode) {
          debugPrint(
            '✅ GRN list fetched successfully: ${_grnList.length} items',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ GRN fetch returned status: ${response.statusCode}');
        }
        _grnList = [];
      }
    } catch (e) {
      final exception = AppErrorHandler.handle(e);

      if (kDebugMode) {
        debugPrint('❌ Error fetching GRN list: ${exception.message}');
        debugPrint('❌ Original error: $e');
      }

      _error = exception.message;
      _grnList = [];
    }
    notifyListeners();
  }

  Future<void> fetchApInvoices() async {
    if (kDebugMode) {
      debugPrint('🚀 fetchAPInvoices CALLED');
    }

    try {
      final response = await DioClient.dio.get(
        '/apinvoices/getAll',
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (response.statusCode == 200) {
        _apInvoices = (response.data as List)
            .map((json) => ApInvoice.fromJson(json))
            .toList();

        if (kDebugMode) {
          debugPrint('✅ Fetched ${_apInvoices.length} AP invoices');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '⚠️ AP invoices fetch returned status: ${response.statusCode}',
          );
        }
        _apInvoices = [];
      }
    } catch (e) {
      _apInvoices = [];
      final exception = AppErrorHandler.handle(e);

      if (kDebugMode) {
        debugPrint('❌ Error fetching AP invoices: ${exception.message}');
        debugPrint('❌ Original error: $e');
      }

      _error = exception.message;
    }

    notifyListeners();
  }

  void setLoadingOutgoings(bool value) {
    if (kDebugMode) {
      debugPrint('🔄 Setting isLoadingOutgoings to: $value');
    }
    _isLoadingOutgoings = value;
    notifyListeners();
  }

  Future<void> fetchVendors() async {
    if (kDebugMode) {
      debugPrint('🏷️ Fetching vendor names from payments...');
    }

    final payments = _allPayments;

    if (kDebugMode) {
      debugPrint('📊 Processing ${payments.length} payments for vendors');
    }

    final vendors =
        payments
            .map((p) => p.vendorName)
            .where((v) => v != null && v.trim().isNotEmpty)
            .map((v) => v!)
            .toSet()
            .toList()
          ..sort();

    _vendorNamesNotifier.value = vendors;

    if (kDebugMode) {
      debugPrint('✅ Found ${vendors.length} unique vendors: $vendors');
    }
  }

  Future<void> fetchInvoiceNumbers() async {
    if (kDebugMode) {
      debugPrint('🔢 Fetching invoice numbers...');
    }

    if (_isLoadingInvoices) {
      if (kDebugMode) {
        debugPrint('⏳ Already loading invoices, skipping duplicate request');
      }
      return;
    }

    _isLoadingInvoices = true;
    notifyListeners();

    try {
      final response = await DioClient.dio.get(
        '/outgoingpayments/outgoing/getAll',
        queryParameters: {
          'status': 'active,Verified,Pending,Partially Paid',
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
          debugPrint('✅ Pending invoice list: ${invoiceNumbers.length} items');
          debugPrint(
            '📋 First 5 invoice numbers: ${invoiceNumbers.take(5).toList()}',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Fetch invoice numbers returned status: ${response.statusCode}',
          );
        }
        _invoiceNumbersNotifier.value = [];
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      _invoiceNumbersNotifier.value = [];

      if (kDebugMode) {
        debugPrint('❌ fetchInvoiceNumbers error: ${exception.message}');
        debugPrint('❌ Stack trace: $stackTrace');
      }

      _error = 'Unable to load outgoing payments. Please try again later.';
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🏁 fetchInvoiceNumbers completed');
      }
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
    if (kDebugMode) {
      debugPrint('🔍 fetchFilteredOutgoings called with:');
      debugPrint('   - fromDate: $fromDate');
      debugPrint('   - toDate: $toDate');
      debugPrint('   - vendorName: $vendorName');
      debugPrint('   - filterBy: $filterBy');
      debugPrint('   - status: $status');
      debugPrint('   - filterByAmount: $filterByAmount');
      debugPrint('   - sortOrder: $sortOrder');
      debugPrint('   - skip: $skip');
      debugPrint('   - limit: $limit');
      debugPrint('   - invoiceNo: $invoiceNo');
      debugPrint('   - isTableRefresh: $isTableRefresh');
    }

    if (skip == 0) {
      if (isTableRefresh) {
        _isTableLoading = true;
        if (kDebugMode) {
          debugPrint('🔄 Table refresh requested, setting table loading state');
        }
      } else {
        _isLoadingOutgoings = true;
        if (kDebugMode) {
          debugPrint('🔄 Initial load, setting loading state');
        }
      }
      notifyListeners();
    }

    _error = '';

    try {
      String? backendStatus;

      if (status != null && status.trim().isNotEmpty) {
        final uiStatus = status.toLowerCase().trim();

        if (uiStatus == 'pending') {
          backendStatus = 'active,Verified,Pending,Partially Paid';

          if (kDebugMode) {
            debugPrint(
              '🔄 Mapping "pending" to backend status: $backendStatus',
            );
          }
        } else if (uiStatus == 'partial') {
          backendStatus = 'Partially Paid';
          if (kDebugMode) {
            debugPrint(
              '🔄 Mapping "partial" to backend status: $backendStatus',
            );
          }
        } else if (uiStatus == 'paid') {
          backendStatus = 'Fully Paid';
          if (kDebugMode) {
            debugPrint('🔄 Mapping "paid" to backend status: $backendStatus');
          }
        } else {
          backendStatus = status;
          if (kDebugMode) {
            debugPrint('🔄 Using status as-is: $backendStatus');
          }
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

      if (kDebugMode) {
        debugPrint('📤 API Request URL: /outgoingpayments');
        debugPrint('📤 Query Parameters: $queryParams');
      }

      final response = await DioClient.dio.get(
        '/outgoingpayments',
        queryParameters: queryParams,
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (kDebugMode) {
        debugPrint('📥 API Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List ? raw : (raw['outgoings'] ?? []);

        if (kDebugMode) {
          debugPrint('📊 Received ${data.length} outgoings from API');
        }

        var fetched = data.map((e) => Outgoing.fromJson(e)).toList();

        if (kDebugMode) {
          debugPrint('✅ Parsed ${fetched.length} outgoings successfully');
        }

        if (fromDate != null && toDate != null && filterBy == 'paymentDate') {
          if (kDebugMode) {
            debugPrint('🔄 Applying local date filter for paymentDate range');
          }
          fetched = fetched.where((p) {
            final date = p.paymentDate;
            if (date == null) return false;

            return date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
                date.isBefore(toDate.add(const Duration(days: 1)));
          }).toList();

          if (kDebugMode) {
            debugPrint(
              '📊 After date filter: ${fetched.length} outgoings remain',
            );
          }
        }

        /// LOCAL FILTER
        if (invoiceNo != null && invoiceNo.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('🔍 Applying local invoice number filter: $invoiceNo');
          }
          fetched = fetched
              .where(
                (p) => (p.invoiceNo ?? '').toLowerCase().contains(
                  invoiceNo.toLowerCase(),
                ),
              )
              .toList();

          if (kDebugMode) {
            debugPrint(
              '📊 After invoice filter: ${fetched.length} outgoings remain',
            );
          }
        }

        // Pagination logic
        if (skip == 0) {
          _payments = fetched;
          if (kDebugMode) {
            debugPrint('📊 Reset payments list with ${fetched.length} items');
          }
        } else {
          _payments.addAll(fetched);
          if (kDebugMode) {
            debugPrint(
              '📊 Added ${fetched.length} items to existing list, total: ${_payments.length}',
            );
          }
        }

        // Sync backup list
        _allPayments = List.from(_payments);

        _error = '';

        if (kDebugMode) {
          debugPrint('✅ fetchFilteredOutgoings completed successfully');
          debugPrint('📊 Final payment count: ${_payments.length}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ API returned non-200 status: ${response.statusCode}');
          debugPrint('📄 Response data: ${response.data}');
        }
        _payments = [];
        _allPayments = [];
        _error = 'Unable to load outgoings. Please try again.';
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (kDebugMode) {
        debugPrint('❌ fetchFilteredOutgoings error: ${exception.message}');
        debugPrint('❌ Original error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }

      _payments = [];
      _allPayments = [];
      _error = exception.message;

      return [];
    } finally {
      _isLoadingOutgoings = false;
      _isTableLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🏁 fetchFilteredOutgoings completed');
      }
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
    if (kDebugMode) {
      debugPrint('📅 fetchByPaymentDate called:');
      debugPrint('   - fromDate: $fromDate');
      debugPrint('   - toDate: $toDate');
      debugPrint('   - status: $status');
      debugPrint('   - skip: $skip');
      debugPrint('   - limit: $limit');
    }

    try {
      final response = await DioClient.dio.get(
        '/outgoingpayments',
        queryParameters: {
          'filterBy': 'paymentDate',
          'fromDate': DateFormat('yyyy-MM-dd').format(fromDate),
          'toDate': DateFormat('yyyy-MM-dd').format(toDate),
          'status': status,
          'skip': skip,
          'limit': limit,
        },
        options: Options(validateStatus: (s) => (s ?? 500) < 500),
      );

      if (kDebugMode) {
        debugPrint('📥 API Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List ? raw : (raw['outgoings'] ?? []);

        final fetched = data.map((e) => Outgoing.fromJson(e)).toList();

        if (kDebugMode) {
          debugPrint('✅ Fetched ${fetched.length} outgoings by payment date');
        }

        _payments = fetched;
        notifyListeners();

        return fetched;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ API returned non-200 status: ${response.statusCode}');
        }
        _payments = [];
        notifyListeners();
        return [];
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (kDebugMode) {
        debugPrint('❌ fetchByPaymentDate error: ${exception.message}');
        debugPrint('❌ Original error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }

      _payments = [];
      _error = exception.message;

      notifyListeners();

      return [];
    }
  }

  Future<void> fetchAllOutgoings({DateTime? fromDate, DateTime? toDate}) async {
    if (kDebugMode) {
      debugPrint('📊 fetchAllOutgoings called:');
      debugPrint('   - fromDate: $fromDate');
      debugPrint('   - toDate: $toDate');
    }

    _isLoading = true;
    _error = "";
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};

      if (fromDate != null) {
        queryParams['fromDate'] = DateFormat('yyyy-MM-dd').format(fromDate);
      }
      if (toDate != null) {
        queryParams['toDate'] = DateFormat('yyyy-MM-dd').format(toDate);
      }

      if (kDebugMode) {
        debugPrint('📤 API Request: /outgoingpayments/outgoing/getAll');
        debugPrint('📤 Query Parameters: $queryParams');
      }

      final response = await DioClient.dio.get(
        '/outgoingpayments/outgoing/getAll',
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        debugPrint('📥 Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final raw = response.data;
        final List list = raw is List ? raw : raw['outgoings'] ?? [];

        _payments = list.map((e) => Outgoing.fromJson(e)).toList();
        _allPayments = List.from(_payments);

        if (kDebugMode) {
          debugPrint('✅ Fetched ${_payments.length} outgoings');
        }

        _error = "";
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ API returned non-200 status: ${response.statusCode}');
        }
        _payments = [];
        _allPayments = [];
        _error = "Unable to load ledger data";
      }
    } catch (e) {
      _payments = [];
      _allPayments = [];
      final exception = AppErrorHandler.handle(e);

      if (kDebugMode) {
        debugPrint('❌ fetchAllOutgoings error: ${exception.message}');
        debugPrint('❌ Original error: $e');
      }

      _error = exception.message;
    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('🏁 fetchAllOutgoings completed');
      }
    }
  }

  Future<String> saveOutgoingPayment(Outgoing outgoing) async {
    if (kDebugMode) {
      debugPrint(
        '💾 saveOutgoingPayment called for outgoingId: ${outgoing.outgoingId}',
      );
      debugPrint('📊 Outgoing data: ${outgoing.toJson()}');
    }

    try {
      final data = outgoing.toJson();
      data['createdDate'] = ServerTimeService.now.toIso8601String();

      if (kDebugMode) {
        debugPrint('📤 Sending POST request to /outgoingpayments/');
        debugPrint('📤 Request data: $data');
      }

      final response = await DioClient.dio.post(
        '/outgoingpayments/',
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (kDebugMode) {
        debugPrint(
          '📥 Save outgoing payment response status: ${response.statusCode}',
        );
        debugPrint('📥 Save outgoing payment response body: ${response.data}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save outgoing payment: ${response.data}');
      }

      final responseData = response.data;
      final outgoingId = responseData['outgoingId'] ?? outgoing.outgoingId;

      if (kDebugMode) {
        debugPrint(
          '✅ Outgoing payment saved successfully with ID: $outgoingId',
        );
      }

      return outgoingId;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ saveOutgoingPayment error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  Future<void> processOutgoingPayment(String outgoingId) async {
    if (kDebugMode) {
      debugPrint('⚙️ processOutgoingPayment called for ID: $outgoingId');
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '📤 Sending POST request to /outgoingpayments/$outgoingId/process',
        );
      }

      final response = await DioClient.dio.post(
        '/outgoingpayments/$outgoingId/process',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (kDebugMode) {
        debugPrint('📥 Response status: ${response.statusCode}');
        debugPrint('📥 Response body: ${response.data}');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to process payment: ${response.data} (Status: ${response.statusCode})',
        );
      }

      if (kDebugMode) {
        debugPrint('✅ Payment processed successfully for ID: $outgoingId');
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (kDebugMode) {
        debugPrint('❌ processOutgoingPayment error: ${exception.message}');
        debugPrint('❌ Original error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
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
      debugPrint('💳 processPayment called:');
      debugPrint('   - outgoingId: $outgoingId');
      debugPrint('   - paymentType: $paymentType');
      debugPrint('   - amount: $amount');
      debugPrint('   - paymentMode: $paymentMode');
      debugPrint('   - paymentMethod: $paymentMethod');
      debugPrint('   - transactionDetails: $transactionDetails');
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
        if (kDebugMode) {
          debugPrint('🔄 Cash payment method mapped to: $backendPaymentMethod');
        }
      } else {
        backendPaymentMethod = paymentMethod.toLowerCase();
        if (kDebugMode) {
          debugPrint('🔄 Bank payment method mapped to: $backendPaymentMethod');
        }
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

      if (kDebugMode) {
        debugPrint('📅 Payment date set to: $currentDateTime');
      }

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
        if (kDebugMode) {
          debugPrint('🏦 Added bank transaction details to request');
        }
      } else {
        requestData.addAll({
          if (transactionDetails['pettyCashAmount'] != null)
            'pettyCashAmount': transactionDetails['pettyCashAmount'],
          if (transactionDetails['hoCash'] != null)
            'hoCash': transactionDetails['hoCash'],
        });
        if (kDebugMode) {
          debugPrint('💰 Added cash transaction details to request');
        }
      }

      if (kDebugMode) {
        debugPrint(
          '📤 Sending PATCH request to /outgoingpayments/$outgoingId/payment',
        );
        debugPrint('📤 Request data: $requestData');
      }

      final response = await DioClient.dio.patch(
        '/outgoingpayments/$outgoingId/payment',
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (kDebugMode) {
        debugPrint('📥 Response Status: ${response.statusCode}');
        debugPrint('📥 Response Data: ${response.data}');
      }

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

      if (kDebugMode) {
        debugPrint('📊 Updated payment data:');
        debugPrint('   - Status: $newStatus');
        debugPrint('   - Remaining: $remaining');
        debugPrint('   - Total Paid: $totalPaid');
        debugPrint('   - History entries: ${history.length}');
      }

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

        if (kDebugMode) {
          debugPrint('✅ Updated payment at index $index');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Payment with ID $outgoingId not found in local list');
        }
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Payment processed & UI updated instantly');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ processPayment error: $e');
      }
      final exception = AppErrorHandler.handle(e);

      _error = exception.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processBulkPayments(
    List<BulkPayment> bulkPayments,
    List<Outgoing> outgoing,
  ) async {
    if (kDebugMode) {
      debugPrint('📦 processBulkPayments called:');
      debugPrint('   - Number of bulk payments: ${bulkPayments.length}');
      debugPrint('   - Number of outgoing items: ${outgoing.length}');
    }

    try {
      final Map<String, Outgoing> outgoingMap = {
        for (var o in outgoing) o.outgoingId: o,
      };

      if (kDebugMode) {
        debugPrint(
          '🗺️ Created outgoing map with ${outgoingMap.length} entries',
        );
      }

      double perOutgoingPartialAmount = 0.0;

      if (bulkPayments.isNotEmpty &&
          bulkPayments.first.paymentType == 'partial') {
        final totalEnteredAmount = bulkPayments.first.partialAmount ?? 0.0;

        if (totalEnteredAmount <= 0) {
          if (kDebugMode) {
            debugPrint('❌ Invalid partial amount: $totalEnteredAmount');
          }
          throw Exception('Partial amount must be greater than zero');
        }

        perOutgoingPartialAmount = double.parse(
          (totalEnteredAmount / bulkPayments.length).toStringAsFixed(2),
        );

        if (kDebugMode) {
          debugPrint(
            '📊 Per-outgoing partial amount: $perOutgoingPartialAmount',
          );
        }
      }

      for (final payment in bulkPayments) {
        if (kDebugMode) {
          debugPrint(
            '🔍 Validating payment for outgoingId: ${payment.outgoingId}',
          );
        }

        final match = outgoingMap[payment.outgoingId];
        if (match == null) {
          if (kDebugMode) {
            debugPrint('❌ Outgoing not found: ${payment.outgoingId}');
          }
          throw Exception('Outgoing not found: ${payment.outgoingId}');
        }

        final totalPayable = match.totalPayableAmount ?? 0;
        if (totalPayable <= 0) {
          if (kDebugMode) {
            debugPrint(
              '❌ Invalid payable amount for ${payment.outgoingId}: $totalPayable',
            );
          }
          throw Exception('Invalid payable for ${payment.outgoingId}');
        }

        if (payment.paymentType == 'full') {
          if (payment.fullPaymentAmount == null ||
              payment.fullPaymentAmount! <= 0) {
            if (kDebugMode) {
              debugPrint(
                '❌ Invalid full amount for ${payment.outgoingId}: ${payment.fullPaymentAmount}',
              );
            }
            throw Exception('Invalid full amount for ${payment.outgoingId}');
          }
        }

        if (payment.paymentType == 'partial') {
          if (perOutgoingPartialAmount >= totalPayable) {
            if (kDebugMode) {
              debugPrint(
                '❌ Partial amount exceeds payable for ${payment.outgoingId}: $perOutgoingPartialAmount >= $totalPayable',
              );
            }
            throw Exception(
              'Partial amount exceeds payable for ${payment.outgoingId}',
            );
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ All payments validated successfully');
      }

      final serverDate = ServerTimeService.now;

      if (kDebugMode) {
        debugPrint('📅 Server date: ${serverDate.toIso8601String()}');
      }

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

      if (kDebugMode) {
        debugPrint('📤 Bulk payment request data: $requestData');
      }

      final response = await DioClient.dio.patch(
        '/outgoingpayments/bulk/bulk-payment',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (kDebugMode) {
        debugPrint('📥 Bulk payment response status: ${response.statusCode}');
        debugPrint('📥 Response data: ${response.data}');
      }

      if (response.statusCode != 200 && response.statusCode != 207) {
        throw Exception('Bulk payment failed: ${response.statusCode}');
      }

      if (kDebugMode) {
        debugPrint('✅ Bulk payment completed successfully');
      }

      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (kDebugMode) {
        debugPrint('❌ processBulkPayments ERROR: ${exception.message}');
        debugPrint('❌ Original error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }

      rethrow;
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('🗑️ Disposing OutgoingPaymentProvider');
    }
    _vendorNamesNotifier.dispose();
    _invoiceNumbersNotifier.dispose();
    super.dispose();
    if (kDebugMode) {
      debugPrint('✅ OutgoingPaymentProvider disposed');
    }
  }

  Future<void> fetchPayments() async {
    if (kDebugMode) {
      debugPrint('📊 fetchPayments called (empty implementation)');
    }
  }
}
