// ignore_for_file: avoid_print, unnecessary_getters_setters

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/freight.dart';
import 'package:purchaseorders2/models/shippingandbillingaddress.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/po.dart';
import '../models/po_item.dart';
import '../models/vendorpurchasemodel.dart';
import '../models/discount_model.dart';
import '../providers/po_provider.dart';

class PurchaseOrderNotifier extends ChangeNotifier {
  double discount = 0;
  double roundedAmount = 0;
  double finalAmount = 0;
  Item? _editItem;
  Item? get editItem => _editItem;
  Timer? _itemSearchTimer;

  ValueNotifier<DiscountMode> discountMode = ValueNotifier(DiscountMode.none);
  DiscountMode itemWiseDiscountMode = DiscountMode.percentage;

  final TextEditingController overallDiscountController =
      TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  double _overallDiscountValue = 0.0;
  double _overallDiscountAmount = 0.0;
  double pendingDiscountAmount = 0.0;
  double pendingTaxAmount = 0.0;
  double pendingOrderAmount = 0.0;

  bool _disposed = false;
  bool isOverallDisabledFromItem = false;
  bool isOverallDiscountActive = false;
  bool get isNotifierDisposed => _disposed;

  double get overallDiscountValue => _overallDiscountValue;
  set overallDiscountValue(double rawValue) {
    if (_disposed) {
      print('⚠️ overallDiscountValue: Notifier is disposed, skipping');
      return;
    }

    _overallDiscountValue = rawValue;

    if (_disposed) return;
    overallDiscountController.text = rawValue.toStringAsFixed(2);

    for (final item in poItems) {
      if (item == null) continue;
      item.afTaxDiscount = rawValue;
      item.afTaxDiscountType = discountMode.value == DiscountMode.percentage
          ? "percentage"
          : "amount";
    }

    _safeCalculateTotals();
  }

  double get pendingOverallDiscountAmount => overallDiscountAmount;

  double get pendingAfTaxDiscountAmount {
    return poItems.fold(
      0.0,
      (sum, item) => sum + (item.afTaxDiscountAmount ?? 0.0),
    );
  }

  double get pendingBefTaxDiscountAmount {
    return poItems.fold(
      0.0,
      (sum, item) => sum + (item.befTaxDiscountAmount ?? 0.0),
    );
  }

  String _taxType = 'cgst_sgst';
  String get taxType => _taxType;

  void setTaxType(String type) {
    if (_disposed) return;
    _taxType = type;
    safeNotify();
  }

  final POProvider poProvider;

  PurchaseOrderNotifier(this.poProvider) {
    newPriceController.addListener(updateVariance);
    overallDiscountController.text = '0';
    roundOffController.text = '0';
    countController.text = '1';

    isHoldOrder = false;
  }
  PurchaseItem? get selectedItem => _selectedItem;
  PurchaseItem? _selectedItem;

  late TextEditingController itemController = TextEditingController();
  late TextEditingController vendorContactController = TextEditingController();
  late TextEditingController uomController = TextEditingController();
  late TextEditingController expectedDeliveryDateController =
      TextEditingController();
  late TextEditingController orderedDateController = TextEditingController();
  late TextEditingController existingPriceController = TextEditingController();
  late TextEditingController newPriceController = TextEditingController();
  late TextEditingController varianceController = TextEditingController();
  late TextEditingController pendingbefTaxDiscountController =
      TextEditingController();
  late TextEditingController pendingafTaxDiscountController =
      TextEditingController();
  late TextEditingController eachQuantityController = TextEditingController();
  late TextEditingController countController = TextEditingController();
  late TextEditingController quantityController = TextEditingController();
  late TextEditingController befTaxDiscountController = TextEditingController();
  late TextEditingController afTaxDiscountController = TextEditingController();
  late TextEditingController taxPercentageController = TextEditingController();
  late TextEditingController discountPriceController = TextEditingController();
  late TextEditingController pendingCountController = TextEditingController();
  late TextEditingController discountController = TextEditingController();
  late TextEditingController paymentTermsController = TextEditingController();
  late TextEditingController creditLimitController = TextEditingController();
  late TextEditingController shippingController = TextEditingController();
  late TextEditingController billingController = TextEditingController();
  final TextEditingController fileController = TextEditingController();
  late TextEditingController addressController = TextEditingController();
  late TextEditingController cityController = TextEditingController();
  late TextEditingController stateController = TextEditingController();
  late TextEditingController countryController = TextEditingController();
  late TextEditingController postalCodeController = TextEditingController();
  late TextEditingController gstNumberController = TextEditingController();

  String? selectedVendor;
  VendorAll? selectedVendorDetails;
  late bool isHoldOrder;
  String? selectedPaymentTerm;
  String? selectedShippingaddress;
  String? selectedBillingaddress;
  double totalOrderAmount = 0.0;
  bool _vendorsLoaded = false;
  bool _vendorsLoading = false;
  String? selectedLocation;
  String? selectedLocationName;

  List<Item> poItems = [];
  List<PurchaseItem> purchaseItems = [];
  List<String> filteredItems = [];

  List<ShippingAddress> shippingAddress = [];
  List<BillingAddress> billingAddress = [];
  List<Vendor> vendors = [];
  List<VendorAll> vendorAllList = [];
  bool _isLocationFocused = false;
  List<FreightData> freights = [];

  double totalFreightAmount = 0;
  double totalFreightTaxAmount = 0;
  double roundOffAdjustment = 0.0;

  bool get isLocationFocused => _isLocationFocused;
  PurchaseItem? selectedPurchaseItem;
  bool _isEditTotalsInitialized = false;

  int? editingIndex;

  PO? _editingPO;
  PO? get editingPO => _editingPO;
  void setLocationFocus(bool focused) {
    if (_isLocationFocused != focused) {
      _isLocationFocused = focused;
      notifyListeners();
    }
  }

  void setEditingPO(PO? po, {bool notify = true}) {
    if (_disposed) return;

    _editingPO = po;

    // 🔥 Reset guard for new edit session
    _isEditTotalsInitialized = false;

    if (po != null) {
      poItems = List<Item>.from(po.items);

      freights = List<FreightData>.from(po.freights ?? []);
      totalFreightAmount = po.totalFreightAmount ?? 0.0;
      totalFreightTaxAmount = po.totalFreightTaxAmount ?? 0.0;

      roundOffAdjustment = po.roundOffAdjustment ?? 0.0;
      roundOffController.text = roundOffAdjustment.toStringAsFixed(2);

      // ✅ Initialize totals ONCE
      _initializeEditTotalsOnce(notify: notify);
    }
  }

  void _initializeEditTotalsOnce({required bool notify}) {
    if (_isEditTotalsInitialized) {
      print("⛔ Skipping duplicate edit recalculation");
      return;
    }

    print("✅ Initializing edit totals ONCE");

    recalculateFromLoadedPO(notify: notify);

    _isEditTotalsInitialized = true;
  }

  Future<void> updateFreightAt(int index, FreightData freight) async {
    if (index < 0 || index >= freights.length) return;

    final newList = List<FreightData>.from(freights);
    newList[index] = freight;

    freights = newList;

    await recalculateTotalsFromBackend();
  }

  void removeFreightAt(int index) {
    if (index < 0 || index >= freights.length) return;

    freights.removeAt(index);

    recalculateTotalsFromBackend();
    notifyListeners();
  }

  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _safeCalculateTotals() {
    if (_disposed) return;
    calculateTotals();
  }

  void clearFreights() {
    freights.clear();
    totalFreightAmount = 0.0;
    totalFreightTaxAmount = 0.0;
    notifyListeners();
  }

  void safeControllerAction(void Function() action) {
    if (_disposed) {
      print('⚠️ Notifier disposed, skipping controller action');
      return;
    }

    try {
      action();
    } catch (e) {
      print('⚠️ Error in controller action: $e');
    }
  }

  Future<void> addFreight(FreightData freight) async {
    freights.add(freight);
    await recalculateTotalsFromBackend();
  }

  Future<void> recalculateTotalsFromBackend() async {
    final result = await poProvider.calculatePOTotals(
      items: poItems.map((e) => e.toJson()).toList(),
      freights: freights.map((e) => e.toJson()).toList(),
    );

    subTotal = result["subTotal"];
    totalFreightAmount = result["totalFreightAmount"];
    totalFreightTaxAmount = result["totalFreightTaxAmount"];

    final double roundOff = double.tryParse(roundOffController.text) ?? 0.0;

    _calculatedFinalAmount = result["finalAmount"] + roundOff;

    totalOrderAmount = _calculatedFinalAmount;
    pendingOrderAmount = _calculatedFinalAmount;

    notifyListeners();
  }

  void updateVariance() {
    if (_disposed) return;

    double existingPrice = double.tryParse(existingPriceController.text) ?? 0;
    double newPrice = double.tryParse(newPriceController.text) ?? 0;
    double variance = newPrice - existingPrice;
    varianceController.text = variance.toStringAsFixed(2);
    safeNotify();
  }

  void clearSelectedVendor() {
    safeControllerAction(() {
      selectedVendor = null;
      selectedVendorDetails = null;
      selectedLocation = null;
      selectedLocationName = null;

      vendorContactController.value = TextEditingValue.empty;
      paymentTermsController.value = TextEditingValue.empty;
      creditLimitController.value = TextEditingValue.empty;
      addressController.value = TextEditingValue.empty;
      cityController.value = TextEditingValue.empty;
      stateController.value = TextEditingValue.empty;
      countryController.value = TextEditingValue.empty;
      postalCodeController.value = TextEditingValue.empty;
      gstNumberController.value = TextEditingValue.empty;

      safeNotify();
    });
  }

  Future<void> applyOverallDiscountToAllItemsAfTax(
    double discountValue,
    DiscountMode mode,
  ) async {
    if (_disposed) return;

    isOverallDiscountActive = true;
    discountMode.value = mode;
    _overallDiscountValue = discountValue;
    overallDiscountController.text = discountValue.toStringAsFixed(2);

    await recalculateTotalsFromBackend();
  }

  void setLocation({required String location, String? locationName}) {
    if (_disposed) return;

    selectedLocation = location;
    selectedLocationName = locationName;
    safeNotify();
  }

  void clearLocation() {
    if (_disposed) return;

    selectedLocation = null;
    selectedLocationName = null;
    safeNotify();
  }

  void clearAllItems() {
    if (_disposed) return;

    poItems.clear();
    totalOrderAmount = 0.0;
    safeNotify();
  }

  void setSelectedVendors(String? vendorName) {
    if (_disposed) return;

    selectedVendor = vendorName;
    if (vendorName != null) {
      selectedVendorDetails = vendorAllList.firstWhere(
        (vendor) => vendor.vendorName == vendorName,
        orElse: () => VendorAll(
          vendorName: '',
          contactpersonPhone: '',
          vendorId: '',
          paymentTerms: 'No Payment Term Selected',
          contactpersonEmail: '',
          address: '',
          country: '',
          state: '',
          city: '',
          postalCode: 0,
          gstNumber: '',
          creditLimit: 0,
        ),
      );
    } else {
      selectedVendorDetails = null;
    }
    safeNotify();
  }

  double _subTotal = 0.0;
  double _itemWiseDiscount = 0.0;
  double _calculatedFinalAmount = 0.0;
  double get subTotal => _subTotal;
  double get itemWiseDiscount => _itemWiseDiscount;
  double get overallDiscountAmount => _overallDiscountAmount;
  double get calculatedFinalAmount => _calculatedFinalAmount;

  set subTotal(double v) => _subTotal = v;
  set itemWiseDiscount(double v) => _itemWiseDiscount = v;
  set overallDiscountAmount(double v) => _overallDiscountAmount = v;
  set calculatedFinalAmount(double v) => _calculatedFinalAmount = v;

  double get totalDiscount {
    return itemWiseDiscount + overallDiscountAmount;
  }

  @override
  void dispose() {
    print('🛑 PurchaseOrderNotifier.dispose() called');
    _disposed = true;
    _itemSearchTimer?.cancel();

    final controllers = [
      itemController,
      vendorContactController,
      uomController,
      expectedDeliveryDateController,
      orderedDateController,
      eachQuantityController,
      countController,
      quantityController,
      existingPriceController,
      newPriceController,
      varianceController,
      taxPercentageController,
      discountController,
      paymentTermsController,
      creditLimitController,
      shippingController,
      billingController,
      discountPriceController,
      roundOffController,
      overallDiscountController,
      pendingbefTaxDiscountController,
      pendingafTaxDiscountController,
      pendingCountController,
      fileController,
      addressController,
      cityController,
      stateController,
      countryController,
      postalCodeController,
      gstNumberController,
    ];

    for (final c in controllers) {
      try {
        c.dispose();
      } catch (e) {
        print('⚠️ Controller already disposed or error: $e');
      }
    }

    try {
      discountMode.dispose();
    } catch (e) {
      print('⚠️ Error disposing discountMode: $e');
    }

    super.dispose();
    print('✅ PurchaseOrderNotifier.dispose() complete');
  }

  String _getControllerTextSafely(TextEditingController controller) {
    try {
      return controller.text;
    } catch (e) {
      print('⚠️ Controller disposed, returning empty string');
      return '';
    }
  }

  Future<void> fetchVendors1() async {
    if (_vendorsLoaded) return;

    await poProvider.fetchingVendors();
    vendors = poProvider.vendors;

    _vendorsLoaded = true;
    safeNotify();
  }

  Future<void> fetchAllVendors1() async {
    if (_vendorsLoading) return;

    _vendorsLoading = true;

    await poProvider.fetchingAllVendors();

    vendorAllList = poProvider.vendorAllList;

    _vendorsLoading = false;

    safeNotify();
  }

  Future<void> fetchItems(String query) async {
    if (_disposed) return;

    try {
      await poProvider.searchPurchaseItems(query: query);
      purchaseItems = poProvider.purchaseItems;

      filteredItems = purchaseItems
          .map((item) => item.itemName)
          .where((name) => name.isNotEmpty)
          .take(50)
          .toList();

      safeNotify();
    } catch (e) {
      print('❌ Error fetching items: $e');
    }
  }

  Future<void> preloadItems({bool forceRefresh = false}) async {
    if (_disposed) return;

    if (purchaseItems.isNotEmpty && !forceRefresh) return;

    try {
      await poProvider.searchPurchaseItems(query: '');
      purchaseItems = poProvider.purchaseItems;
      filteredItems = purchaseItems
          .map((item) => item.itemName)
          .where((name) => name.isNotEmpty)
          .toList();

      safeNotify();
    } catch (e) {
      print('❌ Error preloading items: $e');
    }
  }

  Future<void> fetchBranches1() async {
    if (_disposed) return;

    await poProvider.fetchBranches();
    safeNotify();
  }

  Future<void> fetchShippingAddress1() async {
    if (_disposed) return;

    await poProvider.fetchShippingaddress();
    shippingAddress = poProvider.shippingAddress;
    safeNotify();
  }

  Future<void> fetchBillingAddress1() async {
    if (_disposed) return;

    await poProvider.fetchBillingAddress();
    billingAddress = poProvider.billingAddress;
    safeNotify();
  }

  void selectEditItem(Item item) {
    if (_disposed) return;

    _editItem = item;
    safeNotify();
  }

  void clearEditItem() {
    if (_disposed) return;

    _editItem = null;
    safeNotify();
  }

  void setEditItem(Item item) {
    if (_disposed) return;

    _editItem = item;
    safeNotify();
  }

  void updateItemAtIndex(int index, Item updatedItem) {
    if (_disposed || index >= poItems.length) return;
    poItems[index] = updatedItem;
    safeNotify();
  }

  void updateAfTaxForAllItems(double discountValue, DiscountMode mode) {
    if (_disposed) return;

    for (var item in poItems) {
      item.afTaxDiscount = discountValue;

      item.afTaxDiscountType = mode == DiscountMode.percentage
          ? "percentage"
          : "amount";
    }

    _safeCalculateTotals();
  }

  void recalculateFromLoadedPO({required bool notify}) {
    if (_disposed) return;

    print('🔁 Recalculating totals from loaded PO (EDIT MODE)');

    double subTotal = 0.0;
    double totalTax = 0.0;
    double totalFinal = 0.0;

    double totalBefTaxDiscount = 0.0;
    double totalAfTaxDiscount = 0.0;

    for (final item in poItems) {
      subTotal += item.totalPrice ?? 0.0;
      final double tax = item.pendingTaxAmount ?? item.taxAmount ?? 0.0;
      item.pendingTaxAmount = tax;
      if (item.taxType == 'igst') {
        item.pendingIgst = tax;
        item.pendingCgst = 0.0;
        item.pendingSgst = 0.0;
      } else {
        item.pendingCgst = tax / 2;
        item.pendingSgst = tax / 2;
        item.pendingIgst = 0.0;
      }
      totalTax += tax;
      totalFinal += item.pendingFinalPrice ?? item.finalPrice ?? 0.0;
      totalBefTaxDiscount += item.befTaxDiscountAmount ?? 0.0;
      totalAfTaxDiscount += item.afTaxDiscountAmount ?? 0.0;
    }

    if (isOverallDiscountActive) {
      _itemWiseDiscount = totalBefTaxDiscount;
      _overallDiscountAmount = totalAfTaxDiscount;
    } else {
      _itemWiseDiscount = totalBefTaxDiscount + totalAfTaxDiscount;
      _overallDiscountAmount = 0.0;
    }

    _subTotal = subTotal;
    pendingTaxAmount = totalTax;

    final double roundOff = double.tryParse(roundOffController.text) ?? 0.0;

    _calculatedFinalAmount =
        totalFinal + totalFreightAmount + totalFreightTaxAmount + roundOff;

    totalOrderAmount = _calculatedFinalAmount;
    pendingOrderAmount = _calculatedFinalAmount;

    pendingDiscountAmount = _itemWiseDiscount + _overallDiscountAmount;

    if (notify) safeNotify();
  }

  void clearSelectedItem() {
    if (_disposed) return;

    editingIndex = null;
    itemController.clear();
    uomController.clear();
    eachQuantityController.clear();
    quantityController.clear();
    existingPriceController.clear();
    newPriceController.clear();
    varianceController.clear();
    taxPercentageController.clear();
    befTaxDiscountController.clear();
    afTaxDiscountController.clear();
    safeNotify();
  }

  void removeItem(Item item) {
    poItems.remove(item);

    if (poItems.isEmpty) {
      totalFreightAmount = 0;
      totalFreightTaxAmount = 0;
    }

    calculateTotals();
  }

  void setSelectedPaymentTerm(String? term) {
    if (_disposed) return;

    selectedPaymentTerm = term;
    safeNotify();
  }

  void setSelectedItem(String itemName) {
    if (_disposed) return;
    PurchaseItem foundItem = PurchaseItem(
      itemName: itemName,
      purchasePrice: 0,
      purchasetaxName: 0,
      uom: '',
      purchaseItemId: '',
      purchasecategoryName: '',
      purchasesubcategoryName: '',
      hsnCode: '',
    );

    try {
      final existingItem = purchaseItems.firstWhere(
        (item) => item.itemName == itemName,
      );

      foundItem = existingItem;
    } catch (e) {
      purchaseItems.add(foundItem);
    }

    _selectedItem = foundItem;

    safeControllerAction(() {
      itemController.text = itemName;
      uomController.text = foundItem.uom.toString();

      if (foundItem.purchasePrice > 0) {
        existingPriceController.text = foundItem.purchasePrice.toStringAsFixed(
          2,
        );
        newPriceController.text = foundItem.purchasePrice.toStringAsFixed(2);
      }

      if (foundItem.purchasetaxName >= 0) {
        taxPercentageController.text = foundItem.purchasetaxName
            .toStringAsFixed(2);
      }

      befTaxDiscountController.text = '0';
      afTaxDiscountController.text = '0';
    });
    safeNotify();
  }

  void setSelectedVendor(String? vendorName) {
    if (_disposed) {
      print('⚠️ setSelectedVendor: Notifier is disposed, skipping');
      return;
    }

    selectedVendor = vendorName;

    if (vendorName != null && vendorName.isNotEmpty) {
      try {
        final vendor = vendorAllList.firstWhere(
          (v) => v.vendorName == vendorName,
        );

        selectedVendorDetails = vendor;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) {
            vendorContactController.text = vendor.contactpersonPhone;
            paymentTermsController.text = vendor.paymentTerms;
            creditLimitController.text = vendor.creditLimit.toString();
            addressController.text = vendor.address;
            cityController.text = vendor.city;
            stateController.text = vendor.state;
            countryController.text = vendor.country;
            postalCodeController.text = vendor.postalCode.toString();
            gstNumberController.text = vendor.gstNumber;
          }
        });
      } catch (e) {
        selectedVendorDetails = null;
      }
    } else {
      selectedVendorDetails = null;
    }

    safeNotify();
  }

  void setSelectedshippingaddress(String? shippingId) {
    if (_disposed) return;

    selectedShippingaddress = shippingId;
    safeNotify();
  }

  void setSelectedbillingaddress(String? businessId) {
    if (_disposed) return;

    selectedBillingaddress = businessId;
    safeNotify();
  }

  void updateItemDetailsFromCache(PurchaseItem item) {
    if (_disposed) return;

    _selectedItem = item;

    safeControllerAction(() {
      itemController.text = item.itemName;
      existingPriceController.text = item.purchasePrice.toStringAsFixed(2);
      newPriceController.text = item.purchasePrice.toStringAsFixed(2);
      taxPercentageController.text = item.purchasetaxName.toStringAsFixed(2);
      uomController.text = item.uom;

      befTaxDiscountController.text = '0';
      afTaxDiscountController.text = '0';
    });

    updateVariance();

    final index = purchaseItems.indexWhere(
      (e) => e.purchaseItemId == item.purchaseItemId,
    );

    if (index == -1) {
      purchaseItems.add(item);
    }

    safeNotify();
  }

  void calculateTotals({bool fromEditLoad = false}) {
    if (_editingPO != null && !_isEditTotalsInitialized) {
      print("⛔ calculateTotals blocked during edit init");
      return;
    }

    if (_disposed) {
      return;
    }

    double subTotal = 0.0;
    double totalTax = 0.0;
    double totalBefTaxDiscount = 0.0;
    double totalAfTaxDiscount = 0.0;
    double totalFinal = 0.0;

    for (final item in poItems) {
      final double itemTotal = item.totalPrice ?? item.pendingTotalPrice ?? 0.0;
      final double itemFinal = item.finalPrice ?? item.pendingFinalPrice ?? 0.0;

      subTotal += itemTotal;
      totalFinal += itemFinal;

      totalTax += item.taxAmount ?? item.pendingTaxAmount ?? 0.0;
      totalBefTaxDiscount += item.befTaxDiscountAmount ?? 0.0;
      totalAfTaxDiscount += item.afTaxDiscountAmount ?? 0.0;
    }
    if (isOverallDiscountActive) {
      _itemWiseDiscount = totalBefTaxDiscount;
      _overallDiscountAmount = totalAfTaxDiscount;
    } else {
      _itemWiseDiscount = totalBefTaxDiscount + totalAfTaxDiscount;
      _overallDiscountAmount = 0.0;
    }

    _subTotal = subTotal;
    pendingTaxAmount = totalTax;

    final double roundOff = double.tryParse(roundOffController.text) ?? 0.0;

    _calculatedFinalAmount =
        totalFinal + totalFreightAmount + totalFreightTaxAmount + roundOff;
    totalOrderAmount = _calculatedFinalAmount;
    pendingOrderAmount = _calculatedFinalAmount;
    pendingDiscountAmount = _itemWiseDiscount + _overallDiscountAmount;

    print('EDIT SAFE TOTALS');
    print('Subtotal: $_subTotal');
    print('Item Discount: $_itemWiseDiscount');
    print('Overall Discount: $_overallDiscountAmount');
    print('Final: $totalOrderAmount');

    safeNotify();
  }

  void resetControllers() {
    print('[🔄 Reset Controllers]');

    final controllers = [
      vendorContactController,
      paymentTermsController,
      creditLimitController,
      addressController,
      cityController,
      stateController,
      countryController,
      postalCodeController,
      gstNumberController,
      expectedDeliveryDateController,
      orderedDateController,
      billingController,
      shippingController,
      itemController,
      uomController,
      eachQuantityController,
      countController,
      quantityController,
      existingPriceController,
      newPriceController,
      varianceController,
      taxPercentageController,
      discountController,
      discountPriceController,
      roundOffController,
      overallDiscountController,
      pendingbefTaxDiscountController,
      pendingafTaxDiscountController,
      pendingCountController,
      fileController,
    ];

    for (final controller in controllers) {
      try {
        controller.clear();
      } catch (_) {}
    }

    countController.text = '1';

    selectedVendor = null;
    selectedVendorDetails = null;

    selectedLocation = null;
    selectedLocationName = null;

    selectedPaymentTerm = null;
    selectedShippingaddress = null;
    selectedBillingaddress = null;

    poItems.clear();
    purchaseItems.clear();
    filteredItems.clear();
    freights.clear();
    totalFreightAmount = 0;
    totalFreightTaxAmount = 0;

    editingIndex = null;
    _editItem = null;
    _editingPO = null;

    subTotal = 0.0;
    itemWiseDiscount = 0.0;
    overallDiscountAmount = 0.0;
    calculatedFinalAmount = 0.0;
    totalOrderAmount = 0.0;
    _overallDiscountValue = 0.0;

    notifyListeners();
  }

  void addItem(Item item) {
    if (_disposed) return;
    poItems.add(item);
    calculateTotals();
    safeNotify();
  }

  void resetItemFields() {
    if (_disposed) return;

    itemController.value = TextEditingValue.empty;
    uomController.value = TextEditingValue.empty;
    eachQuantityController.value = TextEditingValue.empty;
    quantityController.value = TextEditingValue.empty;
    existingPriceController.value = TextEditingValue.empty;
    newPriceController.value = TextEditingValue.empty;
    varianceController.value = TextEditingValue.empty;
    taxPercentageController.value = TextEditingValue.empty;
    befTaxDiscountController.value = TextEditingValue.empty;
    afTaxDiscountController.value = TextEditingValue.empty;

    countController.value = TextEditingValue(text: '1');

    safeNotify();
  }

  Future<void> selectDate(BuildContext context) async {
    if (_disposed) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ServerTimeService.now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      expectedDeliveryDateController.text = "${picked.toLocal()}".split(' ')[0];
      safeNotify();
    }
  }

  Future<void> selectOrderedDate(BuildContext context) async {
    if (_disposed) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ServerTimeService.now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      orderedDateController.text = "${picked.toLocal()}".split(' ')[0];
      safeNotify();
    }
  }

  Future<bool> submitPurchaseOrder(BuildContext context) async {
    if (_disposed) {
      print('⚠️ submitPurchaseOrder called after dispose');
      return false;
    }

    try {
      if (selectedLocation == null || selectedLocation!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select location')),
          );
        }
        return false;
      }

      final vendorDetails = selectedVendorDetails;
      if (vendorDetails == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a vendor')),
          );
        }
        return false;
      }

      final snapshot = {
        "vendorContact": _getControllerTextSafely(vendorContactController),
        "paymentTerms": _getControllerTextSafely(paymentTermsController),
        "billing": _getControllerTextSafely(billingController),
        "shipping": _getControllerTextSafely(shippingController),
        "orderedDate": _getControllerTextSafely(orderedDateController),
        "expectedDate": _getControllerTextSafely(
          expectedDeliveryDateController,
        ),
        "roundOff": _getControllerTextSafely(roundOffController),
        "overallDiscount": _getControllerTextSafely(overallDiscountController),
      };

      await recalculateTotalsFromBackend();
      await Future.delayed(Duration(milliseconds: 50));

      final poProvider = Provider.of<POProvider>(context, listen: false);

      String formatDate(String? s) {
        if (s == null || s.isEmpty) return '';
        try {
          final parts = s.split('-');
          if (parts.length == 3 && parts[0].length == 2) {
            return '${parts[2]}-${parts[1]}-${parts[0]}';
          }
          return s;
        } catch (_) {
          return s;
        }
      }

      final formattedOrderDate = formatDate(snapshot["orderedDate"]);
      final formattedExpectedDate = formatDate(snapshot["expectedDate"]);

      final List<Item> finalItems = poItems.map((e) => e.copyWith()).toList();

      double roundOffValue = double.tryParse(snapshot["roundOff"] ?? '') ?? 0.0;

      final bool hasOverallDiscount = discountMode.value != DiscountMode.none;
      final double overallDiscountValue = hasOverallDiscount
          ? double.tryParse(snapshot["overallDiscount"] ?? '') ?? 0.0
          : 0.0;

      if (editingPO != null) {
        final updatedPO = editingPO!.copyWith(
          vendorName: selectedVendor,
          vendorContact: snapshot["vendorContact"],
          orderedDate: formattedOrderDate,
          expectedDeliveryDate: formattedExpectedDate,

          location: selectedLocation,
          locationName: selectedLocationName,
          freights: freights,
          totalFreightAmount: totalFreightAmount,
          totalFreightTaxAmount: totalFreightTaxAmount,

          items: finalItems,
          totalOrderAmount: calculatedFinalAmount,
          pendingOrderAmount: calculatedFinalAmount,
          pendingDiscountAmount: overallDiscountAmount + itemWiseDiscount,
          pendingTaxAmount: pendingTaxAmount,

          paymentTerms: snapshot["paymentTerms"],
          billingAddress: snapshot["billing"],
          shippingAddress: snapshot["shipping"],

          contactpersonEmail: vendorDetails.contactpersonEmail,
          address: vendorDetails.address,
          country: vendorDetails.country,
          state: vendorDetails.state,
          city: vendorDetails.city,
          postalCode: vendorDetails.postalCode,
          gstNumber: vendorDetails.gstNumber,
          creditLimit: vendorDetails.creditLimit,

          roundOffAdjustment: roundOffValue,
          overallDiscount: hasOverallDiscount
              ? PurchaseOrderDiscount(
                  value: overallDiscountValue,
                  mode: discountMode.value,
                )
              : null,

          poStatus: editingPO!.poStatus,
        );

        await poProvider.updatePO(updatedPO);
        print('✅ PO updated successfully');
        return true;
      }

      final newPO = PO(
        purchaseOrderId: '',
        randomId: '',
        vendorName: selectedVendor ?? '',

        location: selectedLocation,
        locationName: selectedLocationName,

        vendorContact: snapshot["vendorContact"],
        items: finalItems,
        totalOrderAmount: calculatedFinalAmount,
        pendingOrderAmount: calculatedFinalAmount,
        pendingDiscountAmount: overallDiscountAmount + itemWiseDiscount,
        pendingTaxAmount: pendingTaxAmount,

        paymentTerms: snapshot["paymentTerms"] ?? '',
        billingAddress: snapshot["billing"] ?? '',
        shippingAddress: snapshot["shipping"] ?? '',

        contactpersonEmail: vendorDetails.contactpersonEmail,
        address: vendorDetails.address,
        country: vendorDetails.country,
        state: vendorDetails.state,
        city: vendorDetails.city,
        postalCode: vendorDetails.postalCode,
        gstNumber: vendorDetails.gstNumber,
        creditLimit: vendorDetails.creditLimit,

        orderDate: formattedOrderDate,
        expectedDeliveryDate: formattedExpectedDate,
        roundOffAdjustment: roundOffValue,
        freights: freights,
        totalFreightAmount: totalFreightAmount,
        totalFreightTaxAmount: totalFreightTaxAmount,

        overallDiscount: hasOverallDiscount
            ? PurchaseOrderDiscount(
                value: overallDiscountValue,
                mode: discountMode.value,
              )
            : null,

        poStatus: calculatedFinalAmount > vendorDetails.creditLimit
            ? 'CreditLimit for Approve'
            : 'Pending',
      );

      await poProvider.postPO(newPO, vendorDetails);
      print('✅ New PO created successfully');
      return true;
    } catch (e, stackTrace) {
      print('❌ submitPurchaseOrder error: $e');
      print(stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PO: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // void calculateItemTotals() {
  //   if (_disposed) return;
  //   safeNotify();
  // }

  Future<void> applyOverallDiscount(POProvider poProvider) async {}
}
