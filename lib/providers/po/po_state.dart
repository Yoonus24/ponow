import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po/BranchLocation.dart';
import 'package:purchaseorders2/models/po/freight_name_model.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/models/po/po_item.dart';
import 'package:purchaseorders2/models/po/purchase_tax_model.dart';
import 'package:purchaseorders2/models/po/shippingandbillingaddress.dart';
import 'package:purchaseorders2/models/po/vendorpurchasemodel.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/services/dio_client.dart';

abstract class POState extends ChangeNotifier {
  // ==================== CONFIGURATION ====================
  final Dio dio = DioClient.dio;
  AIInvoiceResponse? pendingAIResponse;
  String? lastScannedImagePath;
 
  // ==================== STATE VARIABLES ====================
  // PO Lists
  List<PO> posInternal = [];
  List<PO> pendingPOsInternal = [];
  List<PO> get pos => posInternal;
  List<PO> get pendingPOs => pendingPOsInternal;
  List<PO> get poList => poListInternal;
  final List<PO> poListInternal = [];
  PO? selectedPOInternal;
  PO? get selectedPO => selectedPOInternal;

  // Vendors
  List<Vendor> vendorsInternal = [];
  List<VendorAll> vendorAllListInternal = [];
  List<VendorAll> vendorCache = [];
  List<String> filteredVendorNamesInternal = [];
  bool vendorsLoaded = false;
  List<Vendor> get vendors => vendorsInternal;
  List<VendorAll> get vendorAllList => vendorAllListInternal;
  List<String> get filteredVendorNames => filteredVendorNamesInternal;

  // Purchase Items
  List<PurchaseItem> purchaseItemsInternal = [];
  List<String> filteredPurchaseItemsInternal = [];
  List<PurchaseItem> get purchaseItems => purchaseItemsInternal;
  List<String> get filteredPurchaseItems => filteredPurchaseItemsInternal;
  final bool isPreloadingItemsInternal = false;
  bool itemsLoaded = false;

  // Addresses
  List<ShippingAddress> shippingAddressesInternal = [];
  List<BillingAddress> billingAddressInternal = [];
  List<ShippingAddress> get shippingAddress => shippingAddressesInternal;
  List<BillingAddress> get billingAddress => billingAddressInternal;

  // Branches
  List<BranchLocation> branchesInternal = [];
  List<BranchLocation> get branches => branchesInternal;
  bool isBranchLoadingInternal = false;
  bool get isBranchLoading => isBranchLoadingInternal;

  // Taxes & Freights
  List<PurchaseTax> purchaseTaxes = [];
  List<FreightName> freightNames = [];
  Map<String, dynamic>? taxDataInternal;
  Map<String, dynamic>? get taxData => taxDataInternal;

  // Items
  final List<Item> itemsInternal = [];
  List<Item> approvedItems = [];
  List<Item> get items => itemsInternal;

  // Search & Suggestions
  List<String> searchSuggestionsInternal = [];
  List<String> get searchSuggestions => searchSuggestionsInternal;

  // Loading States
  bool isLoadingInternal = false;
  bool isFetchingInternal = false;
  bool firstLoadCompleted = false;
  bool isVendorLoadingInternal = false;
  bool get isLoading => isLoadingInternal;
  bool get isFetching => isFetchingInternal;
  bool get isVendorLoading => isVendorLoadingInternal;
  final Map<String, bool> pdfLoadingMapInternal = {};

  // Error State
  String? errorInternal;
  String? get error => errorInternal;

  // Pagination
  int skipInternal = 0;
  bool hasMoreInternal = true;
  int currentSkip = 0;
  int? totalItems;

  // Filter States
  String currentFilterStatusInternal = 'All';
  String? selectedVendorFilterInternal;
  DateTime? selectedDateFilterInternal;
  DateTimeRange? selectedDateRangeFilterInternal;
  String searchQueryInternal = '';
  String? selectedItemNameFilterInternal;
  String? selectedRandomIdFilterInternal;
  String filterByInternal = 'orderDate';
  bool includeInactiveInternal = false;

  // Getters for Filters
  String get currentFilterStatus => currentFilterStatusInternal;
  String? get selectedVendorFilter => selectedVendorFilterInternal;
  DateTime? get selectedDateFilter => selectedDateFilterInternal;
  DateTimeRange? get selectedDateRangeFilter => selectedDateRangeFilterInternal;
  String get searchQuery => searchQueryInternal;
  String? get selectedItemNameFilter => selectedItemNameFilterInternal;
  String? get selectedRandomIdFilter => selectedRandomIdFilterInternal;
  String get filterBy => filterByInternal;
  bool get includeInactive => includeInactiveInternal;
  bool get isFirstLoadCompleted => firstLoadCompleted;

  // Scroll Controllers
  final ScrollController vendorScrollController = ScrollController();
  final ScrollController vendorAllScrollController = ScrollController();
  final ScrollController itemScrollController = ScrollController();
  final ScrollController poScrollController = ScrollController();

  // Timers
  Timer? vendorSearchTimerInternal;
  Timer? searchTimerInternal;
  final bool isRevertingPOInternal = false;
  final bool branchesLoadedInternal = false;
  bool approvedPOLoaded = false;
  final List<String> filteredPurchaseOrderInternal = [];

  @override
  void dispose() {
    searchTimerInternal?.cancel();
    vendorSearchTimerInternal?.cancel();
    vendorScrollController.dispose();
    vendorAllScrollController.dispose();
    itemScrollController.dispose();
    poScrollController.dispose();
    super.dispose();
  }
}