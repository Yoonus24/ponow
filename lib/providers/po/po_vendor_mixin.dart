import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/models/po/vendorpurchasemodel.dart';
import 'po_state.dart';
import 'po_helper_mixin.dart';

mixin POVendorMixin on POState, POHelperMixin {
  // ==================== INITIALIZATION ====================
  void initVendorScrollListener() {
    vendorScrollController.addListener(() {
      if (!isFetchingInternal &&
          vendorScrollController.position.pixels >=
              vendorScrollController.position.maxScrollExtent - 100) {
        if (hasMoreInternal && !isFetchingInternal) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await fetchingVendors(
              vendorName: searchQueryInternal,
              skip: skipInternal,
              limit: 50,
              append: true,
            );
          });
        }
      }
    });
  }

  void initAllVendorScrollListener() {
    vendorAllScrollController.addListener(() async {
      if (vendorAllScrollController.position.pixels ==
              vendorAllScrollController.position.maxScrollExtent &&
          !isFetchingInternal &&
          hasMoreInternal) {
        skipInternal += 50;
        await fetchingAllVendors(
          vendorName: searchQueryInternal,
          skip: skipInternal,
          limit: 50,
          append: true,
        );
      }
    });
  }

  // ==================== VENDOR METHODS ====================
  Future<void> preloadVendors() async {
    if (isFetchingInternal || vendorsInternal.isNotEmpty) return;

    try {
      isFetchingInternal = true;
      final response = await dio.get(
        '/vendors/limit',
        queryParameters: {'limit': 1000},
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final data = response.data;
        vendorsInternal = (data['vendors'] as List)
            .map<Vendor>((v) => Vendor.fromJson(v))
            .toList();
        filteredVendorNamesInternal = vendorsInternal
            .map((v) => v.vendorName)
            .toList();
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        'Preload vendors error: '
        '${exception.message}',
      );
    } finally {
      isFetchingInternal = false;
      notifyListeners();
    }
  }

  void searchVendorsDebounced(String query) {
    vendorSearchTimerInternal?.cancel();
    vendorSearchTimerInternal = Timer(const Duration(milliseconds: 300), () {
      _actualVendorSearch(query);
    });
  }

  Future<void> _actualVendorSearch(String query) async {
    if (query.isEmpty) {
      notifyListeners();
      return;
    }

    final cachedResults = vendorsInternal
        .where((v) => v.vendorName.toLowerCase().contains(query.toLowerCase()))
        .take(50)
        .toList();

    if (cachedResults.isNotEmpty) {
      filteredVendorNamesInternal = cachedResults
          .map((v) => v.vendorName)
          .toList();
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
    if (isFetchingInternal) return;

    isFetchingInternal = true;
    isVendorLoadingInternal = true;
    notifyListeners();

    try {
      final response = await dio.get(
        '/vendors/exact-names/',
        queryParameters: {
          'vendor_name': vendorName,
          'skip': skip,
          'limit': limit,
        },
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final List<dynamic> data = response.data;

        final newVendorNames = data
            .map<String>((vendor) => vendor['vendorName'] ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        final newVendors = data.map<Vendor>((vendor) {
          return Vendor(
            vendorId: vendor['vendorId'] ?? '',
            vendorName: vendor['vendorName'] ?? '',
            randomId: vendor['randomId'] ?? '',
          );
        }).toList();

        if (append) {
          filteredVendorNamesInternal.addAll(newVendorNames);
          vendorsInternal.addAll(newVendors);
        } else {
          filteredVendorNamesInternal = newVendorNames;
          vendorsInternal = newVendors;
        }

        hasMoreInternal = data.length >= limit;
        skipInternal = skip + data.length;
      } else {
        hasMoreInternal = false;
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        '❌ fetchingVendors error: '
        '${exception.message}',
      );
    } finally {
      isFetchingInternal = false;
      isVendorLoadingInternal = false;
      notifyListeners();
    }
  }

  Future<List<VendorAll>> fetchingAllVendors({
    String vendorName = '',
    int skip = 0,
    int limit = 100,
    bool append = false,
  }) async {
    if (vendorCache.isNotEmpty && vendorName.isEmpty && !append) {
      return vendorCache;
    }

    try {
      isFetchingInternal = true;
      isVendorLoadingInternal = true;
      notifyListeners();

      final response = await dio.get(
        '/vendors/vendor-names/',
        queryParameters: {
          if (vendorName.isNotEmpty) "vendor_name": vendorName,
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
            randomId: vendor['randomId'] ?? '',
          );
        }).toList();

        if (vendorName.isEmpty && !append) {
          vendorCache = fetchedVendors;
          vendorsLoaded = true;
        }

        if (!append) {
          vendorAllListInternal = fetchedVendors;
        } else {
          vendorAllListInternal.addAll(fetchedVendors);
        }

        hasMoreInternal = fetchedVendors.length >= limit;

        notifyListeners();
        return fetchedVendors;
      }

      return [];
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "❌ Error fetching all vendors: "
        "${exception.message}",
      );

      return [];
    } finally {
      isFetchingInternal = false;
      isVendorLoadingInternal = false;
      notifyListeners();
    }
  }

  Future<void> fetchVendors() async {
    setLoadingStateInternal(true);
    setErrorInternal(null);
    try {
      final response = await dio.get('/vendors/');
      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300 &&
          response.data is List) {
        final List<dynamic> data = response.data;
        vendorsInternal = data
            .map<Vendor>((json) => Vendor.fromJson(json))
            .toList();
        filteredVendorNamesInternal = vendorsInternal
            .map((v) => v.vendorName)
            .toList();
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      setErrorInternal(exception.message);
    } finally {
      setLoadingStateInternal(false);
    }
  }
}
