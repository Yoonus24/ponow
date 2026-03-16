import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/freight.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/models/vendorpurchasemodel.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/discount_model.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:purchaseorders2/models/po_template.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

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
        _initializeWithPOData(editingPO!);
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
  }

  void cleanup() {
    vendorController.removeListener(_onVendorInputChanged);
    try {
      isSaving.dispose();
      selectedTaxType.dispose();
      showValidationErrors.dispose();
      roundOffErrorNotifier.dispose();
    } catch (e) {}
  }

  Future<void> _initializeForNewPO() async {
    if (isDisposed()) return;

    await Future.wait([
      notifier.fetchShippingAddress1(),
      notifier.fetchBillingAddress1(),
    ]);

    await poProvider.preloadBranches();

    await notifier.fetchItems('');

    notifier.expectedDeliveryDateController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      applyAddressesIfReady();
      applyLocationIfReady();
    });

    if (!isDisposed()) {
      final now = ServerTimeService.now;
      notifier.orderedDateController.text =
          "${now.day.toString().padLeft(2, '0')}-"
          "${now.month.toString().padLeft(2, '0')}-"
          "${now.year}";
    }

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

  void applyLocationIfReady() {
    if (isDisposed()) return;

    final branches = poProvider.branches;
    if (branches.isEmpty) return;

    if (notifier.selectedLocation != null &&
        notifier.selectedLocation!.isNotEmpty) {
      return;
    }

    final selected = branches.firstWhere(
      (b) => b.location.toLowerCase() == 'prod_gw',
      orElse: () => branches.first,
    );

    notifier.setLocation(
      location: selected.location,
      locationName: selected.branchName,
    );
  }

  void _onVendorInputChanged() {
    if (isDisposed()) return;

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
    } catch (e) {}
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

      // ✅ ROUND OFF FIX START
      final roundOff = double.tryParse(notifier.roundOffController.text) ?? 0.0;

      notifier.roundOffAdjustment = roundOff;

      debugPrint("🟢 ROUND OFF BEFORE SAVE: $roundOff");
      debugPrint("🟢 TOTAL ORDER BEFORE SAVE: ${notifier.totalOrderAmount}");
      // ✅ ROUND OFF FIX END

      if (notifier.isNotifierDisposed) {
        _stopSavingSpinner();
        return;
      }

      if (_isControllerDisposed(notifier.vendorContactController) ||
          _isControllerDisposed(notifier.paymentTermsController) ||
          _isControllerDisposed(notifier.billingController) ||
          _isControllerDisposed(notifier.shippingController) ||
          _isControllerDisposed(notifier.orderedDateController)) {
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
        notifier.clearFreights();
      }

      FocusManager.instance.primaryFocus?.unfocus();

      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
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

    if (editingPO != null) {
      return;
    }

    vendorController.clear();
    _clearVendorDetails();

    notifier.orderedDateController.clear();
    notifier.expectedDeliveryDateController.clear();
    notifier.billingController.clear();
    notifier.shippingController.clear();

    notifier.poItems.clear();
    notifier.clearFreights();

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
    if (discountValue == null || discountValue <= 0) {
      _showRequiredFieldSnackBar('Invalid discount value');
      return;
    }

    try {
      final itemList = notifier.poItems.map((item) {
        return {
          "itemId": item.itemId,
          "quantity": item.quantity ?? 0.0,
          "newPrice": item.newPrice ?? 0.0,
          "pendingTotalQuantity":
              item.pendingTotalQuantity ?? item.quantity ?? 0.0,
          "poQuantity": item.poQuantity ?? item.quantity ?? 0.0,

          "befTaxDiscount": item.befTaxDiscount ?? 0.0,
          "befTaxDiscountType": item.befTaxDiscountType ?? "percentage",
          "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,

          "afTaxDiscount": 0.0,
          "afTaxDiscountType": "amount",
          "afTaxDiscountAmount": 0.0,

          "taxPercentage": item.taxPercentage ?? 0.0,
          "taxType": selectedTaxType.value == 1 ? "cgst_sgst" : "igst",
        };
      }).toList();

      final bool isPercentage =
          overallDiscountMode.value == DiscountMode.percentage;

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

      notifier.isOverallDiscountActive = true;
      notifier.discountMode.value = overallDiscountMode.value;
      final List items = response["items"] ?? [];
      final summary = response["summary"] ?? {};

      double toDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }

      for (int i = 0; i < items.length; i++) {
        final apiItem = items[i];
        final uiItem = notifier.poItems[i];

        uiItem.afTaxDiscount = toDouble(apiItem["afTaxDiscount"]);
        uiItem.afTaxDiscountAmount = toDouble(
          apiItem["pendingAfTaxDiscountAmount"],
        );

        uiItem.finalPrice = toDouble(apiItem["pendingFinalPrice"]);
        uiItem.pendingFinalPrice = uiItem.finalPrice;

        uiItem.totalPrice = toDouble(apiItem["pendingTotalPrice"]);
        uiItem.pendingTotalPrice = uiItem.totalPrice;

        uiItem.taxAmount = toDouble(apiItem["pendingTaxAmount"]);
        uiItem.pendingTaxAmount = uiItem.taxAmount;

        uiItem.pendingDiscountAmount = toDouble(
          apiItem["pendingDiscountAmount"],
        );

        uiItem.pendingCgst = toDouble(apiItem["pendingCgst"]);
        uiItem.pendingSgst = toDouble(apiItem["pendingSgst"]);
        uiItem.pendingIgst = toDouble(apiItem["pendingIgst"]);
      }

      notifier.pendingTaxAmount = toDouble(summary["totalTaxAmount"]);
      notifier.totalOrderAmount = toDouble(summary["totalFinalAmount"]);
      notifier.overallDiscountAmount = toDouble(
        summary["overallDiscountTotalAmount"],
      );

      notifier.calculateTotals();
      updateTotalOrderAmount();
      triggerUIRefresh();
    } catch (e) {
      if (context.mounted) {
        _showRequiredFieldSnackBar(e.toString());
      }
    }
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

  void _initializeWithPOData(PO po) {
    if (isDisposed()) return;

    notifier.setEditingPO(po);

    VendorAll vendor;
    try {
      vendor = notifier.vendorAllList.firstWhere(
        (v) => v.vendorName == po.vendorName,
      );
    } catch (_) {
      vendor = VendorAll(
        vendorName: po.vendorName ?? '',
        contactpersonPhone: po.vendorContact ?? '',
        paymentTerms: po.paymentTerms ?? '',
        contactpersonEmail: po.contactpersonEmail ?? '',
        address: po.billingAddress ?? '',
        country: po.country ?? '',
        state: po.state ?? '',
        city: po.city ?? '',
        postalCode: po.postalCode ?? 0,
        gstNumber: po.gstNumber ?? '',
        creditLimit: po.creditLimit ?? 0,
        vendorId: '',
      );
    }

    notifier.setSelectedVendor(vendor.vendorName);
    notifier.selectedVendorDetails = vendor;
    vendorController.text = vendor.vendorName;
    notifier.vendorContactController.text = vendor.contactpersonPhone;
    notifier.paymentTermsController.text = vendor.paymentTerms;
    notifier.creditLimitController.text = vendor.creditLimit.toString();

    if (po.location != null && po.location!.isNotEmpty) {
      notifier.setLocation(
        location: po.location!,
        locationName: po.locationName,
      );
    }

    notifier.orderedDateController.text = formatDate(po.orderDate ?? '');

    debugPrint("EXPECTED DATE RAW: ${po.expectedDeliveryDate}");

    final expectedDate = po.expectedDeliveryDate;

    notifier.expectedDeliveryDateController.text =
        (expectedDate != null && expectedDate.isNotEmpty)
        ? formatDate(expectedDate)
        : ""; // fallback empty

    notifier.billingController.text = po.billingAddress ?? '';
    notifier.shippingController.text = po.shippingAddress ?? '';

    notifier.roundOffController.text = (po.roundOffAdjustment ?? 0.0)
        .toStringAsFixed(2);

    notifier.poItems.clear();

    for (final item in po.items) {
      final qty = (item.quantity ?? 0.0).toDouble();

      final existing = (item.existingPrice ?? item.newPrice ?? 0.0).toDouble();
      final newP = (item.newPrice ?? existing).toDouble();

      final base = qty * newP;

      final befDisc = (item.befTaxDiscountAmount ?? 0.0).toDouble();
      final afDisc = (item.pendingDiscountAmount ?? 0.0).toDouble();

      final tax = (item.pendingTaxAmount ?? item.taxAmount ?? 0.0).toDouble();

      double finalPrice = (item.pendingFinalPrice ?? 0.0).toDouble();

      if (finalPrice == 0.0 && base > 0) {
        finalPrice = base + tax - befDisc - afDisc;
        if (finalPrice < 0) finalPrice = 0.0;
      }

      notifier.poItems.add(
        Item(
          itemId: item.itemId,
          itemName: item.itemName,
          uom: item.uom,

          quantity: qty,

          count: (item.count == null || item.count == 0) ? 1.0 : item.count,

          eachQuantity: (item.eachQuantity == null || item.eachQuantity == 0)
              ? qty
              : item.eachQuantity,

          existingPrice: existing,
          newPrice: newP,

          taxPercentage: item.taxPercentage ?? 0.0,
          taxType: item.taxType ?? 'cgst_sgst',

          befTaxDiscount: item.befTaxDiscount ?? 0.0,
          afTaxDiscount: item.afTaxDiscount ?? 0.0,

          befTaxDiscountAmount: befDisc,
          afTaxDiscountAmount: afDisc,

          taxAmount: tax,

          totalPrice: base,
          pendingTotalPrice: base,

          finalPrice: finalPrice,
          pendingFinalPrice: finalPrice,

          pendingTaxAmount: tax,
          pendingDiscountAmount: befDisc + afDisc,

          pendingCgst:
              item.pendingCgst ?? (item.taxType == 'cgst_sgst' ? tax / 2 : 0.0),

          pendingSgst:
              item.pendingSgst ?? (item.taxType == 'cgst_sgst' ? tax / 2 : 0.0),

          pendingIgst: item.pendingIgst ?? (item.taxType == 'igst' ? tax : 0.0),

          expiryDate: '',
        ),
      );
    }

    _initializeDiscountSectionWithPOData(po);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isDisposed()) return;

      notifier.recalculateFromLoadedPO(notify: true);

      debugPrint("TOTAL ORDER AMOUNT: ${notifier.totalOrderAmount}");
      debugPrint(
        "EXPECTED DELIVERY DATE UI: ${notifier.expectedDeliveryDateController.text}",
      );

      updateTotalOrderAmount();
      triggerUIRefresh();
    });
  }

  void _initializeDiscountSectionWithPOData(PO po) {
    if (isDisposed()) return;

    // 🔹 Reset everything first
    notifier.isOverallDiscountActive = false;
    notifier.isOverallDisabledFromItem = false;

    notifier.discountMode.value = DiscountMode.none;
    overallDiscountMode.value = DiscountMode.none;

    notifier.overallDiscountController.text = '0';
    notifier.overallDiscountAmount = 0.0;

    // 🔹 Always use backend truth for total discount
    notifier.itemWiseDiscount = po.items.fold(
      0.0,
      (sum, item) => sum + (item.pendingDiscountAmount ?? 0.0),
    );

    // 🔹 Calculate individual discount types
    double totalBef = po.items.fold(
      0.0,
      (s, i) => s + (i.befTaxDiscountAmount ?? 0.0),
    );

    double totalAf = po.items.fold(
      0.0,
      (s, i) => s + (i.afTaxDiscountAmount ?? 0.0),
    );

    // 🔥 RULE: MUTUAL EXCLUSIVITY
    if (totalBef > 0) {
      // ✅ ITEM-WISE DISCOUNT EXISTS → DISABLE OVERALL
      notifier.isOverallDiscountActive = false;
      notifier.isOverallDisabledFromItem = true;

      notifier.discountMode.value = DiscountMode.none;
      overallDiscountMode.value = DiscountMode.none;

      notifier.overallDiscountController.text = '0';
    } else if (totalAf > 0) {
      // ✅ OVERALL DISCOUNT EXISTS → ENABLE OVERALL
      notifier.isOverallDiscountActive = true;
      notifier.isOverallDisabledFromItem = false;

      // Detect type (percentage / amount)
      final first = po.items.first;

      final type = first.afTaxDiscountType ?? 'percentage';

      notifier.discountMode.value = type == 'percentage'
          ? DiscountMode.percentage
          : DiscountMode.fixedAmount;

      overallDiscountMode.value = notifier.discountMode.value;

      notifier.overallDiscountController.text = (first.afTaxDiscount ?? 0.0)
          .toStringAsFixed(2);

      // Optional: calculate total overall discount
      notifier.overallDiscountAmount = po.items.fold(
        0.0,
        (sum, i) => sum + (i.afTaxDiscountAmount ?? 0.0),
      );
    } else {
      // ✅ NO DISCOUNT
      notifier.isOverallDiscountActive = false;
      notifier.isOverallDisabledFromItem = false;

      notifier.discountMode.value = DiscountMode.none;
      overallDiscountMode.value = DiscountMode.none;

      notifier.overallDiscountController.text = '0';
    }

    notifier.notifyListeners();
  }

  void _verifyItemDataBeforeSubmission() {}

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

  void updateTotalOrderAmount() {
    if (isDisposed()) return;

    totalOrderAmount.value = notifier.totalOrderAmount;
  }

  void triggerUIRefresh() {
    if (isDisposed()) return;
    refreshUI.value = !refreshUI.value;
  }

  void applyTemplate(POTemplate t) {
    if (isDisposed()) return;

    if (editingPO != null) return;

    notifier.poItems.clear();
    notifier.clearFreights();

    notifier.isOverallDiscountActive = false;
    notifier.discountMode.value = DiscountMode.none;
    overallDiscountMode.value = DiscountMode.none;

    notifier.overallDiscountController.text = '0';
    notifier.overallDiscountAmount = 0.0;
    notifier.itemWiseDiscount = 0.0;

    notifier.setSelectedVendor(t.vendorName);
    vendorController.text = t.vendorName;

    try {
      final vendor = notifier.vendorAllList.firstWhere(
        (v) => v.vendorName == t.vendorName,
      );

      notifier.selectedVendorDetails = vendor;
      notifier.vendorContactController.text = vendor.contactpersonPhone;
      notifier.paymentTermsController.text = vendor.paymentTerms;
      notifier.creditLimitController.text = vendor.creditLimit.toString();
    } catch (_) {
      notifier.selectedVendorDetails = null;
    }

    if (t.location != null && t.location!.isNotEmpty) {
      notifier.setLocation(location: t.location!, locationName: t.locationName);
    }

    notifier.billingController.text = t.billingAddress;
    notifier.shippingController.text = t.shippingAddress;

    /// LOAD ITEMS
    notifier.poItems.addAll(t.items.map((i) => i.copyWith()).toList());

    /// LOAD FREIGHT
    if (t.freights.isNotEmpty) {
      notifier.freights.addAll(
        t.freights.map(
          (f) => FreightData(
            id: f.id,
            name: f.name,
            amount: f.amount,
            taxCode: f.taxCode,
            taxType: f.taxType,
            sgst: f.sgst,
            cgst: f.cgst,
            igst: f.igst,
            taxAmount: f.taxAmount,
            total: f.total,
          ),
        ),
      );
    }

    /// RECALCULATE ITEMS
    for (final item in notifier.poItems) {
      final qty = item.quantity ?? 0.0;
      final price = item.newPrice ?? 0.0;
      final base = qty * price;

      final taxPct = item.taxPercentage ?? 0.0;
      final tax = base * taxPct / 100;

      item.totalPrice = base;
      item.pendingTotalPrice = base;

      item.taxAmount = tax;
      item.pendingTaxAmount = tax;

      final befDisc = item.befTaxDiscountAmount ?? 0.0;
      final afDisc = item.afTaxDiscountAmount ?? 0.0;

      double finalPrice = item.finalPrice ?? 0.0;
      if (finalPrice == 0 && base > 0) {
        finalPrice = base + tax - befDisc - afDisc;
      }

      item.finalPrice = finalPrice;
      item.pendingFinalPrice = finalPrice;
      item.pendingDiscountAmount = befDisc + afDisc;
    }

    bool hasOverallDiscount = false;

    if (notifier.poItems.isNotEmpty) {
      final first = notifier.poItems.first;
      final firstPercent = first.afTaxDiscount ?? 0.0;

      hasOverallDiscount =
          firstPercent > 0 &&
          notifier.poItems.every(
            (i) => (i.afTaxDiscount ?? 0.0) == firstPercent,
          ) &&
          notifier.poItems.every((i) => (i.befTaxDiscountAmount ?? 0.0) == 0.0);
    }

    if (hasOverallDiscount) {
      notifier.isOverallDiscountActive = true;

      final type = notifier.poItems.first.afTaxDiscountType ?? 'percentage';

      notifier.discountMode.value = type == 'percentage'
          ? DiscountMode.percentage
          : DiscountMode.fixedAmount;

      overallDiscountMode.value = notifier.discountMode.value;

      notifier.overallDiscountController.text = notifier
          .poItems
          .first
          .afTaxDiscount!
          .toStringAsFixed(2);

      notifier.overallDiscountAmount = notifier.poItems.fold(
        0.0,
        (sum, i) => sum + (i.afTaxDiscountAmount ?? 0.0),
      );

      notifier.itemWiseDiscount = 0.0;
    } else {
      notifier.isOverallDiscountActive = false;

      notifier.itemWiseDiscount = notifier.poItems.fold(
        0.0,
        (sum, i) =>
            sum +
            (i.befTaxDiscountAmount ?? 0.0) +
            (i.afTaxDiscountAmount ?? 0.0),
      );

      notifier.overallDiscountAmount = 0.0;
    }

    /// CALCULATE FREIGHT VALUES
    double freightAmount = notifier.freights.fold(
      0.0,
      (sum, f) => sum + f.amount,
    );

    double freightTax = notifier.freights.fold(
      0.0,
      (sum, f) => sum + f.taxAmount,
    );

    double freightTotal = notifier.freights.fold(
      0.0,
      (sum, f) => sum + f.total,
    );

    notifier.totalFreightAmount = freightAmount;
    notifier.totalFreightTaxAmount = freightTax;

    /// TOTAL ORDER AMOUNT
    double itemTotal = notifier.poItems.fold(
      0.0,
      (sum, i) => sum + (i.finalPrice ?? 0.0),
    );

    notifier.totalOrderAmount = itemTotal + freightTotal;

    notifier.calculatedFinalAmount = notifier.totalOrderAmount;
    notifier.pendingOrderAmount = notifier.totalOrderAmount;

    updateTotalOrderAmount();
    triggerUIRefresh();
    syncDiscountUIFromItems();
  }

  void syncDiscountUIFromItems() {
    if (isDisposed()) return;

    if (notifier.isOverallDiscountActive) {
      notifier.discountMode.value = overallDiscountMode.value;
    } else {
      notifier.discountMode.value = DiscountMode.none;
    }

    notifier.notifyListeners();
    triggerUIRefresh();
  }

  String formatDate(String s) {
    if (s.isEmpty) return "";

    try {
      final date = DateTime.parse(s);

      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (e) {
      debugPrint("DATE PARSE ERROR: $e");
      return "";
    }
  }
}
