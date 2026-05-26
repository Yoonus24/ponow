import 'po_notifier_state.dart';

mixin PONotifierControllerMixin on PurchaseOrderNotifierState {
  @override
  void updateVariance() {
    if (disposed) return;
    double existingPrice = double.tryParse(existingPriceController.text) ?? 0;
    double newPrice = double.tryParse(newPriceController.text) ?? 0;
    double variance = newPrice - existingPrice;
    varianceController.text = variance.toStringAsFixed(2);
    safeNotify();
  }

  void resetControllers() {
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

    selectedVendor = '';
    selectedVendorDetails = null;

    selectedLocation = '';
    selectedLocationName = '';

    selectedPaymentTerm = '';
    selectedShippingaddress = '';
    selectedBillingaddress = '';

    poItems.clear();
    purchaseItems.clear();
    filteredItems.clear();
    freights.clear();
    totalFreightAmount = 0;
    totalFreightTaxAmount = 0;

    editingIndex = null;
    editItemInternal = null;
    editingPOInternal = null;

    subTotalInternal = 0.0;
    itemWiseDiscountInternal = 0.0;
    overallDiscountAmountInternal = 0.0;
    calculatedFinalAmountInternal = 0.0;
    totalOrderAmount = 0.0;
    overallDiscountValueInternal = 0.0;

    notifyListeners();
  }
}