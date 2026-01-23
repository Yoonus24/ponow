// ignore_for_file: avoid_print, unnecessary_getters_setters

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/shippingandbillingaddress.dart';
import 'package:provider/provider.dart';
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

  ValueNotifier<DiscountMode> discountMode = ValueNotifier(DiscountMode.none);
  DiscountMode itemWiseDiscountMode = DiscountMode.percentage;

  final TextEditingController overallDiscountController =
      TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  double _overallDiscountValue = 0.0; // Raw % or ₹ input
  double _overallDiscountAmount = 0.0; // Final ₹ amount
  double pendingDiscountAmount = 0.0;
  double pendingTaxAmount = 0.0;
  double pendingOrderAmount = 0.0;

  bool _disposed = false;
  bool isOverallDisabledFromItem = false;
  bool isOverallDiscountActive = false;
  bool get isNotifierDisposed => _disposed;

  double get overallDiscountValue => _overallDiscountValue;
  set overallDiscountValue(double rawValue) {
    // Check disposed first
    if (_disposed) {
      print('⚠️ overallDiscountValue: Notifier is disposed, skipping');
      return;
    }

    // ✅ Store RAW user input only (5% OR ₹50)
    _overallDiscountValue = rawValue;

    if (_disposed) return;
    overallDiscountController.text = rawValue.toStringAsFixed(2);

    // ✅ DO NOT divide by item count
    // ✅ Just store raw value — calculation happens in calculateTotals()
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

  List<Item> poItems = [];
  List<PurchaseItem> purchaseItems = [];
  List<String> filteredItems = [];

  List<ShippingAddress> shippingAddress = [];
  List<BillingAddress> billingAddress = [];
  List<Vendor> vendors = [];
  List<VendorAll> vendorAllList = [];

  int? editingIndex;

  PO? _editingPO;
  PO? get editingPO => _editingPO;

  void setEditingPO(PO? po, {bool notify = true}) {
    if (_disposed) {
      print('⚠️ setEditingPO called after dispose — ignored');
      return;
    }

    _editingPO = po;

    // 🚫 NEVER notify during dispose / unmount
    if (notify) {
      safeNotify();
    }
  }

  void safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _safeCalculateTotals() {
    if (_disposed) return;
    calculateTotals();
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

  void applyOverallDiscountToAllItemsAfTax(
    double discountValue,
    DiscountMode mode,
  ) {
    if (_disposed) return;

    print('🔧 APPLYING OVERALL DISCOUNT - Mutual Exclusive');
    print('   Discount Value: $discountValue, Mode: $mode');

    discountMode.value = mode;
    _overallDiscountValue = discountValue;
    overallDiscountController.text = discountValue.toStringAsFixed(2);

    if (mode != DiscountMode.none) {
      for (var item in poItems) {
        item.afTaxDiscount = 0.0;
      }
    }

    _safeCalculateTotals();
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
        // ✅ FIXED: Use try-catch instead of checking .disposed
        // TextEditingController doesn't have a public .disposed property
        c.dispose();
      } catch (e) {
        // Ignore if already disposed
        print('⚠️ Controller already disposed or error: $e');
      }
    }

    try {
      // ✅ FIXED: ValueNotifier doesn't have .disposed property
      discountMode.dispose();
    } catch (e) {
      print('⚠️ Error disposing discountMode: $e');
    }

    super.dispose();
    print('✅ PurchaseOrderNotifier.dispose() complete');
  }

  String _getControllerTextSafely(TextEditingController controller) {
    try {
      // ✅ FIXED: Don't check .disposed - use try-catch instead
      return controller.text;
    } catch (e) {
      // Controller might be disposed
      print('⚠️ Controller disposed, returning empty string');
      return '';
    }
  }

  // ✅ ADDED: Helper method to check if controller is disposed
  bool _isControllerDisposed(TextEditingController controller) {
    try {
      // ✅ FIXED: Try to access the text property
      // If it throws, the controller is likely disposed
      final text = controller.text;
      return false;
    } catch (e) {
      print('⚠️ Controller check error (likely disposed): $e');
      return true;
    }
  }

  Future<void> fetchVendors1() async {
    // ❌ DON'T fetch again if already loaded
    if (_vendorsLoaded) {
      print('⚡ fetchVendors1 skipped (already loaded)');
      return;
    }

    await fetchAllVendors1();
  }

  Future<void> fetchAllVendors1() async {
    if (_disposed) return;

    // ✅ Already loaded → instant return
    if (_vendorsLoaded && vendorAllList.isNotEmpty) {
      print('⚡ Vendors already loaded (cache hit)');
      return;
    }

    // ⛔ Prevent duplicate parallel API calls
    if (_vendorsLoading) {
      print('⏳ Vendors already loading, wait...');
      return;
    }

    try {
      _vendorsLoading = true;
      print('🌐 Fetching vendors from API...');

      await poProvider.fetchingVendors();
      await poProvider.fetchingAllVendors();

      vendors = poProvider.vendors;
      vendorAllList = poProvider.vendorAllList;

      _vendorsLoaded = true;

      print('✅ Vendors loaded: ${vendorAllList.length}');
      safeNotify();
    } catch (e) {
      print('❌ Vendor preload failed: $e');
    } finally {
      _vendorsLoading = false;
    }
  }

  Future<void> fetchItems(String query) async {
    if (_disposed) return;

    try {
      await poProvider.searchPurchaseItems(query);
      purchaseItems = poProvider.purchaseItems;
      safeNotify();
    } catch (e) {
      print('❌ Error fetching items in notifier: $e');
    }
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

  // void updateItem({
  //   required double pendingCount,
  //   required double quantity,
  //   required double newPrice,
  //   required double befTaxDiscount,
  //   required double afTaxDiscount,
  //   required double taxPercentage,
  // }) {
  //   if (_disposed) return;
  //   if (editingIndex == null || editingIndex! >= poItems.length) {
  //     print('❌ Invalid editing index: $editingIndex');
  //     return;
  //   }

  //   final item = poItems[editingIndex!];

  //   print("🔧 Updating Item => ${item.itemName}");
  //   print("   Count: $pendingCount  Qty: $quantity  Price: $newPrice");
  //   print("   BefTax: $befTaxDiscount  AfTax: $afTaxDiscount");
  //   print("   Mode: $itemWiseDiscountMode");

  //   String befTaxType = itemWiseDiscountMode == DiscountMode.percentage
  //       ? "percentage"
  //       : "amount";
  //   String afTaxType = itemWiseDiscountMode == DiscountMode.percentage
  //       ? "percentage"
  //       : "amount";

  //   double baseAmount = quantity * newPrice;
  //   double befTaxDiscAmount = 0;

  //   if (befTaxType == "percentage") {
  //     befTaxDiscAmount = baseAmount * (befTaxDiscount / 100);
  //   } else {
  //     befTaxDiscAmount = befTaxDiscount;
  //   }

  //   double priceAfterBefTax = baseAmount - befTaxDiscAmount;
  //   double taxAmount = priceAfterBefTax * (taxPercentage / 100);
  //   double priceAfterTax = priceAfterBefTax + taxAmount;
  //   double afTaxDiscAmount = 0;

  //   if (afTaxType == "percentage") {
  //     afTaxDiscAmount = priceAfterTax * (afTaxDiscount / 100);
  //   } else {
  //     afTaxDiscAmount = afTaxDiscount;
  //   }

  //   double finalPrice = priceAfterTax - afTaxDiscAmount;
  //   if (finalPrice < 0) finalPrice = 0;

  //   item.count = pendingCount;
  //   item.eachQuantity = quantity / pendingCount;
  //   item.quantity = quantity;
  //   item.newPrice = newPrice;
  //   item.befTaxDiscount = befTaxDiscount;
  //   item.afTaxDiscount = afTaxDiscount;
  //   item.befTaxDiscountType = befTaxType;
  //   item.afTaxDiscountType = afTaxType;
  //   item.befTaxDiscountAmount = befTaxDiscAmount;
  //   item.afTaxDiscountAmount = afTaxDiscAmount;
  //   item.taxPercentage = taxPercentage;
  //   item.taxAmount = taxAmount;
  //   item.totalPrice = baseAmount;
  //   item.finalPrice = finalPrice;
  //   item.pendingCount = pendingCount;
  //   item.pendingQuantity = quantity / pendingCount;
  //   item.pendingTotalQuantity = quantity;
  //   item.pendingBefTaxDiscountAmount = befTaxDiscAmount;
  //   item.pendingAfTaxDiscountAmount = afTaxDiscAmount;
  //   item.pendingTaxAmount = taxAmount;
  //   item.pendingFinalPrice = finalPrice;
  //   item.pendingTotalPrice = baseAmount;
  //   item.pendingDiscountAmount = befTaxDiscAmount + afTaxDiscAmount;
  //   if (_taxType == "igst") {
  //     item.pendingIgst = taxAmount;
  //     item.pendingCgst = 0;
  //     item.pendingSgst = 0;
  //   } else {
  //     item.pendingCgst = taxAmount / 2;
  //     item.pendingSgst = taxAmount / 2;
  //     item.pendingIgst = 0;
  //   }

  //   print("✅ Item Updated Successfully!");
  //   print("   Final Price: $finalPrice");

  //   editingIndex = null;

  //   _safeCalculateTotals();
  // }

  void updateItemAtIndex(int index, Item updatedItem) {
    if (_disposed || index >= poItems.length) return;
    poItems[index] = updatedItem;
    safeNotify();
  }

  void updateAfTaxForAllItems(double discountValue, DiscountMode mode) {
    if (_disposed) return;

    for (var item in poItems) {
      // ✅ Store ONLY RAW VALUE
      item.afTaxDiscount = discountValue;

      // ✅ Store correct type
      item.afTaxDiscountType = mode == DiscountMode.percentage
          ? "percentage"
          : "amount";
    }

    _safeCalculateTotals();
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
    if (_disposed) return;

    poItems.remove(item);
    _safeCalculateTotals();
  }

  void setSelectedPaymentTerm(String? term) {
    if (_disposed) return;

    selectedPaymentTerm = term;
    safeNotify();
  }

  void setSelectedItem(String itemName) {
    if (_disposed) return;

    final item = purchaseItems.firstWhere(
      (item) => item.itemName == itemName,
      orElse: () => PurchaseItem(
        itemName: '',
        purchasePrice: 0,
        purchasetaxName: 0,
        uom: '',
        purchaseItemId: '',
        purchasecategoryName: '',
        purchasesubcategoryName: '',
        hsnCode: '',
      ),
    );

    _selectedItem = item;
    itemController.text = item.itemName;
    uomController.text = item.uom.toString();
    existingPriceController.text = item.purchasePrice.toStringAsFixed(2);
    newPriceController.text = item.purchasePrice.toStringAsFixed(2);
    taxPercentageController.text = item.purchasetaxName.toStringAsFixed(2);
    uomController.text = item.uom;
    befTaxDiscountController.text = '0';
    afTaxDiscountController.text = '0';

    safeNotify();
  }

  void setSelectedVendor(String? vendorName) {
    // Check disposed first
    if (_disposed) {
      print('⚠️ setSelectedVendor: Notifier is disposed, skipping');
      return;
    }

    print('🔄 Setting selected vendor: $vendorName');
    selectedVendor = vendorName;

    if (vendorName != null && vendorName.isNotEmpty) {
      try {
        final vendor = vendorAllList.firstWhere(
          (v) => v.vendorName == vendorName,
        );

        selectedVendorDetails = vendor;

        // Safe setting of controller values
        if (vendorContactController.hasListeners) {
          vendorContactController.text = vendor.contactpersonPhone;
        }
        if (paymentTermsController.hasListeners) {
          paymentTermsController.text = vendor.paymentTerms;
        }
        if (creditLimitController.hasListeners) {
          creditLimitController.text = vendor.creditLimit.toString();
        }
        if (addressController.hasListeners) {
          addressController.text = vendor.address;
        }
        if (cityController.hasListeners) {
          cityController.text = vendor.city;
        }
        if (stateController.hasListeners) {
          stateController.text = vendor.state;
        }
        if (countryController.hasListeners) {
          countryController.text = vendor.country;
        }
        if (postalCodeController.hasListeners) {
          postalCodeController.text = vendor.postalCode.toString();
        }
        if (gstNumberController.hasListeners) {
          gstNumberController.text = vendor.gstNumber;
        }

        print('✅ Vendor details updated in notifier:');
        print('   Contact: ${vendor.contactpersonPhone}');
        print('   Payment Terms: ${vendor.paymentTerms}');
        print('   Credit Limit: ${vendor.creditLimit}');
      } catch (e) {
        print('❌ Vendor not found in list: $vendorName');
        selectedVendorDetails = null;
      }
    } else {
      print('🔄 Clearing vendor selection');
      selectedVendorDetails = null;
      clearSelectedVendor();
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

  void updateItemDetails(String? itemName) {
    if (_disposed) return;

    if (itemName != null) {
      final item = purchaseItems.firstWhere(
        (item) => item.itemName == itemName,
        orElse: () => PurchaseItem(
          itemName: '',
          purchasePrice: 0.0,
          purchasetaxName: 0.0,
          purchaseItemId: '',
          uom: '',
          purchasecategoryName: '',
          purchasesubcategoryName: '',
          hsnCode: '',
        ),
      );

      existingPriceController.text = item.purchasePrice.toStringAsFixed(2);
      newPriceController.text = item.purchasePrice.toStringAsFixed(2);
      taxPercentageController.text = item.purchasetaxName.toStringAsFixed(2);
      uomController.text = item.uom;
      safeNotify();
    }
  }

  void calculateTotals() {
    // Check disposed first
    if (_disposed) {
      print('⚠️ calculateTotals: Notifier is disposed, skipping');
      return;
    }

    try {
      print('🧮 calculateTotals() called');

      double subTotal = 0.0;
      double totalBefTaxDiscount = 0.0;
      double totalAfTaxDiscount = 0.0;
      double totalTax = 0.0;
      double totalFinal = 0.0;

      // Safe iteration with null check
      for (final item in poItems) {
        if (item == null) {
          print('⚠️ Null item found in poItems, skipping');
          continue;
        }

        print('   Item: ${item.itemName}');
        print('     totalPrice: ${item.totalPrice}');
        print('     finalPrice: ${item.finalPrice}');
        print('     afTaxDiscount: ${item.afTaxDiscount}%');
        print('     afTaxDiscountAmount: ₹${item.afTaxDiscountAmount}');

        subTotal += item.totalPrice ?? 0.0;
        totalBefTaxDiscount += item.befTaxDiscountAmount ?? 0.0;
        totalAfTaxDiscount += item.afTaxDiscountAmount ?? 0.0;
        totalTax += item.taxAmount ?? 0.0;
        totalFinal += item.finalPrice ?? 0.0;
      }

      // ✅ Assign totals
      _subTotal = subTotal;
      _itemWiseDiscount = totalBefTaxDiscount;
      _overallDiscountAmount = totalAfTaxDiscount;
      pendingTaxAmount = totalTax;
      _calculatedFinalAmount = totalFinal;
      totalOrderAmount = totalFinal;

      print('📊 Totals calculated:');
      print('   _subTotal: $_subTotal');
      print('   _calculatedFinalAmount: $_calculatedFinalAmount');
      print('   totalOrderAmount: $totalOrderAmount');
      print(
        '   _overallDiscountAmount: $_overallDiscountAmount (Total afTaxDiscountAmount)',
      );

      // Use safe notify
      safeNotify();
    } catch (e, stackTrace) {
      print('❌ Error in calculateTotals: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void resetControllers() {
    print('[🔄 Reset Controllers] Resetting all controllers...');

    // ✅ FIX: Don't use clear() - it calls controller.value= which can throw if disposed
    // Instead, create NEW controllers

    // List of all controllers to reset
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

    // ✅ FIX: Don't clear - check if disposed first
    for (final controller in controllers) {
      _safeResetController(controller);
    }

    // Keep count as '1'
    countController.text = '1';

    // Clear other data
    selectedVendor = null;
    selectedVendorDetails = null;
    selectedPaymentTerm = null;
    selectedShippingaddress = null;
    selectedBillingaddress = null;
    poItems.clear();
    purchaseItems.clear();
    filteredItems.clear();
    editingIndex = null;
    _editItem = null;
    _editingPO = null;

    // Reset totals
    subTotal = 0.0;
    itemWiseDiscount = 0.0;
    overallDiscountAmount = 0.0;
    calculatedFinalAmount = 0.0;
    totalOrderAmount = 0.0;
    discount = 0;
    roundedAmount = 0;
    finalAmount = 0;
    _overallDiscountValue = 0.0;

    print('[✅ Reset Controllers] All controllers reset successfully');
    notifyListeners();
  }

  // ✅ ADD THIS HELPER METHOD
  void _safeResetController(TextEditingController controller) {
    try {
      // Check if controller is still valid by trying to access its text
      final currentText = controller.text;
      // If we get here, controller is not disposed
      controller.clear();
    } catch (e) {
      // Controller is disposed, create a new one
      print('⚠️ Controller disposed, skipping clear: $e');
    }
  }

  void addItem(Item item) {
    if (_disposed) return;
    poItems.add(item);
    safeNotify();
  }

  // void addItem() {
  //   if (_disposed) return;

  //   if (_selectedItem != null) {
  //     final existingPrice =
  //         double.tryParse(existingPriceController.text) ?? 0.0;
  //     final befTaxDiscount =
  //         double.tryParse(befTaxDiscountController.text) ?? 0.0;
  //     final afTaxDiscount =
  //         double.tryParse(afTaxDiscountController.text) ?? 0.0;
  //     final newPrice = double.tryParse(newPriceController.text) ?? 0.0;
  //     final count = double.tryParse(countController.text) ?? 0.0;
  //     final eachQuantity = double.tryParse(eachQuantityController.text) ?? 0.0;
  //     final taxPercentage =
  //         double.tryParse(taxPercentageController.text) ?? 0.0;

  //     final quantity = count * eachQuantity;

  //     String befTaxDiscountType =
  //         itemWiseDiscountMode == DiscountMode.percentage
  //         ? 'percentage'
  //         : 'amount';
  //     String afTaxDiscountType = itemWiseDiscountMode == DiscountMode.percentage
  //         ? 'percentage'
  //         : 'amount';

  //     print(
  //       '🎯 Adding item with discount types - BefTax: $befTaxDiscountType, AfTax: $afTaxDiscountType',
  //     );

  //     double totalPriceBeforeDiscount = quantity * newPrice;
  //     double befTaxDiscountAmount = 0.0;
  //     double afTaxDiscountAmount = 0.0;

  //     if (befTaxDiscountType == 'percentage') {
  //       befTaxDiscountAmount =
  //           (totalPriceBeforeDiscount * befTaxDiscount) / 100;
  //     } else {
  //       befTaxDiscountAmount = befTaxDiscount;
  //     }

  //     double priceAfterBefTaxDiscount =
  //         totalPriceBeforeDiscount - befTaxDiscountAmount;
  //     double taxAmount = priceAfterBefTaxDiscount * (taxPercentage / 100);
  //     double priceAfterTax = priceAfterBefTaxDiscount + taxAmount;

  //     if (afTaxDiscountType == 'percentage') {
  //       afTaxDiscountAmount = (priceAfterTax * afTaxDiscount) / 100;
  //     } else {
  //       afTaxDiscountAmount = afTaxDiscount;
  //     }

  //     double finalPrice = priceAfterTax - afTaxDiscountAmount;

  //     if (finalPrice < 0) finalPrice = 0;

  //     final variance = newPrice - existingPrice;

  //     final poItem = Item(
  //       itemId: _selectedItem!.purchaseItemId,
  //       itemName: _selectedItem!.itemName,
  //       quantity: quantity,
  //       existingPrice: existingPrice,
  //       newPrice: newPrice,
  //       count: count,
  //       eachQuantity: eachQuantity,
  //       taxPercentage: taxPercentage,
  //       taxAmount: taxAmount,
  //       befTaxDiscount: befTaxDiscount,
  //       afTaxDiscount: afTaxDiscount,
  //       befTaxDiscountAmount: befTaxDiscountAmount,
  //       afTaxDiscountAmount: afTaxDiscountAmount,
  //       befTaxDiscountType: befTaxDiscountType,
  //       afTaxDiscountType: afTaxDiscountType,
  //       totalPrice: totalPriceBeforeDiscount,
  //       finalPrice: finalPrice,
  //       variance: variance,
  //       uom: _selectedItem!.uom,
  //       taxType: _taxType,
  //       pendingCount: count,
  //       pendingQuantity: eachQuantity,
  //       pendingTotalQuantity: quantity,
  //       pendingBefTaxDiscountAmount: befTaxDiscountAmount,
  //       pendingAfTaxDiscountAmount: afTaxDiscountAmount,
  //       pendingTaxAmount: taxAmount,
  //       pendingFinalPrice: finalPrice,
  //       pendingTotalPrice: totalPriceBeforeDiscount,
  //       pendingDiscountAmount: befTaxDiscountAmount + afTaxDiscountAmount,
  //       pendingCgst: _taxType == 'igst' ? 0 : taxAmount / 2,
  //       pendingSgst: _taxType == 'igst' ? 0 : taxAmount / 2,
  //       pendingIgst: _taxType == 'igst' ? taxAmount : 0,
  //       hsnCode: _selectedItem!.hsnCode,
  //       purchasecategoryName: _selectedItem!.purchasecategoryName,
  //       purchasesubcategoryName: _selectedItem!.purchasesubcategoryName,
  //       expiryDate: '',
  //     );

  //     final existingItemIndex = poItems.indexWhere(
  //       (item) =>
  //           item.itemName?.toLowerCase() ==
  //           _selectedItem!.itemName.toLowerCase(),
  //     );

  //     if (existingItemIndex != -1) {
  //       poItems[existingItemIndex] = poItem;
  //     } else {
  //       poItems.add(poItem);
  //     }

  //     print('✅ Item added successfully:');
  //     print('   BefTax Discount: $befTaxDiscount ($befTaxDiscountType)');
  //     print('   AfTax Discount: $afTaxDiscount ($afTaxDiscountType)');

  //     _safeCalculateTotals();
  //     resetItemFields();
  //     clearSelectedItem();
  //   }
  // }

  void resetItemFields() {
    if (_disposed) return;

    // DON'T use clear() - use value = empty
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

    // Keep count as '1'
    countController.value = TextEditingValue(text: '1');

    safeNotify();
  }

  Future<void> selectDate(BuildContext context) async {
    if (_disposed) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      initialDate: DateTime.now(),
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
      // 🔐 SNAPSHOT ALL CONTROLLER VALUES FIRST (CRITICAL)
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

      final vendorDetails = selectedVendorDetails;
      if (vendorDetails == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a vendor')),
          );
        }
        return false;
      }

      // 🔥 ALWAYS recalc before submit
      calculateTotals();

      final poProvider = Provider.of<POProvider>(context, listen: false);

      // ---------------------------
      // Date formatter
      // ---------------------------
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

      // ---------------------------
      // Deep copy items (SAFE)
      // ---------------------------
      final List<Item> finalItems = poItems.map((e) => e.copyWith()).toList();

      double roundOffValue = double.tryParse(snapshot["roundOff"] ?? '') ?? 0.0;

      final bool hasOverallDiscount = discountMode.value != DiscountMode.none;

      final double overallDiscountValue = hasOverallDiscount
          ? double.tryParse(snapshot["overallDiscount"] ?? '') ?? 0.0
          : 0.0;

      // ---------------------------
      // ✏️ UPDATE PO
      // ---------------------------
      if (editingPO != null) {
        final updatedPO = editingPO!.copyWith(
          vendorName: selectedVendor,
          vendorContact: snapshot["vendorContact"],
          orderedDate: formattedOrderDate,
          expectedDeliveryDate: formattedExpectedDate,
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
          poStatus: calculatedFinalAmount > vendorDetails.creditLimit
              ? 'CreditLimit for Approve'
              : 'Pending',
        );

        await poProvider.updatePO(updatedPO);
        print('✅ PO updated successfully');
        return true;
      }

      // ---------------------------
      // ➕ CREATE NEW PO
      // ---------------------------
      final newPO = PO(
        purchaseOrderId: '',
        randomId: '',
        vendorName: selectedVendor ?? '',
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

  // Add this method at the beginning of the class

  void calculateItemTotals() {
    if (_disposed) return;
    safeNotify();
  }

  Future<void> applyOverallDiscount(POProvider poProvider) async {}
}
