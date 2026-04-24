// ignore_for_file: prefer_final_fields, unnecessary_non_null_assertion, unnecessary_null_comparison, dead_null_aware_expression, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:purchaseorders2/models/branchlocation.dart';
import 'package:purchaseorders2/models/freight.dart';
import 'package:purchaseorders2/models/freight_name_model.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/models/purchase_tax_model.dart';
import 'package:purchaseorders2/models/shippingandbillingaddress.dart';
import 'package:purchaseorders2/models/vendorpurchasemodel.dart';
import 'package:purchaseorders2/pdfs/approved_pdf.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

class POProvider extends ChangeNotifier {
  // ==================== CONFIGURATION ====================
  final Dio _dio = DioClient.dio;

  // ==================== STATE VARIABLES ====================
  // PO Lists
  List<PO> _pos = [];
  List<PO> _pendingPOs = [];
  List<PO> get pos => _pos;
  List<PO> get pendingPOs => _pendingPOs;
  List<PO> get poList => _poList;
  final List<PO> _poList = [];
  PO? _selectedPO;
  PO? get selectedPO => _selectedPO;

  // Vendors
  List<Vendor> _vendors = [];
  List<VendorAll> _vendorAllList = [];
  List<VendorAll> vendorCache = [];
  List<String> _filteredVendorNames = [];
  bool vendorsLoaded = false;
  List<Vendor> get vendors => _vendors;
  List<VendorAll> get vendorAllList => _vendorAllList;
  List<String> get filteredVendorNames => _filteredVendorNames;

  // Purchase Items
  List<PurchaseItem> _purchaseItems = [];
  List<String> _filteredPurchaseItems = [];
  List<PurchaseItem> get purchaseItems => _purchaseItems;
  List<String> get filteredPurchaseItems => _filteredPurchaseItems;
  bool _isPreloadingItems = false;
  bool itemsLoaded = false;

  // Addresses
  List<ShippingAddress> _shippingAddresses = [];
  List<BillingAddress> _billingAddress = [];
  List<ShippingAddress> get shippingAddress => _shippingAddresses;
  List<BillingAddress> get billingAddress => _billingAddress;

  // Branches
  List<BranchLocation> _branches = [];
  List<BranchLocation> get branches => _branches;
  bool _isBranchLoading = false;
  bool get isBranchLoading => _isBranchLoading;

  // Taxes & Freights
  List<PurchaseTax> purchaseTaxes = [];
  List<FreightName> freightNames = [];
  Map<String, dynamic>? _taxData;
  Map<String, dynamic>? get taxData => _taxData;

  // Items
  final List<Item> _items = [];
  List<Item> approvedItems = [];
  List<Item> get items => _items;

  // Search & Suggestions
  List<String> _searchSuggestions = [];
  List<String> get searchSuggestions => _searchSuggestions;

  // Loading States
  bool _isLoading = false;
  bool _isFetching = false;
  bool _isVendorLoading = false;
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  bool get isVendorLoading => _isVendorLoading;
  Map<String, bool> _pdfLoadingMap = {};
  // Error State
  String? _error;
  String? get error => _error;

  // Pagination
  int _skip = 0;
  bool _hasMore = true;
  int currentSkip = 0;
  int? totalItems;

  // Filter States
  String _currentFilterStatus = 'All';
  String? _selectedVendorFilter;
  DateTime? _selectedDateFilter;
  DateTimeRange? _selectedDateRangeFilter;
  String _searchQuery = '';
  String? _selectedItemNameFilter;
  String? _selectedRandomIdFilter;
  String _filterBy = 'orderDate';
  bool _includeInactive = false;

  // Getters for Filters
  String get currentFilterStatus => _currentFilterStatus;
  String? get selectedVendorFilter => _selectedVendorFilter;
  DateTime? get selectedDateFilter => _selectedDateFilter;
  DateTimeRange? get selectedDateRangeFilter => _selectedDateRangeFilter;
  String get searchQuery => _searchQuery;
  String? get selectedItemNameFilter => _selectedItemNameFilter;
  String? get selectedRandomIdFilter => _selectedRandomIdFilter;
  String get filterBy => _filterBy;
  bool get includeInactive => _includeInactive;

  // Scroll Controllers
  final ScrollController vendorScrollController = ScrollController();
  final ScrollController vendorAllScrollController = ScrollController();
  final ScrollController itemScrollController = ScrollController();
  final ScrollController poScrollController = ScrollController();

  // Timers
  Timer? _vendorSearchTimer;
  Timer? _searchTimer;
  final bool _isRevertingPO = false;
  final bool _branchesLoaded = false;
  bool approvedPOLoaded = false;
  final List<String> _filteredPurchaseOrder = [];

  // ==================== INITIALIZATION ====================
  void initVendorScrollListener() {
    vendorScrollController.addListener(() {
      if (!_isFetching &&
          vendorScrollController.position.pixels >=
              vendorScrollController.position.maxScrollExtent - 100) {
        if (_hasMore && !_isFetching) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await fetchingVendors(
              vendorName: _searchQuery,
              skip: _skip,
              limit: 50,
              append: true,
            );
          });
        }
      }
    });
  }

  bool isPdfLoading(String poId) {
    return _pdfLoadingMap[poId] ?? false;
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

  Future<void> generatePdf(PO po, BuildContext context) async {
    final id = po.purchaseOrderId;

    _pdfLoadingMap[id] = true;
    notifyListeners();

    try {
      final poService = PurchaseOrderService();

      final pdfFile = await poService.generatePurchaseOrderPdf(id);

      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF failed: $e')));
    } finally {
      _pdfLoadingMap[id] = false;
      notifyListeners();
    }
  }

  // ==================== PO FETCHING METHODS ====================
  Future<void> fetchPendingPOsOnly() async {
    _currentFilterStatus = "Pending";
    await fetchPOsWithFilters(clearExisting: true);
  }

  Future<void> fetchApprovedPOsOnly() async {
    _currentFilterStatus = "Approved";
    await fetchPOsWithFilters(
      status: "Approved,PartiallyReceived",
      clearExisting: true,
    );
    approvedPOLoaded = true;
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
      final queryParams = _buildPOQueryParams(
        status: status,
        vendorName: vendorName,
        itemName: itemName,
        randomId: randomId,
        fromDate: fromDate,
        toDate: toDate,
        dateRange: dateRange,
        searchQuery: searchQuery,
        filterByField: filterByField,
        includeInactive: includeInactive,
        skip: skip,
        limit: limit,
      );

      final response = await _dio.get(
        '/purchaseorders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        final List<PO> fetchedPOs = _parsePOsFromData(data);

        _updatePOList(fetchedPOs, clearExisting, append, skip, limit);
        notifyListeners();
      } else {
        _error = 'Failed: ${response.statusCode} - ${response.data}';
      }
    } on DioException catch (e) {
      _setError(_getReadableError(e));
    } catch (e) {
      _setError("Something went wrong. Please try again.");
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> fetchPendingPOsFromBackend({
    int skip = 0,
    int limit = 50,
    bool clearExisting = true,
  }) async {
    _setLoadingState(true);
    _setError(null);

    try {
      final now = ServerTimeService.now;
      final formatter = DateFormat('yyyy-MM-dd');
      final fromDate = formatter.format(
        now.subtract(const Duration(days: 3650)),
      );
      final toDate = formatter.format(now.add(const Duration(days: 1)));

      final response = await _dio.get(
        '/purchaseorders/pending/purchase',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          'fromDate': fromDate,
          'toDate': toDate,
        },
      );

      final data = response.data;
      List listData = [];
      int? total;

      if (data is Map) {
        listData = data['purchaseOrders'] ?? [];
        total = data['totalItems'];
      } else if (data is List) {
        listData = data;
      }

      final List<PO> fetchedPOs = listData
          .map((e) {
            try {
              return PO.fromJson(e);
            } catch (err) {
              print("❌ PARSE ERROR: $err");
              return null;
            }
          })
          .whereType<PO>()
          .toList();

      totalItems = total;

      if (clearExisting) {
        _pendingPOs = List.from(fetchedPOs);
        _pos = List.from(fetchedPOs);
        _poList
          ..clear()
          ..addAll(_pos);
      } else {
        _pendingPOs.addAll(fetchedPOs);
        _pos.addAll(fetchedPOs);
        _poList.addAll(fetchedPOs);
      }

      _hasMore = fetchedPOs.length >= limit;
      _skip = skip + fetchedPOs.length;

      notifyListeners();
    } catch (e) {
      print("❌ ERROR: $e");
      _setError(_handleError(e));
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> fetchPOs() async {
    _setLoadingState(true);
    _setError(null);

    try {
      final response = await _dio.get('/purchaseorders/pending/purchase');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          final List<PO> fetchedPOs = data
              .map((json) => PO.fromJson(json))
              .toList();
          _pos = fetchedPOs;
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
      _setError(_getReadableError(e));
    } catch (e) {
      _setError("Something went wrong. Please try again.");
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> fetchPOsByStatus(String status) async {
    await fetchPOsWithFilters(status: status, clearExisting: true);
  }

  Future<PO?> fetchPOById(String id) async {
    try {
      final response = await _dio.get("/purchaseorders/$id");
      if (response.statusCode == 200) {
        return PO.fromJson(response.data);
      }
    } catch (e) {
      print("ERROR FETCH FULL PO: $e");
    }
    return null;
  }

  // ==================== VENDOR METHODS ====================
  Future<void> preloadVendors() async {
    if (_isFetching || _vendors.isNotEmpty) return;

    try {
      _isFetching = true;
      final response = await _dio.get(
        '/vendors/limit',
        queryParameters: {'limit': 1000},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _vendors = (data['vendors'] as List)
            .map<Vendor>((v) => Vendor.fromJson(v))
            .toList();
        _filteredVendorNames = _vendors.map((v) => v.vendorName).toList();
      }
    } catch (e) {
      debugPrint('Preload vendors error: $e');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void searchVendorsDebounced(String query) {
    _vendorSearchTimer?.cancel();
    _vendorSearchTimer = Timer(const Duration(milliseconds: 300), () {
      _actualVendorSearch(query);
    });
  }

  Future<void> _actualVendorSearch(String query) async {
    if (query.isEmpty || query.length < 1) {
      notifyListeners();
      return;
    }

    final cachedResults = _vendors
        .where((v) => v.vendorName.toLowerCase().contains(query.toLowerCase()))
        .take(50)
        .toList();

    if (cachedResults.isNotEmpty) {
      _filteredVendorNames = cachedResults.map((v) => v.vendorName).toList();
      notifyListeners();
    }

    await fetchingVendors(vendorName: query);
  }

  Future<void> fetchingVendors({
    String vendorName = '',
    int skip = 0,
    int limit = 50,
    bool append = false,
  }) async {
    if (_isFetching) return;

    _isFetching = true;
    _isVendorLoading = true;
    notifyListeners(); // 🔥 UI loading start

    try {
      final response = await _dio.get(
        '/vendors/exact-names/',
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
      _isVendorLoading = false;
      notifyListeners();
    }
  }

  Future<List<VendorAll>> fetchingAllVendors({
    String vendorName = '',
    int skip = 0,
    int limit = 100,
    bool append = false,
  }) async {
    // ✅ cache optimization
    if (vendorCache.isNotEmpty && vendorName.isEmpty && !append) {
      return vendorCache;
    }

    try {
      _isFetching = true;
      _isVendorLoading = true;
      notifyListeners();

      // ✅ FIX: use queryParameters instead of manual URL
      final response = await _dio.get(
        '/vendors/vendor-names/',
        queryParameters: {
          if (vendorName.isNotEmpty) "vendor_name": vendorName, // 🔥 key fix
          "skip": skip,
          "limit": limit,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final List data = response.data;

        final fetchedVendors = data.map<VendorAll>((vendor) {
          return VendorAll(
            vendorId: vendor['vendorId'] ?? '',
            vendorName: vendor['vendorName'] ?? '',
            contactpersonPhone: vendor['contactpersonPhone']?.toString() ?? '',
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

        // ✅ cache store
        if (vendorName.isEmpty && !append) {
          vendorCache = fetchedVendors;
          vendorsLoaded = true;
        }

        // ✅ list update
        if (!append) {
          _vendorAllList = fetchedVendors;
        } else {
          _vendorAllList.addAll(fetchedVendors);
        }

        // ✅ pagination
        _hasMore = fetchedVendors.length >= limit;

        notifyListeners();
        return fetchedVendors;
      }

      return [];
    } catch (e) {
      debugPrint("❌ Error fetching all vendors: $e");
      return [];
    } finally {
      _isFetching = false;
      _isVendorLoading = false;
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

  // ==================== PURCHASE ITEMS METHODS ====================
  Future<void> preloadAllPurchaseItems() async {
    if (_isPreloadingItems || itemsLoaded) return;

    _isPreloadingItems = true;

    try {
      _purchaseItems.clear();

      int skip = 0;
      const int limit = 100;
      bool hasMore = true;

      while (hasMore) {
        final response = await _dio.get(
          '/rawMaterials/',
          queryParameters: {"skip": skip, "limit": limit},
        );

        if (response.statusCode == 200) {
          List<dynamic> data = [];

          if (response.data is Map && response.data['items'] != null) {
            data = response.data['items'];
          } else if (response.data is List) {
            data = response.data;
          }

          if (data.isEmpty) {
            hasMore = false;
            break;
          }

          final items = data
              .map<PurchaseItem>((e) => PurchaseItem.fromJson(e))
              .where((item) => item.itemName?.isNotEmpty ?? false)
              .toList();

          _purchaseItems.addAll(items);

          skip += limit;
        } else {
          hasMore = false;
        }
      }

      itemsLoaded = true; // IMPORTANT FIX
      notifyListeners();
    } catch (e) {
      debugPrint("Preload error: $e");
    } finally {
      _isPreloadingItems = false;
    }
  }

  Future<bool> fetchAllItems({
    int skip = 0,
    int limit = 100,
    bool append = false,
  }) async {
    try {
      final response = await _dio.get(
        '/rawMaterials/getAll',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final decoded = response.data;
        List<dynamic> data = [];

        if (decoded is Map && decoded.containsKey('items')) {
          data = decoded['items'] ?? [];
        } else if (decoded is List) {
          data = decoded;
        }

        final newItems = data
            .map((item) => PurchaseItem.fromJson(item))
            .where((item) => item.itemName?.isNotEmpty ?? false)
            .toList();

        final newItemNames = newItems
            .map((item) => item.itemName ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        if (append) {
          _purchaseItems.addAll(newItems);
          _filteredPurchaseItems.addAll(newItemNames);
        } else {
          _purchaseItems = newItems;
          _filteredPurchaseItems = newItemNames;
        }
        notifyListeners();
        return newItems.length >= limit;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<PurchaseItem>> searchPurchaseItems({
    required String query,
    int skip = 0,
    int limit = 50,
    bool append = false,
  }) async {
    try {
      final response = await _dio.post(
        '/rawMaterials/',
        data: {"itemName": query, "skip": skip, "limit": limit},
      );

      if (response.statusCode == 200) {
        final data = response.data['items'];
        final items = data
            .map<PurchaseItem>((e) => PurchaseItem.fromJson(e))
            .toList();

        if (!append) {
          _purchaseItems = items;
        } else {
          _purchaseItems.addAll(items);
        }

        notifyListeners();
        return items;
      }
    } catch (e) {
      print("Search error: $e");
    }
    return [];
  }

  // ==================== ADDRESS METHODS ====================
  Future<void> fetchShippingaddress() async {
    _setLoadingState(true);
    _error = null;

    try {
      final response = await _dio.get(
        'https://yenerp.com/purchaseapi/poshippingaddress/',
      );

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
      final response = await _dio.get(
        'https://yenerp.com/purchaseapi/pobusiness/',
      );

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

  // ==================== BRANCH METHODS ====================
  Future<void> fetchBranches({bool force = false}) async {
    if (_isBranchLoading) return;
    if (_branches.isNotEmpty && !force) return;

    _isBranchLoading = true;
    notifyListeners();

    try {
      // ✅ separate dio ONLY for branches
      final Dio branchDio = Dio(
        BaseOptions(
          baseUrl: 'https://yenerp.com/masteradminapi',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await branchDio.get('/locations/');

      if (response.statusCode == 200 && response.data is List) {
        _branches = (response.data as List)
            .map((e) => BranchLocation.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Branch fetch error: $e");
    }

    _isBranchLoading = false;
    notifyListeners();
  }

  Future<void> preloadBranches() async {
    if (_branches.isEmpty) {
      await fetchBranches(force: true);
    }
  }

  // ==================== TAX & FREIGHT METHODS ====================
  Future<void> fetchPurchaseTaxes() async {
    try {
      final response = await _dio.get('/purchasetaxes/');
      if (response.statusCode == 200) {
        purchaseTaxes = (response.data as List)
            .map((e) => PurchaseTax.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> fetchFreightNames() async {
    try {
      final response = await _dio.get('/freights/');
      if (response.statusCode == 200) {
        freightNames = (response.data as List)
            .map((e) => FreightName.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<FreightData> calculateFreightTotals({
    required double amount,
    required String taxCode,
    required String taxType,
  }) async {
    final response = await _dio.get(
      '/purchaseorders/freight/totals',
      queryParameters: {"amt": amount, "tCode": taxCode, "taxType": taxType},
    );
    return FreightData.fromJson(response.data);
  }

  Future<Map<String, dynamic>> calculatePOTotals({
    required List items,
    required List freights,
  }) async {
    final response = await _dio.post(
      '/purchaseorders/calculate-totals',
      data: {"items": items, "freights": freights},
    );
    return response.data;
  }

  // ==================== PO ACTIONS ====================
  Future<void> approvePo(String purchaseOrderId) async {
    try {
      final response = await _dio.patch(
        '/purchaseorders/approved/$purchaseOrderId',
      );
      if (response.statusCode == 200) {
        print("PO Approved Successfully");
        await fetchPendingPOsFromBackend(clearExisting: true);
        notifyListeners();
      } else {
        throw Exception("Failed to approve PO");
      }
    } catch (e) {
      print("Approve PO Error: $e");
      _setError("Failed to approve PO");
    }
  }

  Future<void> rejectPo(String purchaseOrderId) async {
    try {
      final response = await _dio.patch(
        '/purchaseorders/rejected/$purchaseOrderId',
      );
      if (response.statusCode == 200) {
        print("PO Rejected Successfully");
        await fetchPendingPOsFromBackend(clearExisting: true);
        notifyListeners();
      } else {
        throw Exception("Failed to reject PO");
      }
    } catch (e) {
      print("Reject PO Error: $e");
      _setError("Failed to reject PO");
    }
  }

  Future<void> approveAndRemovePO(String purchaseOrderId) async {
    try {
      _setLoadingState(true);
      await approvePo(purchaseOrderId);
      await fetchPendingPOsFromBackend(clearExisting: true);
      notifyListeners();
    } catch (e) {
      _setError(_handleError(e));
      rethrow;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> revertPOToPending(String purchaseOrderId) async {
    _setLoadingState(true);
    _setError(null);

    try {
      await _dio.put(
        '/purchaseorders/$purchaseOrderId',
        data: {"poStatus": "Pending"},
      );
      await fetchPendingPOsFromBackend(clearExisting: true);
    } catch (e) {
      _setError(_handleError(e));
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> changePoStatusToPending(String id) async {
    await _dio.put('/purchaseorders/$id', data: {"poStatus": "Pending"});
  }

  // Future<void> convertGrnPo(String poId, PO po) async {
  //   try {
  //     final pendingItems = po.items
  //         .where((item) => (item.pendingTotalQuantity ?? 0) > 0)
  //         .toList();

  //     if (pendingItems.isEmpty) {
  //       debugPrint("⚠️ No pending items to receive");
  //       return;
  //     }

  //     final response = await _dio.patch(
  //       '/purchaseorders/receivedupdates/$poId',
  //       data: {
  //         'items': pendingItems
  //             .map(
  //               (item) => {
  //                 'itemId': item.itemId,
  //                 'receivedQuantity': item.receivedQuantity,
  //                 'expiryDate': item.expiryDate,
  //               },
  //             )
  //             .toList(),
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final PO? updatedPo = await fetchPOById(poId);
  //       final bool allItemsReceived =
  //           updatedPo?.items.every(
  //             (item) => (item.pendingTotalQuantity ?? 0) <= 0,
  //           ) ??
  //           false;
  //       final String newStatus = allItemsReceived
  //           ? 'GRNConverted'
  //           : 'PartiallyReceived';

  //       await _dio.patch(
  //         '/purchaseorders/$poId',
  //         data: {'poStatus': newStatus},
  //       );

  //       await applyCurrentFilters();
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     debugPrint("❌ convertGrnPo error: $e");
  //   }
  // }

  Future<void> updatePO(PO po) async {
    _setLoadingState(true);
    _setError(null);

    try {
      final String now = ServerTimeService.now.toIso8601String();
      final updatedItems = _buildUpdatedItems(po.items);

      final double totalFreightAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.amount ?? 0),
      );
      final double totalFreightTaxAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.taxAmount ?? 0),
      );

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
      final double finalAmount =
          totalPendingAmount +
          totalFreightAmount +
          totalFreightTaxAmount +
          roundOffValue;

      final Map<String, dynamic> updateData = {
        "lastUpdatedDate": now,
        "vendorName": po.vendorName,
        "vendorContact": po.vendorContact,
        "items": updatedItems,
        "totalOrderAmount": finalAmount,
        "pendingOrderAmount": finalAmount,
        "pendingDiscountAmount": totalPendingDiscount,
        "pendingTaxAmount": totalPendingTax,
        "roundOffAdjustment": roundOffValue,
        "roundOffValue": roundOffValue,
        "freights": po.freights?.map((f) => f.toJson()).toList() ?? [],
        "totalFreightAmount": totalFreightAmount,
        "totalFreightTaxAmount": totalFreightTaxAmount,
        "location": po.location,
        "locationName": po.locationName,
        "orderDate": po.orderDate,
        "expectedDeliveryDate": po.expectedDeliveryDate,
      };

      final response = await _dio.patch(
        '/purchaseorders/${po.purchaseOrderId}',
        data: updateData,
      );

      if (response.statusCode == 200) {
        await fetchPOsWithFilters(clearExisting: true);
      } else {
        throw Exception("Failed to update PO");
      }
    } catch (e) {
      _setError(_handleError(e));
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
    List<FreightData>? freights,
    double? totalFreightAmount,
    double? totalFreightTaxAmount,
  }) async {
    debugPrint("🟢 updatePoDetails() CALLED");
    debugPrint("📌 PO ID: $poId");

    try {
      /// FORMAT DATE
      final dateFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
      final formattedInvoiceDate = dateFormatter.format(invoiceDate);

      debugPrint("📅 Invoice Date (formatted): $formattedInvoiceDate");
      debugPrint("🧾 Invoice No: $invoiceNumber");

      /// FIND PO
      debugPrint("🔍 Finding PO in local list...");
      final PO po = _pos.firstWhere(
        (p) => p.purchaseOrderId == poId,
        orElse: () => throw Exception("PO not found"),
      );
      debugPrint("✅ PO found: ${po.randomId}");

      /// PREPARE ITEMS
      debugPrint("📦 Preparing items for API...");
      final receivedItems = items.map((item) => item.copyWith()).toList();

      final itemsList = receivedItems.map((item) {
        String? formattedExpiryDate;

        if (item.expiryDate != null && item.expiryDate!.isNotEmpty) {
          formattedExpiryDate = _normalizeDate(item.expiryDate);
        }

        debugPrint("➡️ Item: ${item.itemName}");
        debugPrint("   ID: ${item.itemId}");
        debugPrint("   Received Qty: ${item.receivedQuantity}");
        debugPrint("   BefTax: ${item.befTaxDiscount}");
        debugPrint("   AfTax: ${item.afTaxDiscount}");
        debugPrint("   Expiry: $formattedExpiryDate");

        return {
          "itemId": item.itemId,
          "receivedQuantity": item.receivedQuantity ?? 0,
          "grnPrice": item.newPrice ?? 0.0,
          "damagedQuantity": 0.0,
          "befTaxDiscount": item.befTaxDiscount ?? 0.0,
          "afTaxDiscount": item.afTaxDiscount ?? 0.0,
          "expiryDate": formattedExpiryDate,
        };
      }).toList();

      /// BUILD BODY
      final Map<String, dynamic> body = {
        "items": itemsList,
        "invoiceNo": invoiceNumber,
        "invoiceDate": formattedInvoiceDate,
        "discountPrice": 0,
        "grnRoundOffAmount": roundOffAdjustment ?? 0.0,
        "poId": poId,
        "freights": po.freights?.map((f) => f.toJson()).toList() ?? [],
        "totalFreightAmount": po.totalFreightAmount ?? 0.0,
        "totalFreightTaxAmount": po.totalFreightTaxAmount ?? 0.0,
      };

      debugPrint("=========== UPDATE PO API PAYLOAD ===========");
      debugPrint(body.toString());

      /// API CALL
      debugPrint("🌐 Calling API: PATCH /purchaseorders/receivedupdates/$poId");
      final response = await _dio.patch(
        '/purchaseorders/receivedupdates/$poId',
        data: body,
      );

      debugPrint("📡 Status Code: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ API FAILED: ${response.data}");
        throw Exception(response.data?["detail"] ?? "PO update failed");
      }

      debugPrint("=========== UPDATE PO RESPONSE ===========");
      debugPrint(response.data.toString());

      /// CHECK GRN
      debugPrint("🔎 GRN Created: ${response.data["grnCreated"]}");
      debugPrint("🆔 GRN ID: ${response.data["grnId"]}");

      /// STOCK CHECK
      if (response.data["stockUpdate"] != null) {
        debugPrint("📦 Stock Update: ${response.data["stockUpdate"]}");
      }

      debugPrint("✅ updatePoDetails SUCCESS");

      return response.data;
    } catch (e, stack) {
      debugPrint("❌ updatePoDetails FAILED: $e");
      debugPrintStack(stackTrace: stack);
      throw Exception("updatePoDetails failed: $e");
    }
  }

  Future<void> postPO(PO po, VendorAll selectedVendorDetails) async {
    _setLoadingState(true);
    _error = null;

    try {
      final String now = ServerTimeService.now.toIso8601String();
      final formattedOrderedDate = _formatDateForBackend(po.orderedDate ?? "");
      final formattedExpectedDate = _formatDateForBackend(
        po.expectedDeliveryDate ?? "",
      );

      final updatedItems = _buildPostItems(po.items);

      final double totalFreightAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.amount ?? 0),
      );
      final double totalFreightTaxAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.taxAmount ?? 0),
      );

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
      final double finalAmount =
          totalPendingAmount +
          totalFreightAmount +
          totalFreightTaxAmount +
          roundOffValue;

      final bool isHoldOrder =
          finalAmount > (selectedVendorDetails.creditLimit ?? 0);

      final updatedPO = po.copyWith(
        orderDate: now,
        createdDate: now,
        lastUpdatedDate: now,
        approvedDate: null,
        rejectedDate: null,
        invoiceDate: null,
        orderedDate: formattedOrderedDate,
        expectedDeliveryDate: formattedExpectedDate,
        totalOrderAmount: finalAmount,
        pendingOrderAmount: finalAmount,
        pendingDiscountAmount: totalPendingDiscount,
        pendingTaxAmount: totalPendingTax,
        roundOffAdjustment: roundOffValue,
        poStatus: isHoldOrder ? 'CreditLimit for Approve' : 'Pending',
      );

      final Map<String, dynamic> poJson = updatedPO.toJson()
        ..['freights'] = po.freights?.map((f) => f.toJson()).toList() ?? []
        ..['items'] = updatedItems
        ..['totalFreightAmount'] = totalFreightAmount
        ..['totalFreightTaxAmount'] = totalFreightTaxAmount
        ..removeWhere(
          (key, value) =>
              (key == "approvedDate" ||
                  key == "rejectedDate" ||
                  key == "invoiceDate") &&
              (value == "" || value == null),
        );

      final response = await _dio.post('/purchaseorders/', data: poJson);

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
      } else {
        throw Exception("Failed to post PO");
      }
    } catch (e) {
      _setError(_handleError(e));
    } finally {
      _setLoadingState(false);
    }
  }

  // ==================== CALCULATION METHODS ====================
  Future<Map<String, dynamic>> calculateGrnOverallDiscount({
    required List<Map<String, dynamic>> items,
    required double discountAmount,
    required String discountType,
  }) async {
    final response = await _dio.post(
      '/purchaseorders/items/grn/calculate-overall-discount',
      data: {
        "applyOverallDiscount": true,
        "overallDiscountAmount": discountAmount,
        "discount_type": discountType,
        "items": items,
      },
    );
    return response.data;
  }

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
      if (pendingTotalQuantity <= 0 || newPrice <= 0) {
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

      final queryParameters = {
        'pendingTotalQuantity': pendingTotalQuantity,
        'poQuantity': poQuantity,
        'newPrice': newPrice,
        'taxPercentage': taxPercentage,
        'taxType': taxType,
      };

      if (befTaxDiscountType == 'amount') {
        queryParameters['befTaxDiscountAmount'] = befTaxDiscountAmount ?? 0.0;
        queryParameters['befTaxDiscount'] = 0.0;
      } else {
        queryParameters['befTaxDiscount'] = befTaxDiscount ?? 0.0;
        queryParameters['befTaxDiscountAmount'] = 0.0;
      }

      if (afTaxDiscountType == 'amount') {
        queryParameters['afTaxDiscountAmount'] = afTaxDiscountAmount ?? 0.0;
        queryParameters['afTaxDiscount'] = 0.0;
      } else {
        queryParameters['afTaxDiscount'] = afTaxDiscount ?? 0.0;
        queryParameters['afTaxDiscountAmount'] = 0.0;
      }

      queryParameters['befTaxDiscountType'] = befTaxDiscountType;
      queryParameters['afTaxDiscountType'] = afTaxDiscountType;

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
      rethrow;
    }
  }

  Future<Map<String, dynamic>> calculateOverallDiscountAPI({
    required List<Map<String, dynamic>> items,
    required bool applyOverallDiscount,
    required String overallDiscountType,
    required double overallDiscount,
    required double overallDiscountAmount,
  }) async {
    final payload = {
      "applyOverallDiscount": applyOverallDiscount,
      "overallDiscountType": overallDiscountType,
      "overallDiscount": overallDiscount,
      "overallDiscountAmount": overallDiscountAmount,
      "items": items,
      "roundOffAdjustment": 0.0,
      "taxType": "cgst_sgst",
    };

    try {
      final response = await _dio.post(
        '/purchaseorders/items/calculate-overall-discount',
        data: payload,
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("HTTP ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

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
          "befTaxDiscountAmount": item.befTaxDiscountAmount,
          "afTaxDiscountAmount": item.afTaxDiscountAmount,
          "befTaxDiscountType": item.befTaxDiscountType,
          "afTaxDiscountType": item.afTaxDiscountType,
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

  // ==================== SEARCH & FILTER METHODS ====================
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

  void searchPOs(String query) {
    _searchQuery = query;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      applyCurrentFilters();
    });
  }

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

  Future<void> fetchTodayPOs() async {
    final now = ServerTimeService.now;
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
    final now = ServerTimeService.now;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    await fetchPOsWithFilters(
      fromDate: startOfWeek,
      toDate: endOfWeek,
      filterByField: 'orderDate',
      clearExisting: true,
    );
  }

  Future<void> fetchThisMonthPOs() async {
    final now = ServerTimeService.now;
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
    await fetchPendingPOsFromBackend(clearExisting: true);
  }

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

  // ==================== FILTER SETTERS ====================
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

  // ==================== UTILITY METHODS ====================
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

  void cleanupUnusedKeys(List<PO> currentPOs) {
    final currentRandomIds = currentPOs
        .map((po) => po.randomId)
        .whereType<String>()
        .toSet();
  }

  void removeApprovedPO(String poId) {
    _pos.removeWhere((po) => po.purchaseOrderId == poId);
    _poList.removeWhere((po) => po.purchaseOrderId == poId);
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

  void addItem(Item newItem) {
    _items.add(newItem);
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

  // ==================== PRIVATE HELPER METHODS ====================
  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Map<String, dynamic> _buildPOQueryParams({
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
  }) {
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

    final dateFormatter = DateFormat('yyyy-MM-dd');

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

    return queryParams;
  }

  List<PO> _parsePOsFromData(List data) {
    return data
        .map((e) {
          final po = PO.fromJson(e);
          po.items.removeWhere((item) => (item.pendingTotalQuantity ?? 0) <= 0);
          return po;
        })
        .whereType<PO>()
        .toList();
  }

  void _updatePOList(
    List<PO> fetchedPOs,
    bool clearExisting,
    bool append,
    int skip,
    int limit,
  ) {
    if (clearExisting && !append) {
      _pos = List.from(fetchedPOs);
      _poList
        ..clear()
        ..addAll(_pos);
    } else if (append) {
      final existingIds = _pos.map((p) => p.purchaseOrderId).toSet();
      final newPOs = fetchedPOs.where(
        (po) => !existingIds.contains(po.purchaseOrderId),
      );
      _pos.addAll(newPOs);
      _poList.addAll(newPOs);
    } else {
      _pos = List.from(fetchedPOs);
      _poList
        ..clear()
        ..addAll(_pos);
    }

    _hasMore = fetchedPOs.length >= limit;
    _skip = skip + fetchedPOs.length;
  }

  List<Map<String, dynamic>> _buildUpdatedItems(List<Item> items) {
    return items.map((item) {
      final double qty = item.quantity ?? 0.0;
      final double price = item.newPrice ?? item.existingPrice ?? 0.0;
      final double safeCount =
          (item.pendingCount == null || item.pendingCount == 0)
          ? (item.count == null || item.count == 0 ? 1.0 : item.count!)
          : item.pendingCount!;
      final double safeQty =
          item.pendingQuantity ?? item.eachQuantity ?? item.quantity ?? 0.0;
      final double safeTotal = safeCount * safeQty;
      final double pendingFinal =
          item.pendingFinalPrice ?? item.finalPrice ?? 0.0;
      final double pendingTotal =
          item.pendingTotalPrice ?? item.totalPrice ?? 0.0;
      final double pendingDiscount = item.pendingDiscountAmount ?? 0.0;
      final double pendingTax = item.pendingTaxAmount ?? 0.0;

      double sgst = 0, cgst = 0, igst = 0;
      if ((item.taxType ?? 'cgst_sgst') == 'igst') {
        igst = pendingTax;
      } else {
        cgst = pendingTax / 2;
        sgst = pendingTax / 2;
      }

      return {
        "itemId": item.itemId ?? "",
        "itemName": item.itemName ?? "",
        "quantity": qty,
        "poQuantity": item.poQuantity ?? qty,
        "uom": item.uom ?? "",
        "count": safeCount,
        "pendingCount": safeCount,
        "eachQuantity": safeQty,
        "pendingQuantity": safeQty,
        "pendingTotalQuantity": safeTotal,
        "existingPrice": item.existingPrice ?? 0.0,
        "newPrice": price,
        "taxPercentage": item.taxPercentage ?? 0.0,
        "taxType": item.taxType ?? "cgst_sgst",
        "befTaxDiscount": item.befTaxDiscount ?? 0.0,
        "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,
        "befTaxDiscountType": item.befTaxDiscountType ?? "percentage",
        "afTaxDiscount": item.afTaxDiscount ?? 0.0,
        "afTaxDiscountAmount": item.afTaxDiscountAmount ?? 0.0,
        "afTaxDiscountType": item.afTaxDiscountType ?? "percentage",
        "pendingTaxAmount": pendingTax,
        "pendingDiscountAmount": pendingDiscount,
        "pendingTotalPrice": pendingTotal,
        "pendingFinalPrice": pendingFinal,
        "poQuantitysgst": cgst,
        "poQuantitycgst": sgst,
        "poQuantityigst": igst,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildPostItems(List<Item> items) {
    return items.map((item) {
      final double qty = item.quantity ?? 0.0;
      final double price = item.newPrice ?? item.existingPrice ?? 0.0;
      final double pendingFinal =
          item.pendingFinalPrice ?? item.finalPrice ?? 0.0;
      final double pendingTotal =
          item.pendingTotalPrice ?? item.totalPrice ?? 0.0;
      final double pendingDiscount = item.pendingDiscountAmount ?? 0.0;
      final double pendingTax = item.pendingTaxAmount ?? 0.0;

      double sgst = 0, cgst = 0, igst = 0;
      if ((item.taxType ?? 'igst') == 'igst') {
        igst = pendingTax;
      } else {
        cgst = pendingTax / 2;
        sgst = pendingTax / 2;
      }

      return {
        "itemId": item.itemId ?? "",
        "itemName": item.itemName ?? "",
        "quantity": qty,
        "poQuantity": qty,
        "poQuantityTaxAmount": item.poQuantityTaxAmount ?? pendingTax,
        "poQuantityDiscountAmount":
            item.poQuantityDiscountAmount ?? pendingDiscount,
        "poQuantitypendingTotalPrice":
            item.poQuantitypendingTotalPrice ?? pendingTotal,
        "poQuantitypendingFinalPrice":
            item.poQuantitypendingFinalPrice ?? pendingFinal,
        "poQuantitysgst": item.poQuantitysgst ?? sgst,
        "poQuantitycgst": item.poQuantitycgst ?? cgst,
        "poQuantityigst": item.poQuantityigst ?? igst,
        "uom": item.uom ?? "",
        "count": item.count ?? 1.0,
        "eachQuantity": item.eachQuantity ?? 0.0,
        "existingPrice": item.existingPrice ?? 0.0,
        "newPrice": price,
        "taxPercentage": item.taxPercentage ?? 0.0,
        "taxType": item.taxType ?? "cgst_sgst",
        "befTaxDiscount": item.befTaxDiscount ?? 0.0,
        "afTaxDiscount": item.afTaxDiscount ?? 0.0,
        "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,
        "afTaxDiscountAmount": item.afTaxDiscountAmount ?? 0.0,
        "pendingCount": item.pendingCount ?? 1.0,
        "pendingQuantity": item.pendingQuantity ?? qty,
        "pendingTotalQuantity": item.pendingTotalQuantity ?? qty,
        "pendingTaxAmount": pendingTax,
        "pendingDiscountAmount": pendingDiscount,
        "pendingTotalPrice": pendingTotal,
        "pendingFinalPrice": pendingFinal,
      };
    }).toList();
  }

  String _formatDateForBackend(String dateString) {
    if (dateString.isEmpty) return "";
    try {
      final parts = dateString.split('-');
      if (parts.length == 3 &&
          parts[0].length == 2 &&
          parts[1].length == 2 &&
          parts[2].length == 4) {
        return "${parts[2]}-${parts[1]}-${parts[0]}";
      }
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  String _normalizeDate(String date) {
    try {
      if (date.contains('-')) {
        List<String> parts = date.split('-');
        if (parts[0].length == 2 && parts[1].length == 2) {
          return "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      }
      return DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(date).toUtc().toLocal());
    } catch (e) {
      return date;
    }
  }

  String _getReadableError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Request timed out.";
      case DioExceptionType.connectionError:
        return "No internet connection.";
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode >= 500) {
          return "Server error.";
        } else if (statusCode == 404) {
          return "Data not found.";
        } else if (statusCode == 400) {
          return "Invalid request.";
        } else {
          return "Something went wrong.";
        }
      case DioExceptionType.cancel:
        return "Request cancelled.";
      default:
        return "Unexpected error.";
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      return _getReadableError(e);
    }
    return "Something went wrong. Please try again.";
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

  // ==================== DISPOSAL ====================
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
