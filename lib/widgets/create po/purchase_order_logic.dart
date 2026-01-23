import 'package:flutter/material.dart';
import 'package:purchaseorders2/calculation/purchase_order_calculations.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/models/vendorpurchasemodel.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/discount_model.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:purchaseorders2/models/po_template.dart';

class PurchaseOrderLogic {
  final BuildContext context;
  final PurchaseOrderNotifier notifier;
  final POProvider poProvider;
  final PO? editingPO;
  final TextEditingController vendorController;
  final ValueNotifier<double> totalOrderAmount;
  final ValueNotifier<DiscountMode> overallDiscountMode;
  final ValueNotifier<String> itemWiseDiscountMode;
  final ValueNotifier<bool> refreshUI;
  final GlobalKey<FormState> formKey;
  final bool Function() isDisposed;
  final ValueNotifier<bool> isSaving = ValueNotifier(false);

  final ValueNotifier<int> selectedTaxType = ValueNotifier(1);
  final ValueNotifier<bool> showValidationErrors = ValueNotifier(false);
  final ValueNotifier<String?> roundOffErrorNotifier = ValueNotifier<String?>(
    null,
  );

  // bool _isInitialized = false;

  final TemplateProvider templateProvider;
  bool _addressAutoFilled = false;

  PurchaseOrderLogic({
    required this.context,
    required this.notifier,
    required this.poProvider,
    required this.editingPO,
    required this.vendorController,
    required this.totalOrderAmount,
    required this.overallDiscountMode,
    required this.itemWiseDiscountMode,
    required this.refreshUI,
    required this.formKey,
    required this.isDisposed,
    required this.templateProvider,
  }) {}

  void initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (isDisposed()) return;

      if (editingPO != null) {
        // 🔥 1️⃣ FIRST load vendors synchronously
        await notifier.fetchAllVendors1();
        await notifier.fetchVendors1();

        // 🔥 2️⃣ THEN initialize PO (vendor will match correctly)
        _initializeWithPOData(editingPO!);

        // 🔥 3️⃣ Remaining data can be background
        _fetchSupportingDataInBackground();

        updateTotalOrderAmount();
        triggerUIRefresh();
        return;
      }

      await _initializeForNewPO();
    });
  }

  void applyAddressesIfReady() {
    if (isDisposed()) return;
    if (_addressAutoFilled) return;

    // Billing
    if (notifier.billingAddress.isNotEmpty &&
        notifier.billingController.text.isEmpty) {
      final billing = notifier.billingAddress.first;
      notifier.billingController.text =
          '${billing.address1} ${billing.address2}';
      notifier.setSelectedbillingaddress(billing.businessId);
    }

    // Shipping
    if (notifier.shippingAddress.isNotEmpty &&
        notifier.shippingController.text.isEmpty) {
      final shipping = notifier.shippingAddress.first;
      notifier.shippingController.text = shipping.address;
      notifier.setSelectedshippingaddress(shipping.shippingId);
    }

    _addressAutoFilled = true;
    triggerUIRefresh();

    print('✅ Billing & Shipping auto-filled');
  }

  void cleanup() {
    print('🧹 PurchaseOrderLogic.cleanup() called');

    vendorController.removeListener(_onVendorInputChanged);
    try {
      isSaving.dispose();
      selectedTaxType.dispose();
      showValidationErrors.dispose();
      roundOffErrorNotifier.dispose();
    } catch (e) {
      print('⚠️ Error disposing ValueNotifiers: $e');
    }

    print('✅ PurchaseOrderLogic cleanup complete');
  }

  Future<void> _initializeForNewPO() async {
    await Future.wait([
      notifier.fetchShippingAddress1(),
      notifier.fetchBillingAddress1(),
      notifier.fetchAllVendors1(),
      notifier.fetchVendors1(),
      notifier.fetchItems(''),
    ]);

    // 🔥 THIS IS THE KEY LINE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      applyAddressesIfReady();
    });

    final backendDate = await poProvider.getServerDate();
    notifier.orderedDateController.text = backendDate ?? '';

    notifier.roundOffController.text = '0';
    notifier.totalOrderAmount = 0.0;

    updateTotalOrderAmount();
    triggerUIRefresh();
  }

  void _fetchSupportingDataInBackground() {
    Future.wait([
      notifier.fetchAllVendors1(),
      poProvider.fetchingAllVendors(vendorName: '', skip: 0, limit: 50),
      notifier.fetchVendors1(),
      notifier.fetchItems(''),
      notifier.fetchShippingAddress1(),
      notifier.fetchBillingAddress1(),
    ]).then((_) {
      if (!isDisposed()) {
        triggerUIRefresh();
      }
    });
  }

  void _updateQuantity() {
    if (isDisposed()) {
      print('⚠️ _updateQuantity: Logic is disposed');
      return;
    }

    try {
      if (!notifier.countController.hasListeners ||
          !notifier.eachQuantityController.hasListeners) {
        print('⚠️ _updateQuantity: Controllers have no listeners');
        return;
      }

      final count = double.tryParse(notifier.countController.text) ?? 0.0;
      final eachQuantity =
          double.tryParse(notifier.eachQuantityController.text) ?? 0.0;

      // Check if quantityController is still valid
      if (notifier.quantityController.hasListeners) {
        notifier.quantityController.text = (count * eachQuantity)
            .toStringAsFixed(2);
      }
    } catch (e) {
      print('❌ Error in _updateQuantity: $e');
    }
  }

  void _onVendorInputChanged() {
    if (isDisposed()) return;

    // 🔥 DO NOT CLEAR IN EDIT MODE
    if (editingPO != null) return;

    if (vendorController.text.trim().isEmpty) {
      _clearVendorDetails();
    }
  }

  void _clearVendorDetails() {
    if (isDisposed()) return;

    try {
      notifier.vendorContactController.clear();
      notifier.paymentTermsController.clear();
      notifier.creditLimitController.clear();
      notifier.clearSelectedVendor();
      vendorController.clear();
      triggerUIRefresh();
    } catch (e) {
      print('⚠️ Error in _clearVendorDetails: $e');
    }
  }

  void onVendorSelected(String selectedVendor) {
    notifier.setSelectedVendor(selectedVendor);

    VendorAll? details = notifier.vendorAllList.firstWhere(
      (v) => v.vendorName == selectedVendor,
      orElse: () => VendorAll(
        vendorName: selectedVendor,
        contactpersonPhone: '',
        vendorId: '',
        paymentTerms: '',
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

    notifier.vendorContactController.text = details.contactpersonPhone;
    notifier.paymentTermsController.text = details.paymentTerms;
    notifier.creditLimitController.text = details.creditLimit.toString();
  }

  void onTaxTypeChanged(int? value, int taxType) {
    if (isDisposed()) return;

    selectedTaxType.value = value ?? 1;

    if (taxType == 1) {
      for (var item in poProvider.items) {
        item.taxType = 'cgst_sgst';
        item.pendingIgst = 0.0;
        item.pendingCgst = (item.taxAmount ?? 0.0) / 2;
        item.pendingSgst = (item.taxAmount ?? 0.0) / 2;
      }
    } else {
      for (var item in poProvider.items) {
        item.taxType = 'igst';
        item.pendingCgst = 0.0;
        item.pendingSgst = 0.0;
        item.pendingIgst = item.taxAmount ?? 0.0;
      }
    }
  }

  Future<void> savePurchaseOrder({
    required GlobalKey vendorSectionKey,
    required GlobalKey billingSectionKey,
    required GlobalKey itemsSectionKey,
  }) async {
    if (isDisposed()) return;

    if (vendorController.text.isEmpty ||
        notifier.selectedVendor == null ||
        notifier.selectedVendor!.isEmpty) {
      _showRequiredFieldSnackBar(
        'Please select a vendor',
        scrollKey: vendorSectionKey,
      );
      return;
    }

    if (notifier.billingController.text.isEmpty) {
      _showRequiredFieldSnackBar(
        'Please enter billing address',
        scrollKey: billingSectionKey,
      );
      return;
    }

    if (notifier.poItems.isEmpty) {
      _showRequiredFieldSnackBar(
        'Please add at least one item',
        scrollKey: itemsSectionKey,
      );
      return;
    }

    if (!validateRoundOff()) {
      _showRequiredFieldSnackBar("Invalid round-off value");
      return;
    }

    if (!formKey.currentState!.validate()) {
      _showRequiredFieldSnackBar(
        'Please fill all required fields before saving',
        scrollKey: vendorSectionKey,
      );
      return;
    }

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Confirm Save',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            editingPO != null
                ? 'Do you want to update this order?'
                : 'Do you want to save this order?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(editingPO != null ? 'Update Order' : 'Save Order'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || isDisposed()) return;

    try {
      isSaving.value = true;
      if (notifier.isNotifierDisposed) {
        print('⚠️ Notifier is disposed, cannot save');
        _stopSavingSpinner();
        return;
      }
      if (_isControllerDisposed(notifier.vendorContactController) ||
          _isControllerDisposed(notifier.paymentTermsController) ||
          _isControllerDisposed(notifier.billingController) ||
          _isControllerDisposed(notifier.shippingController) ||
          _isControllerDisposed(notifier.orderedDateController)) {
        print('⚠️ One or more controllers are disposed, cannot save');
        _stopSavingSpinner();
        return;
      }
      _verifyItemDataBeforeSubmission();

      final bool success = await notifier.submitPurchaseOrder(context);
      if (isDisposed()) {
        _stopSavingSpinner();
        return;
      }

      if (!success) {
        throw Exception('Purchase Order save failed');
      }

      await poProvider.refreshPOList();

      if (isDisposed()) {
        _stopSavingSpinner();
        return;
      }

      if (editingPO == null) {
        notifier.poItems.clear();
      }

      FocusManager.instance.primaryFocus?.unfocus();

      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      print('❌ Save Purchase Order Error: $e');
      print('Stack trace: $stackTrace');

      if (!isDisposed() && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PO: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!isDisposed()) {
        isSaving.value = false;
      }
    }
  }

  bool _isControllerDisposed(TextEditingController controller) {
    try {
      final text = controller.text;
      return false;
    } catch (e) {
      print('⚠️ Controller check error (likely disposed): $e');
      return true;
    }
  }

  void _stopSavingSpinner() {
    if (!isDisposed()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed()) {
          isSaving.value = false;
        }
      });
    }
  }

  bool validateRoundOff() {
    final value = double.tryParse(notifier.roundOffController.text) ?? 0.0;

    if (value < -2 || value > 2) {
      roundOffErrorNotifier.value = "Round off must be between -2 and +2";
      return false;
    }

    roundOffErrorNotifier.value = null;
    return true;
  }

  void resetAllFields() {
    if (isDisposed()) return;

    // 🚫 DO NOTHING IN EDIT MODE
    if (editingPO != null) {
      print('⚠️ resetAllFields skipped (edit mode)');
      return;
    }

    // ✅ ONLY for Create PO
    vendorController.clear();
    _clearVendorDetails();

    notifier.orderedDateController.clear();
    notifier.expectedDeliveryDateController.clear();
    notifier.billingController.clear();
    notifier.shippingController.clear();

    notifier.poItems.clear();

    notifier.overallDiscountController.text = '0';
    notifier.roundOffController.text = '0';

    notifier.subTotal = 0.0;
    notifier.itemWiseDiscount = 0.0;
    notifier.overallDiscountAmount = 0.0;
    notifier.calculatedFinalAmount = 0.0;
    notifier.totalOrderAmount = 0.0;

    updateTotalOrderAmount();
    triggerUIRefresh();
  }

  void _resetItemFields() {
    notifier.itemController.clear();
    notifier.uomController.clear();
    notifier.eachQuantityController.clear();
    notifier.quantityController.clear();
    notifier.existingPriceController.clear();
    notifier.newPriceController.clear();
    notifier.varianceController.clear();
    notifier.taxPercentageController.clear();
    notifier.befTaxDiscountController.clear();
    notifier.afTaxDiscountController.clear();

    notifier.countController.text = '1';
    notifier.clearSelectedItem();
    triggerUIRefresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed()) notifier.fetchItems('');
    });
  }

  Future<void> applyDiscount() async {
    if (isDisposed()) return;
    if (!context.mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final discountText = notifier.overallDiscountController.text.trim();
    if (discountText.isEmpty) {
      _showRequiredFieldSnackBar('Please enter discount value');
      return;
    }

    final discountValue = double.tryParse(discountText);
    if (discountValue == null || discountValue < 0) {
      _showRequiredFieldSnackBar('Invalid discount value');
      return;
    }

    try {
      // 🔒 VALIDATE ITEM IDs (THIS FIXES "Item ID missing")
      for (final item in notifier.poItems) {
        if (item.itemId == null || item.itemId!.isEmpty) {
          throw Exception('Item ID missing');
        }
      }

      // 🔥 BUILD PAYLOAD (ROOT FIX FOR 422 ERROR)
      final itemList = notifier.poItems.map((item) {
        return {
          "itemId": item.itemId,
          "quantity": item.quantity ?? 0.0,
          "newPrice": item.newPrice ?? 0.0,
          "pendingTotalQuantity":
              item.pendingTotalQuantity ?? item.quantity ?? 0.0,
          "poQuantity": item.poQuantity ?? item.quantity ?? 0.0,

          // BEFORE TAX DISCOUNT
          "befTaxDiscount": item.befTaxDiscount ?? 0.0,
          "befTaxDiscountType": item.befTaxDiscountType ?? "amount",
          "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,

          // 🔥 OVERALL DISCOUNT → BACKEND WILL CALCULATE
          "afTaxDiscount": 0.0,
          "afTaxDiscountType": "amount",
          "afTaxDiscountAmount": 0.0,

          "taxPercentage": item.taxPercentage ?? 0.0,
          "taxType": selectedTaxType.value == 1 ? "cgst_sgst" : "igst",
        };
      }).toList();

      final bool isPercentage =
          overallDiscountMode.value == DiscountMode.percentage;

      // 📤 API CALL
      final response = await poProvider.calculateOverallDiscountAPI(
        items: itemList,
        applyOverallDiscount: true,
        overallDiscountType: isPercentage ? "percentage" : "amount",
        overallDiscount: isPercentage ? discountValue : 0.0,
        overallDiscountAmount: isPercentage ? 0.0 : discountValue,
      );

      if (response["success"] != true) {
        throw Exception(response["error"] ?? "Discount failed");
      }

      // ✅ APPLY BACKEND RESULT TO UI
      final List items = response["items"] ?? [];
      final summary = response["summary"] ?? {};

      double safeToDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }

      for (int i = 0; i < items.length; i++) {
        final apiItem = items[i];
        final uiItem = notifier.poItems[i];

        uiItem.afTaxDiscount = safeToDouble(apiItem["afTaxDiscountPercentage"]);
        uiItem.afTaxDiscountAmount = safeToDouble(
          apiItem["pendingAfTaxDiscountAmount"],
        );
        uiItem.finalPrice = safeToDouble(apiItem["pendingFinalPrice"]);
        uiItem.pendingFinalPrice = uiItem.finalPrice;
        uiItem.totalPrice = safeToDouble(apiItem["pendingTotalPrice"]);
        uiItem.pendingTotalPrice = uiItem.totalPrice;
        uiItem.taxAmount = safeToDouble(apiItem["pendingTaxAmount"]);
        uiItem.pendingTaxAmount = uiItem.taxAmount;
        uiItem.discountAmount = safeToDouble(apiItem["pendingDiscountAmount"]);
        uiItem.pendingDiscountAmount = uiItem.discountAmount;
        uiItem.pendingCgst = safeToDouble(apiItem["pendingCgst"]);
        uiItem.pendingSgst = safeToDouble(apiItem["pendingSgst"]);
        uiItem.pendingIgst = safeToDouble(apiItem["pendingIgst"]);
      }

      // ✅ TOTALS FROM BACKEND
      notifier.pendingTaxAmount = safeToDouble(summary["totalTaxAmount"]);
      notifier.totalOrderAmount = safeToDouble(summary["totalFinalAmount"]);
      notifier.overallDiscountAmount = safeToDouble(
        summary["overallDiscountTotalAmount"],
      );

      notifier.discountMode.value = overallDiscountMode.value;

      notifier.calculateTotals();
      updateTotalOrderAmount();
      triggerUIRefresh();
    } catch (e) {
      if (context.mounted) {
        _showRequiredFieldSnackBar(e.toString());
      }
    }
  }

  void _updateItemsWithOverallDiscount(List<dynamic> updatedItems) {
    for (
      int i = 0;
      i < updatedItems.length && i < notifier.poItems.length;
      i++
    ) {
      final apiItem = updatedItems[i];
      final item = notifier.poItems[i];

      double toDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }

      // ✅ Backend-calculated values ONLY
      item.afTaxDiscount = toDouble(apiItem['afTaxDiscount']);
      item.afTaxDiscountAmount = toDouble(apiItem['afTaxDiscountAmount']);
      item.pendingAfTaxDiscountAmount = toDouble(
        apiItem['pendingAfTaxDiscountAmount'],
      );

      item.totalPrice = toDouble(apiItem['pendingTotalPrice']);
      item.pendingTotalPrice = toDouble(apiItem['pendingTotalPrice']);

      item.taxAmount = toDouble(apiItem['pendingTaxAmount']);
      item.pendingTaxAmount = toDouble(apiItem['pendingTaxAmount']);

      item.finalPrice = toDouble(apiItem['pendingFinalPrice']);
      item.pendingFinalPrice = toDouble(apiItem['pendingFinalPrice']);

      item.pendingDiscountAmount = toDouble(apiItem['pendingDiscountAmount']);

      item.pendingCgst = toDouble(apiItem['pendingCgst']);
      item.pendingSgst = toDouble(apiItem['pendingSgst']);
      item.pendingIgst = toDouble(apiItem['pendingIgst']);
    }

    notifier.notifyListeners();
  }

  void _showRequiredFieldSnackBar(String message, {GlobalKey? scrollKey}) {
    if (isDisposed()) return;

    final overlayState = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    if (scrollKey != null) {
      _scrollToField(scrollKey);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  void _scrollToField(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null && !isDisposed()) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  // void _setupInitialAddresses() {
  //   // Billing
  //   if (notifier.billingAddress.isNotEmpty &&
  //       notifier.billingController.text.isEmpty) {
  //     final first = notifier.billingAddress.first;
  //     final label = '${first.address1} ${first.address2}';
  //     notifier.billingController.text = label;
  //     notifier.setSelectedbillingaddress(first.businessId);
  //   }

  //   // Shipping
  //   if (notifier.shippingAddress.isNotEmpty &&
  //       notifier.shippingController.text.isEmpty) {
  //     final first = notifier.shippingAddress.first;
  //     notifier.shippingController.text = first.address;
  //     notifier.setSelectedshippingaddress(first.shippingId);
  //   }
  // }

  void _initializeWithPOData(PO po) {
    if (isDisposed()) return;

    print('🟢 Loading edit PO: ${po.purchaseOrderId}');

    // -------------------------------
    // 1️⃣ SET EDITING PO
    // -------------------------------
    notifier.setEditingPO(po);

    // -------------------------------
    // 2️⃣ VENDOR DETAILS
    // -------------------------------
    notifier.selectedVendor = po.vendorName;
    vendorController.text = po.vendorName ?? '';

    notifier.vendorContactController.text = po.vendorContact ?? '';
    notifier.paymentTermsController.text = po.paymentTerms ?? '';
    notifier.creditLimitController.text = (po.creditLimit ?? 0).toString();

    notifier.selectedVendorDetails = VendorAll(
      vendorName: po.vendorName ?? '',
      contactpersonPhone: po.vendorContact ?? '',
      vendorId: '',
      paymentTerms: po.paymentTerms ?? '',
      contactpersonEmail: po.contactpersonEmail ?? '',
      address: po.address ?? '',
      country: po.country ?? '',
      state: po.state ?? '',
      city: po.city ?? '',
      postalCode: po.postalCode ?? 0,
      gstNumber: po.gstNumber ?? '',
      creditLimit: po.creditLimit ?? 0,
    );

    // -------------------------------
    // 3️⃣ DATES
    // -------------------------------
    notifier.orderedDateController.text = formatDate(po.orderDate ?? '');
    notifier.expectedDeliveryDateController.text = formatDate(
      po.expectedDeliveryDate ?? '',
    );

    // -------------------------------
    // 4️⃣ ADDRESSES
    // -------------------------------
    notifier.billingController.text = po.billingAddress ?? '';
    notifier.shippingController.text = po.shippingAddress ?? '';

    // -------------------------------
    // 5️⃣ ITEMS (🔥 MOST IMPORTANT PART)
    // -------------------------------
    notifier.poItems.clear();

    for (final item in po.items) {
      final quantity = item.quantity ?? 0.0;
      final price = item.newPrice ?? item.existingPrice ?? 0.0;

      final totalPrice = quantity * price;

      final newItem = Item(
        itemId: item.itemId,
        itemName: item.itemName,
        purchasecategoryName: item.purchasecategoryName,
        purchasesubcategoryName: item.purchasesubcategoryName,
        uom: item.uom,

        count: item.count ?? 1.0,
        eachQuantity: item.eachQuantity ?? quantity,
        quantity: quantity,

        existingPrice: item.existingPrice ?? price,
        newPrice: price,

        taxPercentage: item.taxPercentage ?? 0.0,
        taxType: item.taxType ?? 'cgst_sgst',

        // 🔥 BASE PRICES
        totalPrice: totalPrice,
        finalPrice: totalPrice,

        // 🔥 PENDING VALUES (WITHOUT THIS → TOTAL = 0)
        pendingTotalQuantity: quantity,
        pendingTotalPrice: totalPrice,
        pendingFinalPrice: totalPrice,
        pendingOrderAmount: totalPrice,
        pendingTaxAmount: item.pendingTaxAmount ?? item.taxAmount ?? 0.0,

        // 🔥 DISCOUNTS
        befTaxDiscount: item.befTaxDiscount ?? 0.0,
        afTaxDiscount: item.afTaxDiscount ?? 0.0,
        befTaxDiscountAmount: item.befTaxDiscountAmount ?? 0.0,
        afTaxDiscountAmount: item.afTaxDiscountAmount ?? 0.0,
        pendingDiscountAmount: item.pendingDiscountAmount ?? 0.0,

        // 🔥 TAX SPLIT
        pendingCgst: item.pendingCgst ?? 0.0,
        pendingSgst: item.pendingSgst ?? 0.0,
        pendingIgst: item.pendingIgst ?? 0.0,

        status: item.status,
        barcode: item.barcode,
        expiryDate: item.expiryDate ?? '',
      );

      notifier.poItems.add(newItem);
    }

    // -------------------------------
    // 6️⃣ ROUND OFF (ONLY BACKEND VALUE)
    // -------------------------------
    notifier.roundOffController.text = (po.roundOffAdjustment ?? 0.0)
        .toStringAsFixed(2);

    // -------------------------------
    // 7️⃣ TAX TYPE
    // -------------------------------
    if (po.items.isNotEmpty) {
      final taxType = po.items.first.taxType ?? 'cgst_sgst';
      selectedTaxType.value = taxType == 'igst' ? 2 : 1;
    } else {
      selectedTaxType.value = 1;
    }

    // -------------------------------
    // 8️⃣ DISCOUNT SECTION
    // -------------------------------
    _initializeDiscountSectionWithPOData(po);

    // -------------------------------
    // 9️⃣ FINAL RECALC (🔥 REQUIRED)
    // -------------------------------
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDisposed()) return;

      notifier.calculateTotals();
      updateTotalOrderAmount();
      triggerUIRefresh();

      print('✅ Edit PO fully initialized: ${po.randomId}');
    });
  }

  void _initializeDiscountSectionWithPOData(PO po) {
    if (po.items.isEmpty) return;

    bool hasOverallDiscount = false;
    double overallDiscountValue = 0.0;
    String overallDiscountType = 'percentage';

    final firstItem = po.items.first;
    final commonAfTaxDiscount = firstItem.afTaxDiscount ?? 0.0;
    final commonAfTaxDiscountType = firstItem.afTaxDiscountType ?? 'percentage';

    bool allItemsHaveSameDiscount = po.items.every((item) {
      return (item.afTaxDiscount ?? 0.0) == commonAfTaxDiscount &&
          (item.afTaxDiscountType ?? 'percentage') == commonAfTaxDiscountType;
    });

    // ✅ Only percentage can be treated as overall discount
    if (allItemsHaveSameDiscount &&
        commonAfTaxDiscount > 0 &&
        commonAfTaxDiscountType == 'percentage') {
      hasOverallDiscount = true;
      overallDiscountValue = commonAfTaxDiscount;
      overallDiscountType = commonAfTaxDiscountType;
    }

    if (hasOverallDiscount) {
      overallDiscountMode.value = DiscountMode.percentage;
      notifier.discountMode.value = DiscountMode.percentage;

      notifier.overallDiscountController.text = overallDiscountValue
          .toStringAsFixed(2);
      notifier.isOverallDiscountActive = true;
    } else {
      overallDiscountMode.value = DiscountMode.none;
      notifier.discountMode.value = DiscountMode.none;
      notifier.overallDiscountController.text = '0';
      notifier.isOverallDiscountActive = false;
    }
  }

  void _validateAndFixRoundoff(PO po) {
    if (isDisposed()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDisposed()) return;

      double expectedTotal = po.totalOrderAmount ?? 0.0;
      double calculatedTotal = notifier.calculatedFinalAmount;

      double roundOffInController =
          double.tryParse(notifier.roundOffController.text) ?? 0.0;

      if ((expectedTotal - calculatedTotal).abs() > 0.01) {
        double correctedRoundOff =
            expectedTotal - (calculatedTotal - roundOffInController);

        notifier.roundOffController.text = correctedRoundOff.toStringAsFixed(2);

        notifier.calculateTotals();
        updateTotalOrderAmount();
        triggerUIRefresh();
      }
    });
  }

  void _verifyItemDataBeforeSubmission() {
    // ✅ NO FRONTEND VALIDATION
    // Backend will validate itemId, quantity, price, tax, etc.
  }

  DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    try {
      if (dateString.contains('-') && dateString.length >= 10) {
        if (dateString.split('-')[0].length == 2) {
          final parts = dateString.split('-');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              return DateTime(year, month, day);
            }
          }
        } else {
          final clean = dateString.split(' ')[0];
          return DateTime.tryParse(clean);
        }
      }
      return DateTime.tryParse(dateString);
    } catch (_) {
      return null;
    }
  }

  String _formatToDDMMYYYY(String input) {
    try {
      final date = DateTime.parse(input);
      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (_) {
      return input;
    }
  }

  void updateTotalOrderAmount() {
    if (isDisposed()) return;

    // ✅ Just reflect backend-calculated total
    totalOrderAmount.value = notifier.totalOrderAmount;
  }

  void triggerUIRefresh() {
    if (isDisposed()) return;
    refreshUI.value = !refreshUI.value;
  }

  void applyTemplate(POTemplate t) {
    if (isDisposed()) return;

    if (editingPO != null) return;
    // ------------------------------------------------------------
    // 🔒 Prevent vendorController listener from clearing details
    // ------------------------------------------------------------
    vendorController.removeListener(_onVendorInputChanged);

    // ------------------------------------------------------------
    // CLEAR ITEMS ONLY (Do NOT reset controllers!)
    // ------------------------------------------------------------
    notifier.poItems.clear();

    // ------------------------------------------------------------
    // ✅ LOAD VENDOR BASIC INFORMATION
    // ------------------------------------------------------------
    notifier.selectedVendor = t.vendorName;
    vendorController.text = t.vendorName;

    notifier.vendorContactController.text = t.vendorContact;
    notifier.paymentTermsController.text = t.paymentTerms;
    notifier.creditLimitController.text = t.creditLimit == 0
        ? ''
        : t.creditLimit.toString();

    notifier.gstNumberController.text = t.gstNumber;

    // ------------------------------------------------------------
    // ✅ SET SELECTED VENDOR DETAILS OBJECT
    // ------------------------------------------------------------
    notifier.selectedVendorDetails = VendorAll(
      vendorName: t.vendorName,
      contactpersonPhone: t.vendorContact,
      paymentTerms: t.paymentTerms,
      contactpersonEmail: t.contactpersonEmail,
      address: t.address,
      country: t.country,
      state: t.state,
      city: t.city,
      postalCode: t.postalCode,
      gstNumber: t.gstNumber,
      creditLimit: t.creditLimit,
      vendorId: '',
    );

    // ------------------------------------------------------------
    // ✅ LOAD ADDRESS FIELDS
    // ------------------------------------------------------------
    notifier.addressController.text = t.address;
    notifier.countryController.text = t.country;
    notifier.stateController.text = t.state;
    notifier.cityController.text = t.city;
    notifier.postalCodeController.text = t.postalCode.toString();

    notifier.billingController.text = t.billingAddress;
    notifier.shippingController.text = t.shippingAddress;

    // Template does not store IDs → clear them safely
    notifier.setSelectedbillingaddress(null);
    notifier.setSelectedshippingaddress(null);

    // ------------------------------------------------------------
    // ✅ LOAD ITEMS
    // ------------------------------------------------------------
    notifier.poItems.addAll(t.items.map((item) => item.copyWith()).toList());

    // ------------------------------------------------------------
    // ✅ SET TAX TYPE BASED ON FIRST ITEM
    // ------------------------------------------------------------
    if (t.items.isNotEmpty) {
      final taxType = t.items.first.taxType ?? 'cgst_sgst';
      selectedTaxType.value = taxType == 'igst' ? 2 : 1;
    } else {
      selectedTaxType.value = 1;
    }

    // ------------------------------------------------------------
    // 🔄 RESET DISCOUNTS (Template cannot apply old discounts cleanly)
    // ------------------------------------------------------------
    notifier.overallDiscountController.text = '0';
    notifier.roundOffController.text = '0';
    notifier.discountMode.value = DiscountMode.none;
    overallDiscountMode.value = DiscountMode.none;

    // ------------------------------------------------------------
    // 🔢 RECALCULATE TOTALS
    // ------------------------------------------------------------
    // notifier.calculateTotals();
    updateTotalOrderAmount();

    // ------------------------------------------------------------
    // 🔄 Trigger UI refresh
    // ------------------------------------------------------------
    triggerUIRefresh();

    vendorController.addListener(_onVendorInputChanged);
  }

  String formatDate(String s) {
    if (s.isEmpty) return "";

    try {
      final date = DateTime.tryParse(s);
      if (date != null) {
        return "${date.day.toString().padLeft(2, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.year}";
      }

      if (s.contains("-") && s.split("-").length == 3) {
        return s; // already formatted
      }

      return "";
    } catch (_) {
      return "";
    }
  }
}
