import 'dart:async';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'po_state.dart';

mixin POFilterMixin on POState {
  // ==================== SEARCH & FILTER METHODS ====================
  Future<void> fetchSearchSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      searchSuggestionsInternal = [];
      notifyListeners();
      return;
    }

    try {
      final response = await dio.get(
        '/purchaseorders/search-suggestions',
        queryParameters: {'q': query},
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final data = response.data;
        searchSuggestionsInternal = List<String>.from(
          data['suggestions'] ?? [],
        );
        notifyListeners();
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        'Error fetching suggestions: '
        '${exception.message}',
      );
    }
  }

  void onSuggestionSelected(String selectedSuggestion) {
    searchQueryInternal = selectedSuggestion;
    searchSuggestionsInternal = [];
    notifyListeners();
    applyCurrentFilters();
  }

  void searchPOs(String query) {
    searchQueryInternal = query;
    searchTimerInternal?.cancel();
    searchTimerInternal = Timer(const Duration(milliseconds: 500), () {
      applyCurrentFilters();
    });
  }

  Future<void> applyCurrentFilters() async {
    String? status;
    if (currentFilterStatusInternal != 'All') {
      status = currentFilterStatusInternal;
    }

    DateTime? fromDate;
    DateTime? toDate;

    if (selectedDateRangeFilterInternal != null) {
      fromDate = selectedDateRangeFilterInternal!.start;
      toDate = selectedDateRangeFilterInternal!.end;
    } else if (selectedDateFilterInternal != null) {
      fromDate = selectedDateFilterInternal!;
      toDate = selectedDateFilterInternal!.add(Duration(days: 1));
    }

    await (this as dynamic).fetchPOsWithFilters(
      status: status,
      vendorName: selectedVendorFilterInternal,
      itemName: selectedItemNameFilterInternal,
      randomId: selectedRandomIdFilterInternal,
      fromDate: fromDate,
      toDate: toDate,
      searchQuery: searchQueryInternal,
      filterByField: filterByInternal,
      includeInactive: includeInactiveInternal,
      clearExisting: true,
    );
  }

  Future<void> fetchPOsByVendor(String vendorName) async {
    await (this as dynamic).fetchPOsWithFilters(
      vendorName: vendorName,
      clearExisting: true,
    );
  }

  Future<void> fetchPOsByItem(String itemName) async {
    await (this as dynamic).fetchPOsWithFilters(
      itemName: itemName,
      clearExisting: true,
    );
  }

  Future<void> fetchPOsByRandomId(String randomId) async {
    await (this as dynamic).fetchPOsWithFilters(
      randomId: randomId,
      clearExisting: true,
    );
  }

  Future<void> refreshPOList() async {
    await (this as dynamic).fetchPendingPOsFromBackend(clearExisting: true);
  }

  Future<void> setFilterStatus(String status) async {
    currentFilterStatusInternal = status;
    switch (status) {
      case "Pending":
        await (this as dynamic).fetchPendingPOsOnly();
        break;
      case "Approved":
        await (this as dynamic).fetchApprovedPOsOnly();
        break;
      case "GRNConverted":
        await (this as dynamic).fetchGRNConvertedPOsOnly();
        break;
      case "APInvoiceConverted":
        await (this as dynamic).fetchAPInvoiceConvertedPOsOnly();
        break;
      default:
        await (this as dynamic).fetchAllPOsOnly();
    }
  }

  // ==================== FILTER SETTERS ====================
  void setVendorFilter(String? vendorName) {
    selectedVendorFilterInternal = vendorName;
    notifyListeners();
    applyCurrentFilters();
  }

  void setDateFilter(DateTime? date) {
    selectedDateFilterInternal = date;
    notifyListeners();
    applyCurrentFilters();
  }

  void setDateRangeFilter(DateTimeRange? dateRange) {
    selectedDateRangeFilterInternal = dateRange;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQueryInternal = query;
    notifyListeners();
    applyCurrentFilters();
  }

  void setItemNameFilter(String? itemName) {
    selectedItemNameFilterInternal = itemName;
    notifyListeners();
  }

  void setRandomIdFilter(String? randomId) {
    selectedRandomIdFilterInternal = randomId;
    notifyListeners();
  }

  void setFilterBy(String field) {
    filterByInternal = field;
    notifyListeners();
  }

  void setIncludeInactive(bool value) {
    includeInactiveInternal = value;
    notifyListeners();
  }

  void clearFilters() {
    currentFilterStatusInternal = 'All';
    selectedVendorFilterInternal = null;
    selectedDateFilterInternal = null;
    selectedDateRangeFilterInternal = null;
    searchQueryInternal = '';
    selectedItemNameFilterInternal = null;
    selectedRandomIdFilterInternal = null;
    filterByInternal = 'orderDate';
    includeInactiveInternal = false;
    notifyListeners();
  }
}
