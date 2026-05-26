import 'dart:async';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po/freight.dart';
import 'package:purchaseorders2/models/po/shippingandbillingaddress.dart';
import '../models/po/po.dart';
import '../models/po/po_item.dart';
import '../models/po/vendorpurchasemodel.dart';
import '../models/po/discount_model.dart';
import '../providers/po/po_provider.dart';

abstract class PurchaseOrderNotifierState extends ChangeNotifier {
  double discount = 0;
  double roundedAmount = 0;
  double finalAmount = 0;
  Item? editItemInternal;
  Item? get editItem => editItemInternal;
  Timer? itemSearchTimer;

  ValueNotifier<DiscountMode> discountMode = ValueNotifier(DiscountMode.none);
  DiscountMode itemWiseDiscountMode = DiscountMode.percentage;

  final TextEditingController overallDiscountController = TextEditingController();
  final TextEditingController roundOffController = TextEditingController();
  
  // Shared Calculation Variables moved here to resolve compilation scope errors
  double subTotalInternal = 0.0;
  double itemWiseDiscountInternal = 0.0;
  double calculatedFinalAmountInternal = 0.0;
  double overallDiscountValueInternal = 0.0;
  double overallDiscountAmountInternal = 0.0;

  double get subTotal => subTotalInternal;
  double get itemWiseDiscount => itemWiseDiscountInternal;
  double get overallDiscountAmount => overallDiscountAmountInternal;
  double get calculatedFinalAmount => calculatedFinalAmountInternal;

  set subTotal(double v) => subTotalInternal = v;
  set itemWiseDiscount(double v) => itemWiseDiscountInternal = v;
  set overallDiscountAmount(double v) => overallDiscountAmountInternal = v;
  set calculatedFinalAmount(double v) => calculatedFinalAmountInternal = v;

  double get totalDiscount {
    return itemWiseDiscount + overallDiscountAmount;
  }

  double pendingDiscountAmount = 0.0;
  double pendingTaxAmount = 0.0;
  double pendingOrderAmount = 0.0;
  String? selectedVendorId;
  bool disposed = false;
  bool isOverallDisabledFromItem = false;
  bool isOverallDiscountActive = false;
  bool get isNotifierDisposed => disposed;

  double get overallDiscountValue => overallDiscountValueInternal;
  set overallDiscountValue(double rawValue) {
    if (disposed) return;

    overallDiscountValueInternal = rawValue;

    if (disposed) return;
    overallDiscountController.text = rawValue.toStringAsFixed(2);

    for (final item in poItems) {
      item.afTaxDiscount = rawValue;
      item.afTaxDiscountType = discountMode.value == DiscountMode.percentage
          ? "percentage"
          : "amount";
    }

    safeCalculateTotals();
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

  String taxTypeInternal = 'cgst_sgst';
  String get taxType => taxTypeInternal;

  void setTaxType(String type) {
    if (disposed) return;
    taxTypeInternal = type;
    safeNotify();
  }

  void updatePOProvider(POProvider provider) {
    poProvider = provider;
  }

  late POProvider poProvider;
  PurchaseItem? get selectedItem => selectedItemInternal;
  PurchaseItem? selectedItemInternal;

  final TextEditingController itemController = TextEditingController();
  final TextEditingController vendorContactController = TextEditingController();
  final TextEditingController uomController = TextEditingController();
  final TextEditingController expectedDeliveryDateController = TextEditingController();
  final TextEditingController orderedDateController = TextEditingController();
  final TextEditingController existingPriceController = TextEditingController();
  final TextEditingController newPriceController = TextEditingController();
  final TextEditingController varianceController = TextEditingController();
  final TextEditingController pendingbefTaxDiscountController = TextEditingController();
  final TextEditingController pendingafTaxDiscountController = TextEditingController();
  final TextEditingController eachQuantityController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController befTaxDiscountController = TextEditingController();
  final TextEditingController afTaxDiscountController = TextEditingController();
  final TextEditingController taxPercentageController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController pendingCountController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController paymentTermsController = TextEditingController();
  final TextEditingController creditLimitController = TextEditingController();
  final TextEditingController shippingController = TextEditingController();
  final TextEditingController billingController = TextEditingController();
  final TextEditingController fileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController gstNumberController = TextEditingController();
  final TextEditingController termsAndConditionsController = TextEditingController();

  String selectedVendor = '';
  VendorAll? selectedVendorDetails;
  late bool isHoldOrder;
  String selectedPaymentTerm = '';
  String selectedShippingaddress = '';
  String selectedBillingaddress = '';
  double totalOrderAmount = 0.0;
  bool vendorsLoaded = false;
  bool vendorsLoading = false;
  String selectedLocation = '';
  String selectedLocationName = '';

  List<Item> poItems = [];
  List<PurchaseItem> purchaseItems = [];
  List<String> filteredItems = [];

  List<ShippingAddress> shippingAddress = [];
  List<BillingAddress> billingAddress = [];
  List<Vendor> vendors = [];
  List<VendorAll> vendorAllList = [];
  bool isLocationFocusedInternal = false;
  List<FreightData> freights = [];

  double totalFreightAmount = 0;
  double totalFreightTaxAmount = 0;
  double roundOffAdjustment = 0.0;

  bool get isLocationFocused => isLocationFocusedInternal;
  PurchaseItem? selectedPurchaseItem;
  bool isEditTotalsInitialized = false;

  int? editingIndex;

  PO? editingPOInternal;
  PO? get editingPO => editingPOInternal;

  void safeNotify();
  void safeCalculateTotals();
  void calculateTotals({bool fromEditLoad = false});
  Future<void> recalculateTotalsFromBackend();
  void recalculateFromLoadedPO({bool notify = false});
  void updateVariance();
}