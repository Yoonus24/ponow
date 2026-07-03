import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/models/po/BranchLocation.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/models/po/shippingandbillingaddress.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'po_state.dart';
import 'po_helper_mixin.dart';

mixin POFetchMixin on POState, POHelperMixin {
  // ==================== PO FETCHING METHODS ====================
  Future<void> fetchPendingPOsOnly() async {
    currentFilterStatusInternal = "Pending";
    await fetchPOsWithFilters(clearExisting: true);
  }

  Future<void> fetchApprovedPOsOnly() async {
    currentFilterStatusInternal = "Approved";
    await fetchPOsWithFilters(
      status: "Approved,PartiallyReceived",
      clearExisting: true,
    );
    approvedPOLoaded = true;
  }

  Future<void> fetchGRNConvertedPOsOnly() async {
    currentFilterStatusInternal = "GRNConverted";
    await fetchPOsWithFilters(status: "GRNConverted", clearExisting: true);
  }

  Future<void> fetchAPInvoiceConvertedPOsOnly() async {
    currentFilterStatusInternal = "APInvoiceConverted";
    await fetchPOsWithFilters(
      status: "APInvoiceConverted",
      clearExisting: true,
    );
  }

  Future<void> fetchAllPOsOnly() async {
    currentFilterStatusInternal = "All";
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
      skipInternal = 0;
      hasMoreInternal = true;
    }

    setLoadingStateInternal(true);
    setErrorInternal(null);

    try {
      final queryParams = buildPOQueryParamsInternal(
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

      final response = await dio.get(
        '/purchaseorders',
        queryParameters: queryParams,
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final List data = response.data;
        final List<PO> fetchedPOs = parsePOsFromDataInternal(data);

        updatePOListInternal(fetchedPOs, clearExisting, append, skip, limit);
        notifyListeners();
      } else {
        errorInternal = 'Failed: ${response.statusCode} - ${response.data}';
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      setErrorInternal(exception.message);
    } finally {
      setLoadingStateInternal(false);
    }
  }

  Future<void> fetchPendingPOsFromBackend({
    int skip = 0,
    int limit = 50,
    bool clearExisting = true,
  }) async {
    setLoadingStateInternal(true);
    setErrorInternal(null);

    try {
      final now = ServerTimeService.now;
      final formatter = DateFormat('yyyy-MM-dd');
      final fromDate = formatter.format(
        now.subtract(const Duration(days: 3650)),
      );
      final toDate = formatter.format(now.add(const Duration(days: 1)));

      final response = await dio.get(
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
              debugPrint("❌ PARSE ERROR: $err");
              return null;
            }
          })
          .whereType<PO>()
          .toList();

      totalItems = total;

      if (clearExisting) {
        pendingPOsInternal = List.from(fetchedPOs);
        posInternal = List.from(fetchedPOs);
        poListInternal
          ..clear()
          ..addAll(posInternal);
      } else {
        pendingPOsInternal.addAll(fetchedPOs);
        posInternal.addAll(fetchedPOs);
        poListInternal.addAll(fetchedPOs);
      }

      hasMoreInternal = fetchedPOs.length >= limit;
      skipInternal = skip + fetchedPOs.length;

      notifyListeners();
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("❌ ERROR: ${exception.message}");

      setErrorInternal(exception.message);
    } finally {
      firstLoadCompleted = true;
      setLoadingStateInternal(false);
    }
  }

  Future<void> fetchPOs() async {
    setLoadingStateInternal(true);
    setErrorInternal(null);

    try {
      final response = await dio.get('/purchaseorders/pending/purchase');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is List) {
          final List<PO> fetchedPOs = data
              .map((json) => PO.fromJson(json))
              .toList();
          posInternal = fetchedPOs;
          poListInternal
            ..clear()
            ..addAll(posInternal);
          cleanupUnusedKeys(posInternal);
        } else {
          throw const AppException('Invalid or empty response format');
        }
      } else {
        throw AppException(
          'Failed to load purchase orders: '
          '${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      setErrorInternal(exception.message);
    } finally {
      setLoadingStateInternal(false);
    }
  }

  Future<void> fetchPOsByStatus(String status) async {
    await fetchPOsWithFilters(status: status, clearExisting: true);
  }

  Future<PO?> fetchPOById(String id) async {
    try {
      final response = await dio.get("/purchaseorders/$id");
      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        return PO.fromJson(response.data);
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "ERROR FETCH FULL PO: "
        "${exception.message}",
      );
    }
    return null;
  }

  // ==================== ADDRESS METHODS ====================
  Future<void> fetchShippingaddress() async {
    setLoadingStateInternal(true);
    errorInternal = null;

    try {
      final Dio addressDio = Dio(
        BaseOptions(
          baseUrl: 'https://yenerp.com/purchaseapi',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await addressDio.get('/poshippingaddress/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        shippingAddressesInternal = data
            .map<ShippingAddress>((json) => ShippingAddress.fromJson(json))
            .toList();
      } else {
        errorInternal =
            'Failed to load shipping addresses: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      errorInternal = exception.message;
    } finally {
      setLoadingStateInternal(false);
    }
  }

  Future<void> fetchBillingAddress() async {
    setLoadingStateInternal(true);
    errorInternal = null;

    try {
      final Dio addressDio = Dio(
        BaseOptions(
          baseUrl: 'https://yenerp.com/purchaseapi',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await addressDio.get('/pobusiness/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        billingAddressInternal = data
            .map<BillingAddress>((json) => BillingAddress.fromJson(json))
            .toList();
      } else {
        errorInternal =
            'Failed to load billing addresses: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      errorInternal = exception.message;
    } finally {
      setLoadingStateInternal(false);
    }
  }

  // ==================== BRANCH METHODS ====================
  Future<void> fetchBranches({bool force = false}) async {
    if (isBranchLoadingInternal) return;
    if (branchesInternal.isNotEmpty && !force) return;

    isBranchLoadingInternal = true;
    notifyListeners();

    try {
      final Dio branchDio = Dio(
        BaseOptions(
          baseUrl: 'https://yenerp.com/masteradminapi',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await branchDio.get('/devicecode/service-location/');

      if (response.statusCode == 200 && response.data is List) {
        branchesInternal = (response.data as List)
            .map((e) => BranchLocation.fromJson(e))
            .toList();
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "Branch fetch error: "
        "${exception.message}",
      );
    }

    isBranchLoadingInternal = false;
    notifyListeners();
  }

  Future<void> preloadBranches() async {
    if (branchesInternal.isEmpty) {
      await fetchBranches(force: true);
    }
  }
}
