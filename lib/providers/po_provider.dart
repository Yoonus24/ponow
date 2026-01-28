// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:purchaseorders2/models/discount_model.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/models/shippingandbillingaddress.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/vendorpurchasemodel.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';

class POProvider extends ChangeNotifier {
  static const String cloudBaseUrl = 'https://yenerp.com';
  static const String localBaseUrl = 'http://192.168.29.252:8000/nextjstestapi';

  final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: 'http://192.168.29.252:8000/nextjstestapi',
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            request: true,
            requestBody: true,
            responseBody: true,
            error: true,
          ),
        );

  // STATE VARIABLES
  List<PO> _pos = [];
  PO? _selectedPO;

  List<Vendor> _vendors = [];
  List<VendorAll> _vendorAllList = [];
  List<PurchaseItem> _purchaseItems = [];
  List<ShippingAddress> _shippingAddresses = [];
  List<BillingAddress> _billingAddress = [];
  List<String> _searchSuggestions = [];
  List<String> get searchSuggestions => _searchSuggestions;

  bool _isLoading = false;
  bool _isFetching = false;
  String? _error;
  bool _isVendorLoading = false;
  bool get isVendorLoading => _isVendorLoading;
  Map<String, dynamic>? _taxData;
  List<Item> _items = [];
  List<Item> approvedItems = [];

  // PAGINATION
  int _skip = 0;
  bool _hasMore = true;
  int currentSkip = 0;

  // FILTERED LISTS
  List<String> _filteredVendorNames = [];
  List<String> _filteredPurchaseItems = [];
  List<String> _filteredPurchaseOrder = [];

  // PO list for widgets
  final List<PO> _poList = [];

  // FILTER STATE
  String _currentFilterStatus = 'All';
  String? _selectedVendorFilter;
  DateTime? _selectedDateFilter;
  DateTimeRange? _selectedDateRangeFilter;
  String _searchQuery = '';
  String? _selectedItemNameFilter;
  String? _selectedRandomIdFilter;
  String _filterBy = 'orderDate'; // 'orderDate', 'approvedDate', 'rejectedDate'
  bool _includeInactive = false;

  // SCROLL CONTROLLERS
  final ScrollController vendorScrollController = ScrollController();
  final ScrollController vendorAllScrollController = ScrollController();
  final ScrollController itemScrollController = ScrollController();
  final ScrollController poScrollController = ScrollController();

  // GETTERS
  List<PO> get pos => _pos;
  List<PO> get poList => _poList;
  PO? get selectedPO => _selectedPO;

  List<Vendor> get vendors => _vendors;
  List<VendorAll> get vendorAllList => _vendorAllList;
  List<PurchaseItem> get purchaseItems => _purchaseItems;
  List<ShippingAddress> get shippingAddress => _shippingAddresses;
  List<BillingAddress> get billingAddress => _billingAddress;

  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  String? get error => _error;
  Map<String, dynamic>? get taxData => _taxData;

  List<Item> get items => _items;

  // Filtered lists for auto-complete
  List<String> get filteredVendorNames => _filteredVendorNames;
  List<String> get filteredPurchaseItems => _filteredPurchaseItems;
  List<String> get filteredPurchaseOrder => _filteredPurchaseOrder;

  // Filter getters
  String get currentFilterStatus => _currentFilterStatus;
  String? get selectedVendorFilter => _selectedVendorFilter;
  DateTime? get selectedDateFilter => _selectedDateFilter;
  DateTimeRange? get selectedDateRangeFilter => _selectedDateRangeFilter;
  String get searchQuery => _searchQuery;
  String? get selectedItemNameFilter => _selectedItemNameFilter;
  String? get selectedRandomIdFilter => _selectedRandomIdFilter;
  String get filterBy => _filterBy;
  bool get includeInactive => _includeInactive;

  Future<void> fetchPendingPOsOnly() async {
    _currentFilterStatus = "Pending";
    await fetchPOsWithFilters(status: "Pending", clearExisting: true);
  }

  Future<void> fetchApprovedPOsOnly() async {
    _currentFilterStatus = "Approved";
    await fetchPOsWithFilters(status: "Approved", clearExisting: true);
  }

  Future<void> fetchGRNConvertedPOsOnly() async {
    _currentFilterStatus = "GRNConverted";
    await fetchPOsWithFilters(status: "GRNConverted", clearExisting: true);
  }

  Future<void> fetchAPInvoiceConvertedPOsOnly() async {
    _currentFilterStatus = "APInvoiceConverted";
    await fetchPOsWithFilters(
      status: "APInvoiceConverted",
      clearExisting: true,
    );
  }

  Future<void> fetchAllPOsOnly() async {
    _currentFilterStatus = "All";
    await fetchPOsWithFilters(clearExisting: true);
  }

  Future<void> fetchSearchSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _dio.get(
        '/purchaseorders/search-suggestions',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _searchSuggestions = List<String>.from(data['suggestions'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  void onSuggestionSelected(String selectedSuggestion) {
    _searchQuery = selectedSuggestion;
    _searchSuggestions = [];
    notifyListeners();

    applyCurrentFilters();
  }

  // CLEANUP (CURRENTLY NO-OP)
  void cleanupUnusedKeys(List<PO> currentPOs) {
    final currentRandomIds = currentPOs
        .map((po) => po.randomId)
        .whereType<String>()
        .toSet();
  }

  // FILTER MANAGEMENT
  Future<void> setFilterStatus(String status) async {
    _currentFilterStatus = status;

    switch (status) {
      case "Pending":
        await fetchPendingPOsOnly();
        break;

      case "Approved":
        await fetchApprovedPOsOnly();
        break;

      case "GRNConverted":
        await fetchGRNConvertedPOsOnly();
        break;

      case "APInvoiceConverted":
        await fetchAPInvoiceConvertedPOsOnly();
        break;

      default:
        await fetchAllPOsOnly();
    }
  }

  void setVendorFilter(String? vendorName) {
    _selectedVendorFilter = vendorName;
    notifyListeners();
    applyCurrentFilters();
  }

  void setDateFilter(DateTime? date) {
    _selectedDateFilter = date;
    notifyListeners();
    applyCurrentFilters();
  }

  void setDateRangeFilter(DateTimeRange? dateRange) {
    _selectedDateRangeFilter = dateRange;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    applyCurrentFilters();
  }

  void setItemNameFilter(String? itemName) {
    _selectedItemNameFilter = itemName;
    notifyListeners();
  }

  void setRandomIdFilter(String? randomId) {
    _selectedRandomIdFilter = randomId;
    notifyListeners();
  }

  void setFilterBy(String field) {
    _filterBy = field;
    notifyListeners();
  }

  void setIncludeInactive(bool value) {
    _includeInactive = value;
    notifyListeners();
  }

  void clearFilters() {
    _currentFilterStatus = 'All';
    _selectedVendorFilter = null;
    _selectedDateFilter = null;
    _selectedDateRangeFilter = null;
    _searchQuery = '';
    _selectedItemNameFilter = null;
    _selectedRandomIdFilter = null;
    _filterBy = 'orderDate';
    _includeInactive = false;
    notifyListeners();
  }

  // BASIC STATE HELPERS
  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setSelectedPO(PO? po) {
    _selectedPO = po;
    notifyListeners();
  }

  void setPos(List<PO> newOrders) {
    _pos = newOrders;
    _poList
      ..clear()
      ..addAll(_pos);
    notifyListeners();
  }

  void setApprovedItems(List<Item> items) {
    approvedItems = items;
    notifyListeners();
  }

  void setTaxData(Map<String, dynamic> data) {
    _taxData = data;
    notifyListeners();
  }

  // ITEM MANAGEMENT
  void addItem(Item newItem) {
    _items.add(newItem);
    notifyListeners();
  }

  void removeItem(Item item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateItem(
    int index, {
    double? count,
    double? eachQuantity,
    required String poId,
  }) {
    final item = _items[index];

    if (count != null) item.pendingCount = count;
    if (eachQuantity != null) item.eachQuantity = eachQuantity;

    notifyListeners();
    updateItemFromBackend(index, poId);
  }

  // SCROLL LISTENERS
  void initVendorScrollListener() {
    vendorScrollController.addListener(() {
      if (vendorScrollController.position.pixels >=
              vendorScrollController.position.maxScrollExtent - 50 &&
          !_isFetching &&
          _hasMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          fetchingVendors(
            vendorName: _searchQuery,
            skip: _skip,
            limit: 50,
            append: true,
          );
        });
      }
    });
  }

  void initAllVendorScrollListener() {
    vendorAllScrollController.addListener(() async {
      if (vendorAllScrollController.position.pixels ==
              vendorAllScrollController.position.maxScrollExtent &&
          !_isFetching &&
          _hasMore) {
        _skip += 50;

        await fetchingAllVendors(
          vendorName: _searchQuery,
          skip: _skip,
          limit: 50,
          append: true,
        );
      }
    });
  }

  // SERVER TIME
  Future<String?> getServerDate() async {
    try {
      final response = await Dio().get("https://yenerp.com/liveapi/datetime");

      if (response.statusCode == 200) {
        return response.data["current_date"];
      }
    } catch (e) {
      print("❌ Error fetching server date: $e");
    }
    return null;
  }

  // BACKEND FILTERING METHODS
  Future<void> fetchPOsWithFilters({
    String? status,
    String? vendorName,
    String? itemName,
    String? randomId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTimeRange? dateRange,
    String? searchQuery,
    String? filterByField,
    bool? includeInactive,
    int skip = 0,
    int limit = 50,
    bool clearExisting = true,
    bool append = false,
  }) async {
    if (clearExisting && !append) {
      _skip = 0;
      _hasMore = true;
    }

    _setLoadingState(true);
    _setError(null);

    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }

      if (vendorName != null && vendorName.isNotEmpty) {
        queryParams['vendorName'] = vendorName;
      }

      if (itemName != null && itemName.isNotEmpty) {
        queryParams['itemName'] = itemName;
      }

      if (randomId != null && randomId.isNotEmpty) {
        queryParams['randomId'] = randomId;
      }

      final DateFormat dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

      if (dateRange != null) {
        queryParams['fromDate'] = dateFormatter.format(dateRange.start);
        queryParams['toDate'] = dateFormatter.format(dateRange.end);
      } else if (fromDate != null && toDate != null) {
        queryParams['fromDate'] = dateFormatter.format(fromDate);
        queryParams['toDate'] = dateFormatter.format(toDate);
      } else if (fromDate != null) {
        queryParams['fromDate'] = dateFormatter.format(fromDate);
      } else if (toDate != null) {
        queryParams['toDate'] = dateFormatter.format(toDate);
      }

      if (filterByField != null && filterByField.isNotEmpty) {
        queryParams['filterBy'] = filterByField;
      }

      if (includeInactive != null) {
        queryParams['includeInactive'] = includeInactive.toString();
      }

      print('Fetching POs with filters: $queryParams');
      final response = await _dio.get(
        '/purchaseorders/getAll',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        final List<PO> fetchedPOs = data.map((e) => PO.fromJson(e)).toList();

        // ---------------- CREDIT LIMIT FIX ----------------
        final List<PO> fixedPOs = fetchedPOs.map((po) {
          final double total = po.totalOrderAmount ?? 0;
          final int credit = po.creditLimit ?? 0;

          final bool exceedsCredit = credit > 0 && total > credit;

          if (exceedsCredit &&
              (po.poStatus == 'Pending' ||
                  po.poStatus == 'Pending for Approve')) {
            return po.copyWith(poStatus: 'CreditLimit for Approve');
          }

          return po;
        }).toList();

        // ---------------- 🔒 SAFETY FILTER (THE REAL FIX) ----------------
        final List<PO> filteredPOs = fixedPOs.where((po) {
          // Approved tab must NOT show fully GRN converted POs
          if (_currentFilterStatus == 'Approved') {
            return po.poStatus == 'Approved';
          }

          if (_currentFilterStatus == 'PartiallyReceived') {
            return po.poStatus == 'PartiallyReceived';
          }

          return true;
        }).toList();

        // ---------------- APPLY TO STATE ----------------
        if (clearExisting && !append) {
          _pos = filteredPOs;
          _poList
            ..clear()
            ..addAll(_pos);
        } else if (append) {
          _pos.addAll(filteredPOs);
          _poList.addAll(filteredPOs);
        } else {
          _pos = filteredPOs;
          _poList
            ..clear()
            ..addAll(_pos);
        }

        _hasMore = filteredPOs.length >= limit;
        _skip = skip + filteredPOs.length;

        notifyListeners();
      } else {
        _error = 'Failed: ${response.statusCode} - ${response.data}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoadingState(false);
    }
  }

  // APPLY CURRENT FILTERS
  Future<void> applyCurrentFilters() async {
    String? status;
    if (_currentFilterStatus != 'All') {
      status = _currentFilterStatus;
    }

    DateTime? fromDate;
    DateTime? toDate;

    if (_selectedDateRangeFilter != null) {
      fromDate = _selectedDateRangeFilter!.start;
      toDate = _selectedDateRangeFilter!.end;
    } else if (_selectedDateFilter != null) {
      fromDate = _selectedDateFilter!;
      toDate = _selectedDateFilter!.add(Duration(days: 1));
    }

    await fetchPOsWithFilters(
      status: status,
      vendorName: _selectedVendorFilter,
      itemName: _selectedItemNameFilter,
      randomId: _selectedRandomIdFilter,
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: _searchQuery,
      filterByField: _filterBy,
      includeInactive: _includeInactive,
      clearExisting: true,
    );
  }

  // SPECIFIC FILTER METHODS
  Future<void> fetchAllPOs() async {
    await fetchPOsWithFilters(clearExisting: true);
  }

  Future<void> fetchPendingPOs() async {
    await fetchPOsWithFilters(status: 'Pending', clearExisting: true);
  }

  Future<void> fetchApprovedPOs() async {
    await fetchPOsWithFilters(status: 'Approved', clearExisting: true);
  }

  Future<void> fetchTodayPOs() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    await fetchPOsWithFilters(
      fromDate: todayStart,
      toDate: todayEnd,
      filterByField: 'orderDate',
      clearExisting: true,
    );
  }

  Future<void> fetchThisWeekPOs() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      Duration(days: 6, hours: 23, minutes: 59),
    );

    await fetchPOsWithFilters(
      fromDate: startOfWeek,
      toDate: endOfWeek,
      filterByField: 'orderDate',
      clearExisting: true,
    );
  }

  Item _recalculatePending(Item item) {
    final double qty = item.pendingTotalQuantity ?? item.quantity ?? 0.0;
    final double price = item.newPrice ?? item.existingPrice ?? 0.0;

    final double base = qty * price;

    final double befAmt = item.befTaxDiscountType == 'amount'
        ? (item.befTaxDiscountAmount ?? 0.0)
        : base * (item.befTaxDiscount ?? 0.0) / 100;

    final double afterBef = base - befAmt;

    final double tax = afterBef * (item.taxPercentage ?? 0.0) / 100;

    final double aftAmt = item.afTaxDiscountType == 'amount'
        ? (item.afTaxDiscountAmount ?? 0.0)
        : (afterBef + tax) * (item.afTaxDiscount ?? 0.0) / 100;

    return item.copyWith(
      pendingTotalPrice: base,
      pendingBefTaxDiscountAmount: befAmt,
      pendingAfTaxDiscountAmount: aftAmt,
      pendingDiscountAmount: befAmt + aftAmt,
      pendingTaxAmount: tax,
      pendingFinalPrice: base - befAmt + tax - aftAmt,
    );
  }

  Future<void> fetchThisMonthPOs() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    await fetchPOsWithFilters(
      fromDate: startOfMonth,
      toDate: endOfMonth,
      filterByField: 'orderDate',
      clearExisting: true,
    );
  }

  Future<void> fetchPOsByVendor(String vendorName) async {
    await fetchPOsWithFilters(vendorName: vendorName, clearExisting: true);
  }

  Future<void> fetchPOsByItem(String itemName) async {
    await fetchPOsWithFilters(itemName: itemName, clearExisting: true);
  }

  Future<void> fetchPOsByRandomId(String randomId) async {
    await fetchPOsWithFilters(randomId: randomId, clearExisting: true);
  }

  Future<void> refreshPOList() async {
    await fetchPOs(); // or fetchAllPOs()
    notifyListeners(); // double-safe
  }

  // EXISTING FETCH METHODS
  Future<void> fetchPOs() async {
    _setLoadingState(true);
    _setError(null);
    notifyListeners();

    try {
      final response = await _dio.get('/purchaseorders/getAll');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data != null && data is List) {
          final List<PO> fetchedPOs = data
              .map((json) => PO.fromJson(json))
              .toList();

          final List<PO> fixedPOs = fetchedPOs.map((po) {
            final double total = po.totalOrderAmount ?? 0;
            final int credit = po.creditLimit ?? 0;

            final bool exceedsCredit = credit > 0 && total > credit;

            if (exceedsCredit &&
                (po.poStatus == 'Pending' ||
                    po.poStatus == 'Pending for Approve')) {
              return po.copyWith(poStatus: 'CreditLimit for Approve');
            }

            return po;
          }).toList();

          _pos = fixedPOs;
          _poList
            ..clear()
            ..addAll(_pos);

          cleanupUnusedKeys(_pos);
        } else {
          throw Exception('Invalid or empty response format');
        }
      } else {
        throw Exception(
          'Failed to load purchase orders: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _setError(_formatDioError(e));
    } catch (error) {
      _setError(error.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> fetchPOsByStatus(String status) async {
    await fetchPOsWithFilters(status: status, clearExisting: true);
  }

  // FETCH VENDORS
  Future<void> fetchingVendors({
    String vendorName = '',
    int skip = 0,
    int limit = 50,
    bool append = false,
  }) async {
    // ✅ prevent duplicate / build-time calls
    if (_isFetching) return;

    _isFetching = true;
    _isVendorLoading = true;

    try {
      final response = await _dio.get(
        '/vendors/exact-name/',
        queryParameters: {
          'vendor_name': vendorName,
          'skip': skip,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        final newVendorNames = data
            .map<String>((vendor) => vendor['vendorName'] ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        final newVendors = data.map<Vendor>((vendor) {
          return Vendor(
            vendorId: vendor['vendorId'] ?? '',
            vendorName: vendor['vendorName'] ?? '',
          );
        }).toList();

        if (append) {
          _filteredVendorNames.addAll(newVendorNames);
          _vendors.addAll(newVendors);
        } else {
          _filteredVendorNames = newVendorNames;
          _vendors = newVendors;
        }

        _hasMore = data.length >= limit;
        _skip = skip + data.length;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('❌ fetchingVendors error: $e');
    } finally {
      _isFetching = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void removeApprovedPO(String poId) {
    _pos.removeWhere((po) => po.purchaseOrderId == poId);
    _poList.removeWhere((po) => po.purchaseOrderId == poId);
    notifyListeners();
  }

  Future<void> fetchingAllVendors({
    String vendorName = '',
    int skip = 0,
    int limit = 50,
    bool append = false,
  }) async {
    try {
      _isFetching = true;
      _isVendorLoading = true;

      final url =
          '/vendors/vendor-names/?vendor_name=${Uri.encodeComponent(vendorName)}&skip=$skip&limit=$limit';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final newVendorNames = data
              .map<String>((vendor) => vendor['vendorName'] ?? '')
              .where((name) => name.isNotEmpty)
              .toList();

          final newVendor = data.map<VendorAll>((vendor) {
            return VendorAll(
              vendorId: vendor['vendorId'] ?? '',
              vendorName: vendor['vendorName'] ?? '',
              contactpersonPhone:
                  vendor['contactpersonPhone']?.toString() ?? '',
              contactpersonEmail: vendor['contactpersonEmail'] ?? '',
              address: vendor['address'] ?? '',
              country: vendor['country'] ?? '',
              paymentTerms: vendor['paymentTerms'] ?? '',
              state: vendor['state'] ?? '',
              city: vendor['city'] ?? '',
              postalCode: vendor['postalCode'] ?? 0,
              gstNumber: vendor['gstNumber'] ?? '',
              creditLimit: vendor['creditLimit'] ?? 0,
            );
          }).toList();

          if (append) {
            _filteredVendorNames.addAll(newVendorNames);
            _vendorAllList.addAll(newVendor);
          } else {
            _filteredVendorNames = newVendorNames;
            _vendorAllList = newVendor;
          }

          _hasMore = data.length >= limit;
        }
      } else if (response.statusCode == 404) {
        if (!append) {
          _filteredVendorNames = [];
          _vendorAllList = [];
        }
        _hasMore = false;
      }
    } on DioException catch (e) {
      debugPrint("Error fetching all vendors: ${e.message}");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> fetchVendors() async {
    _setLoadingState(true);
    _error = null;

    try {
      final response = await _dio.get('/vendors/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _vendors = data.map<Vendor>((json) => Vendor.fromJson(json)).toList();
        _filteredVendorNames = _vendors.map((v) => v.vendorName).toList();
      }
    } on DioException catch (e) {
      _error = _formatVendorError(e);
    } finally {
      _setLoadingState(false);
    }
  }

  // SHIPPING / BILLING
  Future<void> fetchShippingaddress() async {
    _setLoadingState(true);
    _error = null;

    try {
      final dio = Dio(BaseOptions(baseUrl: cloudBaseUrl));
      final response = await dio.get('/purchaseapi/poshippingaddress/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _shippingAddresses = data
            .map<ShippingAddress>((json) => ShippingAddress.fromJson(json))
            .toList();
      } else {
        _error = 'Failed to load shipping addresses: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Check internet connection and try again';
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> fetchBillingAddress() async {
    _setLoadingState(true);
    _error = null;

    try {
      final dio = Dio(BaseOptions(baseUrl: cloudBaseUrl));
      final response = await dio.get('/purchaseapi/pobusiness/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _billingAddress = data
            .map<BillingAddress>((json) => BillingAddress.fromJson(json))
            .toList();
      } else {
        _error = 'Failed to load billing addresses: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Check internet connection and try again';
    } finally {
      _setLoadingState(false);
    }
  }

  // SEARCH ITEMS
  Future<void> searchPurchaseItems(String query) async {
    try {
      final response = await _dio.get(
        '/rawMaterials/search',
        queryParameters: {'itemName': query},
      );

      if (response.statusCode == 200) {
        final decoded = response.data;
        final List<dynamic> data = decoded['items'];
        _purchaseItems = data
            .map((item) => PurchaseItem.fromJson(item))
            .toList();
        _filteredPurchaseItems = _purchaseItems
            .map((item) => item.itemName)
            .where((name) => name.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to load purchase items');
      }
    } catch (e) {
      throw Exception('Failed to load purchase items: $e');
    }
  }

  // SEARCH FUNCTIONALITY
  Timer? _searchTimer;

  void searchPOs(String query) {
    _searchQuery = query;

    _searchTimer?.cancel();

    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      applyCurrentFilters();
    });
  }

  // STATUS: APPROVE / REVERT
  Future<void> approvePo(String purchaseOrderId, String status, PO po) async {
    try {
      final response = await _dio.patch(
        '/purchaseorders/$purchaseOrderId',
        data: {'poStatus': status},
      );

      if (response.statusCode == 200) {
        final index = _pos.indexWhere(
          (p) => p.purchaseOrderId == purchaseOrderId,
        );
        if (index != -1) {
          _pos[index] = _pos[index].copyWith(poStatus: status);
        }

        final poListIndex = _poList.indexWhere(
          (p) => p.purchaseOrderId == purchaseOrderId,
        );
        if (poListIndex != -1) {
          _poList[poListIndex] = _poList[poListIndex].copyWith(
            poStatus: status,
          );
        }

        _pos.removeWhere((p) => p.purchaseOrderId == purchaseOrderId);
        _poList.removeWhere((p) => p.purchaseOrderId == purchaseOrderId);

        await applyCurrentFilters();

        notifyListeners();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to approve PO: ${response.statusCode}',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Add this method to POProvider
  Future<void> approveAndRemovePO(String purchaseOrderId) async {
    try {
      _setLoadingState(true);

      final po = _pos.firstWhere(
        (p) => p.purchaseOrderId == purchaseOrderId,
        orElse: () => throw Exception('PO not found'),
      );

      await approvePo(purchaseOrderId, 'Approved', po);

      await applyCurrentFilters();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> revertPOToPending(String purchaseOrderId) async {
    _setLoadingState(true);
    _setError(null);

    try {
      final response = await _dio.patch(
        '/purchaseorders/$purchaseOrderId',
        data: {'poStatus': 'Pending'},
      );

      if (response.statusCode == 200) {
        await applyCurrentFilters();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Server responded with ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _setError(_formatStatusChangeError(e));
    } catch (e) {
      _setError('Failed to revert PO: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> changePoStatusToPending(String purchaseOrderId) async {
    await revertPOToPending(purchaseOrderId);
  }

  // GRN CONVERSION
  Future<void> convertGrnPo(String poId, PO po) async {
    try {
      final pendingItems = po.items
          .where((item) => (item.pendingTotalQuantity ?? 0) > 0)
          .toList();

      if (pendingItems.isEmpty) {
        debugPrint("⚠️ No pending items to receive");
        return;
      }

      final payload = {
        'invoiceNo': po.invoiceNo,
        'invoiceDate': po.invoiceDate,
        'items': pendingItems.map((item) {
          return {
            'itemId': item.itemId,
            'receivedQuantity': item.receivedQuantity,
            'expiryDate': item.expiryDate,
          };
        }).toList(),
      };

      final url = '/purchaseorders/receivedupdates/$poId';
      debugPrint("➡️ PATCH $localBaseUrl$url");
      debugPrint("➡️ Payload: ${jsonEncode(payload)}");

      final response = await _dio.patch(url, data: payload);

      debugPrint("⬅️ Status: ${response.statusCode}");
      debugPrint("⬅️ Data: ${response.data}");

      if (response.statusCode == 200) {
        final allItemsReceived = po.items.every(
          (item) => (item.pendingTotalQuantity ?? 0) <= 0,
        );

        if (allItemsReceived) {
          await applyCurrentFilters();
        }

        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint("❌ convertGrnPo error");
      debugPrint("Message: ${e.message}");
      debugPrint("Status: ${e.response?.statusCode}");
      debugPrint("Body: ${e.response?.data}");
    } catch (e) {
      debugPrint("❌ convertGrnPo unknown error: $e");
    }
  }

  Future<void> convertPoToGrn(
    BuildContext context,
    String poId,
    String invoiceNo,
    double discount,
    String grnId, {
    double? roundOffAdjustment,
  }) async {
    _setLoadingState(true);
    _setError(null);

    try {
      print('=== Converting PO to GRN ===');
      print('GRN ID: $grnId');
      print('PO ID: $poId');
      print('Invoice No: $invoiceNo');
      print('Discount: $discount');
      print('Round Off Adjustment: $roundOffAdjustment');
      print('===========================');

      // IMPORTANT: Update the GRN with round-off adjustment
      final Map<String, dynamic> updateBody = {
        // 'discountPrice': discount,
        'roundOffAdjustment': roundOffAdjustment ?? 0.0,
        'grnRoundOffAmount': roundOffAdjustment ?? 0.0,
      };

      print("=== Updating GRN with round-off ===");
      print(jsonEncode(updateBody));

      // Update the GRN record with round-off
      final response = await _dio.patch('/grns/$grnId', data: updateBody);

      if (response.statusCode == 200) {
        // Success
        print('GRN updated successfully with round-off: $roundOffAdjustment');

        // Refresh GRN list
        final grnProvider = Provider.of<GRNProvider>(context, listen: false);
        await grnProvider.fetchFilteredGRNs();
      } else {
        throw Exception(
          'Failed to update GRN with round-off: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _setError(_formatConversionError(e));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating GRN with round-off: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _setError('Failed to convert PO to GRN: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      _setLoadingState(false);
    }
  }

  void updateInvoiceNumber(String purchaseOrderId) {
    debugPrint("Updating invoice number for PO: $purchaseOrderId");
  }

  Future<Map<String, dynamic>> calculateGrnOverallDiscount({
    required List<Map<String, dynamic>> items,
    required double discountAmount,
    required String discountType, // "before" | "after"
  }) async {
    final response = await _dio.post(
      '/purchaseorders/items/grn/calculate-overall-discount', // ✅ CORRECT
      data: {
        "applyOverallDiscount": true,
        "overallDiscountAmount": discountAmount,
        "discount_type": discountType,
        "items": items,
      },
    );

    return response.data;
  }

  // In POProvider class
  Future<Map<String, dynamic>> calculateItemTotalsBackend({
    required double pendingTotalQuantity,
    required double poQuantity,
    required double newPrice,
    double? befTaxDiscount,
    double? afTaxDiscount,
    double? befTaxDiscountAmount,
    double? afTaxDiscountAmount,
    String befTaxDiscountType = 'percentage',
    String afTaxDiscountType = 'percentage',
    double taxPercentage = 0,
    String taxType = 'cgst_sgst',
  }) async {
    try {
      // ✅ VALIDATE INPUTS BEFORE API CALL
      if (pendingTotalQuantity <= 0 || newPrice <= 0) {
        print('⚠️ Invalid inputs for backend calculation');
        return {
          'pendingTotalPrice': 0.0,
          'pendingBefTaxDiscountAmount': 0.0,
          'pendingAfTaxDiscountAmount': 0.0,
          'pendingTaxAmount': 0.0,
          'pendingFinalPrice': 0.0,
          'pendingDiscountAmount': 0.0,
          'pendingSgst': 0.0,
          'pendingCgst': 0.0,
          'pendingIgst': 0.0,
          'befTaxDiscount': befTaxDiscount ?? 0.0,
          'afTaxDiscount': afTaxDiscount ?? 0.0,
          'poQuantity': poQuantity,
          'quantity': pendingTotalQuantity,
        };
      }

      // ✅ BUILD CORRECT QUERY PARAMETERS
      final queryParameters = {
        'pendingTotalQuantity': pendingTotalQuantity,
        'poQuantity': poQuantity,
        'newPrice': newPrice,
        'taxPercentage': taxPercentage,
        'taxType': taxType,
      };

      // ✅ ADD DISCOUNT PARAMETERS BASED ON TYPE
      if (befTaxDiscountType == 'amount') {
        queryParameters['befTaxDiscountAmount'] = befTaxDiscountAmount ?? 0.0;
        queryParameters['befTaxDiscount'] = 0.0; // Send 0 for percentage
      } else {
        queryParameters['befTaxDiscount'] = befTaxDiscount ?? 0.0;
        queryParameters['befTaxDiscountAmount'] = 0.0; // Send 0 for amount
      }

      if (afTaxDiscountType == 'amount') {
        queryParameters['afTaxDiscountAmount'] = afTaxDiscountAmount ?? 0.0;
        queryParameters['afTaxDiscount'] = 0.0; // Send 0 for percentage
      } else {
        queryParameters['afTaxDiscount'] = afTaxDiscount ?? 0.0;
        queryParameters['afTaxDiscountAmount'] = 0.0; // Send 0 for amount
      }

      queryParameters['befTaxDiscountType'] = befTaxDiscountType;
      queryParameters['afTaxDiscountType'] = afTaxDiscountType;

      print('🔍 Sending to backend API:');
      print('   Query Params: $queryParameters');

      final response = await _dio.get(
        '/purchaseorders/items/totals',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to calculate item totals: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error calculating item totals from backend: $e');
      rethrow;
    }
  }

  // CALCULATIONS
  Future<Map<String, dynamic>> calculateItemTotals({
    required double pendingTotalQuantity,
    required double poQuantity,
    required double newPrice,
    double pendingBefTaxDiscountAmount = 0,
    double pendingAfTaxDiscountAmount = 0,
    double taxPercentage = 0,
    required String taxType,
    required String discountMode,
  }) async {
    try {
      double baseAmount = pendingTotalQuantity * newPrice;
      double befTaxDiscountAmount = 0.0;
      double afterBefTax = baseAmount;

      if (discountMode == 'percentage') {
        befTaxDiscountAmount = baseAmount * pendingBefTaxDiscountAmount / 100;
        afterBefTax = baseAmount - befTaxDiscountAmount;
      } else {
        befTaxDiscountAmount = pendingBefTaxDiscountAmount;
        afterBefTax = baseAmount - befTaxDiscountAmount;
      }

      double taxAmount = afterBefTax * taxPercentage / 100;
      double priceAfterTax = afterBefTax + taxAmount;

      double afTaxDiscountAmount = 0.0;
      double finalPrice = priceAfterTax;

      if (discountMode == 'percentage') {
        afTaxDiscountAmount = priceAfterTax * pendingAfTaxDiscountAmount / 100;
        finalPrice = priceAfterTax - afTaxDiscountAmount;
      } else {
        afTaxDiscountAmount = pendingAfTaxDiscountAmount;
        finalPrice = priceAfterTax - afTaxDiscountAmount;
      }

      double pendingSgst = 0.0;
      double pendingCgst = 0.0;
      double pendingIgst = 0.0;

      if (taxType == 'igst') {
        pendingIgst = taxAmount;
      } else {
        pendingCgst = taxAmount / 2;
        pendingSgst = taxAmount / 2;
      }

      final Map<String, dynamic> data = {
        'pendingTotalPrice': baseAmount,
        'pendingBefTaxDiscountAmount': befTaxDiscountAmount,
        'pendingAfTaxDiscountAmount': afTaxDiscountAmount,
        'pendingDiscountAmount': befTaxDiscountAmount + afTaxDiscountAmount,
        'pendingTaxAmount': taxAmount,
        'pendingSgst': pendingSgst,
        'pendingCgst': pendingCgst,
        'pendingIgst': pendingIgst,
        'pendingFinalPrice': finalPrice,
        'befTaxDiscount': pendingBefTaxDiscountAmount,
        'afTaxDiscount': pendingAfTaxDiscountAmount,
        'poQuantity': poQuantity,
        'quantity': pendingTotalQuantity,
      };

      _taxData = data;
      return data;
    } catch (error) {
      return {};
    }
  }

  Future<Map<String, dynamic>> calculateOverallDiscountAPI({
    required List<Map<String, dynamic>> items,
    required bool applyOverallDiscount,
    required String overallDiscountType,
    required double overallDiscount,
    required double overallDiscountAmount,
  }) async {
    // ✅ Build payload with all required fields
    final payload = {
      "applyOverallDiscount": applyOverallDiscount,
      "overallDiscountType": overallDiscountType,
      "overallDiscount": overallDiscount,
      "overallDiscountAmount": overallDiscountAmount,
      "items": items,
      // ✅ Add these if backend needs them
      "roundOffAdjustment": 0.0,
      "taxType": "cgst_sgst",
    };

    print(
      '🔄 API Request to: /purchaseorders/items/calculate-overall-discount',
    );
    print('📦 Payload: ${jsonEncode(payload)}');

    try {
      final response = await _dio.post(
        '/purchaseorders/items/calculate-overall-discount',
        data: payload,
      );

      print('📥 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = response.data;
        print('✅ Discount calculation successful!');
        print('🔍 Full API Response:');
        print(jsonEncode(decoded));

        // ✅ Debug: Print full response structure
        print('📋 Full response structure:');
        print('   success: ${decoded["success"]}');
        print('   items count: ${(decoded["items"] as List?)?.length ?? 0}');
        print('   summary keys: ${(decoded["summary"] as Map?)?.keys}');

        if (decoded.containsKey("summary")) {
          final summary = decoded["summary"];
          print('📊 Summary details:');
          print('   totalFinalAmount: ${summary["totalFinalAmount"]}');
          print('   totalTaxAmount: ${summary["totalTaxAmount"]}');
          print(
            '   overallDiscountAmount: ${summary["overallDiscountAmount"]}',
          );
          print('   totalDiscountAmount: ${summary["totalDiscountAmount"]}');
        }

        return decoded;
      } else {
        final errorBody = response.data;
        print('❌ API Error ${response.statusCode}');
        print('❌ Error details: $errorBody');

        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      print('❌ API Call Error: $e');
      rethrow;
    }
  }

  // UPDATE PO
  Future<void> updatePO(PO po) async {
    _setLoadingState(true);
    _setError(null);

    try {
      String formatDateForBackend(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) return "";

        try {
          if (dateStr.contains('-') && dateStr.split('-')[0].length == 4) {
            return dateStr;
          }

          if (dateStr.contains('-') && dateStr.split('-')[0].length == 2) {
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              return "${parts[2]}-${parts[1]}-${parts[0]}";
            }
          }

          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            return DateFormat('yyyy-MM-dd').format(date);
          }

          return dateStr;
        } catch (_) {
          return dateStr;
        }
      }

      final Map<String, dynamic> updateData = {
        "vendorName": po.vendorName,
        "vendorContact": po.vendorContact ?? "",
        "expectedDeliveryDate": formatDateForBackend(po.expectedDeliveryDate),
        "orderedDate": formatDateForBackend(po.orderedDate),
        "items": po.items.map((item) {
          // ✅ FIX: Convert amount → percentage for backend
          double base =
              (item.quantity ?? 0.0) *
              (item.newPrice ?? item.existingPrice ?? 0.0);

          double befTaxToSend = item.befTaxDiscount ?? 0.0;
          if (item.befTaxDiscountType == 'amount') {
            befTaxToSend = base > 0
                ? ((item.befTaxDiscountAmount ?? 0.0) / base) * 100
                : 0.0;
          }

          double afterBef = base - (item.befTaxDiscountAmount ?? 0.0);

          double afTaxToSend = item.afTaxDiscount ?? 0.0;
          if (item.afTaxDiscountType == 'amount') {
            afTaxToSend = afterBef > 0
                ? ((item.afTaxDiscountAmount ?? 0.0) / afterBef) * 100
                : 0.0;
          }

          String? expiryDate = item.expiryDate;
          if (expiryDate != null && expiryDate.isNotEmpty) {
            expiryDate = formatDateForBackend(expiryDate);
          } else {
            expiryDate = null;
          }

          return {
            "itemId": item.itemId ?? "",
            "itemName": item.itemName ?? "",
            "quantity": item.quantity ?? 0.0,
            "poQuantity": item.poQuantity ?? item.quantity ?? 0.0,
            "purchasecategoryName": item.purchasecategoryName ?? "",
            "purchasesubcategoryName": item.purchasesubcategoryName ?? "",
            "uom": item.uom ?? "",
            "count": item.count ?? 1.0,
            "eachQuantity": item.eachQuantity ?? 0.0,
            "receivedQuantity": item.receivedQuantity ?? 0.0,
            "damagedQuantity": item.damagedQuantity ?? 0.0,
            "taxPercentage": item.taxPercentage ?? 0.0,
            "existingPrice": item.existingPrice ?? 0.0,
            "newPrice": item.newPrice ?? 0.0,
            "taxType": item.taxType ?? 'cgst_sgst',

            // ✅ fixed lines
            "befTaxDiscount": double.parse(befTaxToSend.toStringAsFixed(2)),
            "afTaxDiscount": double.parse(afTaxToSend.toStringAsFixed(2)),

            "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,
            "afTaxDiscountAmount": item.afTaxDiscountAmount ?? 0.0,
            "befTaxDiscountType": item.befTaxDiscountType ?? 'percentage',
            "afTaxDiscountType": item.afTaxDiscountType ?? 'percentage',

            "discountAmount": item.discountAmount ?? 0.0,
            "taxAmount": item.taxAmount ?? 0.0,
            "barcode": item.barcode ?? "",
            "pendingCount": item.pendingCount ?? item.count ?? 1.0,
            "pendingQuantity": item.pendingQuantity ?? item.eachQuantity ?? 0.0,
            "pendingTotalQuantity":
                item.pendingTotalQuantity ?? item.quantity ?? 0.0,
            "pendingBefTaxDiscountAmount":
                item.pendingBefTaxDiscountAmount ??
                item.befTaxDiscountAmount ??
                0.0,
            "pendingAfTaxDiscountAmount":
                item.pendingAfTaxDiscountAmount ??
                item.afTaxDiscountAmount ??
                0.0,
            "pendingTaxAmount": item.pendingTaxAmount ?? item.taxAmount ?? 0.0,
            "pendingDiscountAmount":
                item.pendingDiscountAmount ?? item.discountAmount ?? 0.0,
            "pendingSgst": item.pendingSgst ?? 0.0,
            "pendingCgst": item.pendingCgst ?? 0.0,
            "pendingIgst": item.pendingIgst ?? 0.0,
            "pendingTotalPrice":
                item.pendingTotalPrice ?? item.totalPrice ?? 0.0,
            "pendingFinalPrice":
                item.pendingFinalPrice ?? item.finalPrice ?? 0.0,
            "status": item.status ?? "active",
            "expiryDate": expiryDate,
          };
        }).toList(),
        "totalOrderAmount": po.totalOrderAmount ?? 0.0,
        "pendingOrderAmount":
            po.pendingOrderAmount ?? po.totalOrderAmount ?? 0.0,
        "pendingDiscountAmount": po.pendingDiscountAmount ?? 0.0,
        "pendingTaxAmount": po.pendingTaxAmount ?? 0.0,
        "paymentTerms": po.paymentTerms ?? "",
        "shippingAddress": po.shippingAddress ?? "",
        "billingAddress": po.billingAddress ?? "",
        "contactpersonEmail": po.contactpersonEmail ?? "",
        "address": po.address ?? "",
        "country": po.country ?? "",
        "state": po.state ?? "",
        "city": po.city ?? "",
        "postalCode": po.postalCode ?? 0,
        "gstNumber": po.gstNumber ?? "",
        "creditLimit": po.creditLimit ?? 0,
        "poStatus": po.poStatus ?? "Pending",
        "lastUpdatedDate":
            po.lastUpdatedDate ?? DateTime.now().toIso8601String(),
        "roundOffAdjustment": po.roundOffAdjustment ?? 0.0,
        "roundOffValue": po.roundOffAdjustment ?? 0.0,
      };

      final response = await _dio.patch(
        '/purchaseorders/${po.purchaseOrderId}',
        data: updateData,
      );

      if (response.statusCode == 200) {
        final updatedPO = po.copyWith(pendingOrderAmount: po.totalOrderAmount);

        final index = _pos.indexWhere(
          (p) => p.purchaseOrderId == po.purchaseOrderId,
        );
        if (index != -1) _pos[index] = updatedPO;

        final poListIndex = _poList.indexWhere(
          (p) => p.purchaseOrderId == po.purchaseOrderId,
        );
        if (poListIndex != -1) _poList[poListIndex] = updatedPO;

        notifyListeners(); // 🔥 REQUIRED
      } else {
        throw Exception(
          "Failed to update PO: ${response.statusCode} - ${response.data}",
        );
      }
    } catch (error) {
      _setError(error.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  Future<Map<String, dynamic>> updatePoDetails(
    String poId,
    List<Item> items,
    String invoiceNumber,
    DateTime invoiceDate,
    double discount, {
    double? roundOffAdjustment,
  }) async {
    try {
      final dateFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
      final formattedInvoiceDate = dateFormatter.format(invoiceDate);

      final receivedItems = items
          .where((item) => (item.receivedQuantity ?? 0) > 0)
          .toList();

      if (receivedItems.isEmpty) {
        throw Exception("No items have received quantity greater than 0");
      }

      final List<Map<String, dynamic>> itemsList = receivedItems.map((item) {
        String? formattedExpiryDate;
        if (item.expiryDate != null && item.expiryDate!.isNotEmpty) {
          formattedExpiryDate = _normalizeDate(item.expiryDate!);
        }

        final double qty = item.receivedQuantity ?? 0.0;
        final double price = item.newPrice ?? 0.0;
        final double base = qty * price;

        double befTaxToSend = item.befTaxDiscount ?? 0.0;
        if (item.befTaxDiscountType == 'amount') {
          befTaxToSend = base > 0
              ? ((item.befTaxDiscountAmount ?? 0.0) / base) * 100
              : 0.0;
        }

        double afTaxToSend = item.afTaxDiscount ?? 0.0;
        final double afterBef = base - (item.befTaxDiscountAmount ?? 0.0);
        if (item.afTaxDiscountType == 'amount') {
          afTaxToSend = afterBef > 0
              ? ((item.afTaxDiscountAmount ?? 0.0) / afterBef) * 100
              : 0.0;
        }

        return {
          "itemId": item.itemId,
          "itemName": item.itemName,
          "count": item.count ?? 0,
          "eachQuantity": item.eachQuantity ?? 0.0,
          "receivedQuantity": qty,
          "pendingQuantity": item.pendingQuantity ?? 0.0,
          "pendingCount": item.pendingCount ?? 0.0,
          "damagedQuantity": item.damagedQuantity ?? 0.0,
          "newPrice": price,
          "befTaxDiscount": double.parse(befTaxToSend.toStringAsFixed(2)),
          "afTaxDiscount": double.parse(afTaxToSend.toStringAsFixed(2)),
          "taxPercentage": item.taxPercentage ?? 0.0,
          "expiryDate": formattedExpiryDate,
        };
      }).toList();

      final Map<String, dynamic> body = {
        "items": itemsList,
        "invoiceNo": invoiceNumber,
        "invoiceDate": formattedInvoiceDate,
        "roundOffAdjustment": roundOffAdjustment ?? 0.0,
        "grnRoundOffAmount": roundOffAdjustment ?? 0.0,
        "poId": poId,
        "freights": [],
      };

      final response = await _dio.patch(
        '/purchaseorders/receivedupdates/$poId',
        data: body,
      );

      if (response.statusCode != 200) {
        throw Exception(response.data?["detail"] ?? "PO update failed");
      }

      final String newStatus =
          response.data["poStatus"] ??
          response.data["status"] ??
          "PartiallyReceived";

      await _dio.patch('/purchaseorders/$poId', data: {"poStatus": newStatus});

      final index = _pos.indexWhere((p) => p.purchaseOrderId == poId);
      if (index != -1) {
        final updatedPoFromServer = PO.fromJson(response.data);

        _pos[index] = updatedPoFromServer.copyWith(
          poStatus: newStatus,
          roundOffAdjustment: roundOffAdjustment,
          lastUpdatedDate: DateTime.now().toIso8601String(),
          invoiceNo: invoiceNumber,
          invoiceDate: formattedInvoiceDate,
        );

        final poListIndex = _poList.indexWhere(
          (p) => p.purchaseOrderId == poId,
        );

        if (poListIndex != -1) {
          _poList[poListIndex] = _pos[index];
        }

        notifyListeners();
      }

      return response.data;
    } catch (e) {
      debugPrint("updatePoDetails failed: $e");
      throw Exception("updatePoDetails failed: $e");
    }
  }

  // UPDATE ITEM TO BACKEND
  Future<void> updateItemFromBackend(int index, String poId) async {
    final item = _items[index];

    final payload = {
      "items": [
        {
          "itemId": item.itemId,
          "newPrice": item.newPrice,
          "pendingCount": item.pendingCount,
          "eachQuantity": item.eachQuantity,
          "befTaxDiscount": item.befTaxDiscount,
          "afTaxDiscount": item.afTaxDiscount,
          "taxPercentage": item.taxPercentage,
          "taxType": item.taxType,
        },
      ],
    };

    try {
      final response = await _dio.patch(
        "/purchaseorders/$poId/items",
        data: payload,
      );

      if (response.statusCode == 200) {
        final decoded = response.data;
        final serverItem = decoded["items"][0];

        // Update only server-calculated fields
        _items[index].pendingTotalQuantity = serverItem["pendingTotalQuantity"];
        _items[index].pendingTotalPrice = serverItem["pendingTotalPrice"];
        _items[index].pendingDiscountAmount =
            serverItem["pendingDiscountAmount"];
        _items[index].pendingTaxAmount = serverItem["pendingTaxAmount"];
        _items[index].pendingFinalPrice = serverItem["pendingFinalPrice"];
        _items[index].pendingSgst = serverItem["pendingSgst"];
        _items[index].pendingCgst = serverItem["pendingCgst"];
        _items[index].pendingIgst = serverItem["pendingIgst"];
        _items[index].status = serverItem["status"];

        notifyListeners();
      } else {
        debugPrint("❌ Backend error: ${response.data}");
      }
    } catch (e) {
      debugPrint("❌ Error updating item: $e");
    }
  }

  // CHECK INVOICE DUPLICATE
  Future<bool> checkInvoiceNumberExists({
    required String invoiceNo,
    required String currentPurchaseOrderId,
    required String currentVendorName,
  }) async {
    try {
      final response = await _dio.get('/purchaseorders/getByInvoiceNo');
      if (response.statusCode == 200) {
        final List<dynamic> purchaseOrders = response.data;
        final searchInvoiceNo = invoiceNo.toLowerCase().trim();
        final searchVendorName = currentVendorName.toLowerCase().trim();

        for (final order in purchaseOrders) {
          final existingInvoice =
              order['invoiceNo']?.toString().toLowerCase().trim() ?? '';
          final poId = order['purchaseOrderId']?.toString() ?? '';
          final existingVendor =
              order['vendorName']?.toString().toLowerCase().trim() ?? '';

          if (existingInvoice == searchInvoiceNo &&
              existingVendor == searchVendorName &&
              poId != currentPurchaseOrderId) {
            return true;
          }
        }
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _normalizeDate(String date) {
    try {
      if (date.contains('-')) {
        List<String> parts = date.split('-');

        // dd-MM-yyyy → yyyy-MM-dd
        if (parts[0].length == 2 && parts[1].length == 2) {
          return "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      }
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  // HTTP HELPERS
  Future<Response> postWithRedirectHandling(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(url, data: body);

      if (response.statusCode! >= 300 && response.statusCode! < 400) {
        final location = response.headers['location'];
        if (location != null) {
          return await _dio.get(location.first);
        }
      }
      return response;
    } catch (error) {
      throw Exception('Network error occurred');
    }
  }

  // POST NEW PO
  Future<void> postPO(PO po, VendorAll selectedVendorDetails) async {
    _setLoadingState(true);
    _error = null;

    try {
      // --------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------
      final String formattedDate = DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      ).format(DateTime.now());

      String formatDateForBackend(String dateString) {
        if (dateString.isEmpty) return "";
        try {
          final parts = dateString.split('-');
          if (parts.length == 3 &&
              parts[0].length == 2 &&
              parts[1].length == 2 &&
              parts[2].length == 4) {
            // dd-MM-yyyy → yyyy-MM-dd
            return "${parts[2]}-${parts[1]}-${parts[0]}";
          }
          return dateString;
        } catch (_) {
          return dateString;
        }
      }

      final formattedOrderedDate = formatDateForBackend(po.orderedDate ?? "");
      final formattedExpectedDate = formatDateForBackend(
        po.expectedDeliveryDate ?? "",
      );

      // --------------------------------------------------
      // OVERALL DISCOUNT (PO LEVEL ONLY)
      // --------------------------------------------------
      final double overallDiscountValue = po.overallDiscount?.value ?? 0.0;
      final String overallDiscountType =
          po.overallDiscount?.mode == DiscountMode.percentage
          ? "percentage"
          : "amount";

      // --------------------------------------------------
      // ITEMS (BACKEND EXPECTS % VALUES)
      // --------------------------------------------------
      final List<Map<String, dynamic>> updatedItems = po.items.map((item) {
        final double base =
            (item.quantity ?? 0) * (item.newPrice ?? item.existingPrice ?? 0);

        // Convert befTax discount → percentage
        double befTaxPercent = item.befTaxDiscount ?? 0.0;
        if (item.befTaxDiscountType == 'amount' && base > 0) {
          befTaxPercent = ((item.befTaxDiscountAmount ?? 0.0) / base) * 100;
        }

        // Convert afTax discount → percentage
        double afTaxPercent = item.afTaxDiscount ?? 0.0;
        if (item.afTaxDiscountType == 'amount' && base > 0) {
          afTaxPercent = ((item.afTaxDiscountAmount ?? 0.0) / base) * 100;
        }

        return {
          "itemId": item.itemId ?? "",
          "itemName": item.itemName ?? "",

          "quantity": item.quantity ?? 0.0,
          "newPrice": item.newPrice ?? 0.0,
          "existingPrice": item.existingPrice ?? 0.0,

          "taxPercentage": item.taxPercentage ?? 0.0,
          "taxType": item.taxType ?? "cgst_sgst",

          // ✅ ALWAYS send discounts as percentages
          "befTaxDiscount": double.parse(befTaxPercent.toStringAsFixed(2)),
          "afTaxDiscount": double.parse(afTaxPercent.toStringAsFixed(2)),
          "befTaxDiscountType": "percentage",
          "afTaxDiscountType": "percentage",

          // ✅ Amounts sent separately
          "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,
          "afTaxDiscountAmount": item.afTaxDiscountAmount ?? 0.0,

          // Backend-calculated values (DO NOT recompute)
          "taxAmount": item.taxAmount ?? 0.0,
          "totalPrice": item.totalPrice ?? 0.0,
          "finalPrice": item.finalPrice ?? 0.0,

          "uom": item.uom ?? "",
          "count": item.count ?? 1.0,
          "eachQuantity": item.eachQuantity ?? 0.0,

          // Pending values (authoritative)
          "pendingCount": item.pendingCount ?? item.count ?? 1.0,
          "pendingQuantity": item.pendingQuantity ?? item.eachQuantity ?? 0.0,
          "pendingTotalQuantity":
              item.pendingTotalQuantity ?? item.quantity ?? 0.0,

          "pendingBefTaxDiscountAmount":
              item.pendingBefTaxDiscountAmount ?? 0.0,
          "pendingAfTaxDiscountAmount": item.pendingAfTaxDiscountAmount ?? 0.0,
          "pendingDiscountAmount": item.pendingDiscountAmount ?? 0.0,
          "pendingTaxAmount": item.pendingTaxAmount ?? 0.0,
          "pendingFinalPrice": item.pendingFinalPrice ?? item.finalPrice ?? 0.0,
          "pendingTotalPrice": item.pendingTotalPrice ?? item.totalPrice ?? 0.0,
        };
      }).toList();

      // --------------------------------------------------
      // TOTALS (AGGREGATION ONLY)
      // --------------------------------------------------
      final double totalPendingAmount = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingFinalPrice ?? 0),
      );

      final double totalPendingDiscount = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingDiscountAmount ?? 0),
      );

      final double totalPendingTax = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingTaxAmount ?? 0),
      );

      final double roundOffValue = po.roundOffAdjustment ?? 0.0;
      final double finalAmount = totalPendingAmount + roundOffValue;

      final bool isHoldOrder =
          finalAmount > (selectedVendorDetails.creditLimit ?? 0);

      // --------------------------------------------------
      // BUILD FINAL PO OBJECT
      // --------------------------------------------------
      final updatedPO = po.copyWith(
        orderDate: formattedDate,
        createdDate: formattedDate,
        lastUpdatedDate: formattedDate,
        approvedDate: formattedDate,
        rejectedDate: formattedDate,
        invoiceDate: formattedDate,

        orderedDate: formattedOrderedDate,
        expectedDeliveryDate: formattedExpectedDate,

        totalOrderAmount: finalAmount,
        pendingOrderAmount: finalAmount,
        pendingDiscountAmount: totalPendingDiscount,
        pendingTaxAmount: totalPendingTax,

        roundOffAdjustment: roundOffValue,
        poStatus: isHoldOrder ? 'CreditLimit for Approve' : 'Pending',
      );

      // --------------------------------------------------
      // FINAL PAYLOAD
      // --------------------------------------------------
      final Map<String, dynamic> poJson = updatedPO.toJson()
        ..['items'] = updatedItems
        ..['overallDiscountValue'] = overallDiscountValue
        ..['overallDiscountType'] = overallDiscountType
        ..['roundOffAdjustment'] = roundOffValue
        ..['roundOffValue'] = roundOffValue;

      print('📤 Posting PO');
      print('   Items count: ${updatedItems.length}');
      print(
        '   First item afTaxDiscount: ${updatedItems.first["afTaxDiscount"]}%',
      );

      // --------------------------------------------------
      // API CALL
      // --------------------------------------------------
      final response = await postWithRedirectHandling(
        '/purchaseorders/',
        poJson,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchPOsWithFilters(status: null, clearExisting: true);
      } else {
        throw Exception(
          "Failed to post PO: ${response.statusCode} - ${response.data}",
        );
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  // FILTER SUMMARY METHODS
  Map<String, int> getFilterCounts() {
    return {
      'All': _pos.length,
      'Pending': _pos.where((po) => po.poStatus == 'Pending').length,
      'Approved': _pos.where((po) => po.poStatus == 'Approved').length,
      'PartiallyReceived': _pos
          .where((po) => po.poStatus == 'PartiallyReceived')
          .length,
      'GRNConverted': _pos.where((po) => po.poStatus == 'GRNConverted').length,
      'APInvoiceConverted': _pos
          .where((po) => po.poStatus == 'APInvoiceConverted')
          .length,
    };
  }

  // ERROR FORMATTERS
  String _formatDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your network.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      default:
        return 'Failed to load purchase orders: ${e.message}';
    }
  }

  String _formatVendorError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        return e.response?.data['message']?.toString() ??
            'Server error: ${e.response?.statusCode}';
      default:
        return 'Failed to load vendors: ${e.message}';
    }
  }

  String _formatStatusChangeError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection available.';
      case DioExceptionType.badResponse:
        return e.response?.data['message']?.toString() ??
            'Server error (${e.response?.statusCode})';
      default:
        return 'Failed to change PO status: ${e.message}';
    }
  }

  String _formatConversionError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection available.';
      case DioExceptionType.badResponse:
        return e.response?.data['message']?.toString() ??
            'Server error (${e.response?.statusCode})';
      default:
        return 'Failed to convert PO to GRN: ${e.message}';
    }
  }

  // DISPOSE
  @override
  void dispose() {
    _searchTimer?.cancel();
    vendorScrollController.dispose();
    vendorAllScrollController.dispose();
    itemScrollController.dispose();
    poScrollController.dispose();
    super.dispose();
  }
}
