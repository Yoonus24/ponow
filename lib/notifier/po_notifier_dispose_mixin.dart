import 'package:flutter/material.dart';
import 'po_notifier_state.dart';

mixin PONotifierDisposeMixin on PurchaseOrderNotifierState {
  @override
  void dispose() {
    disposed = true;
    itemSearchTimer?.cancel();
    newPriceController.removeListener(updateVariance);

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
      befTaxDiscountController,
      afTaxDiscountController,
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
      termsAndConditionsController,
    ];

    for (final c in controllers) {
      try {
        c.dispose();
      } catch (e) {
        debugPrint("Error disposing controller: ${e.toString()}");
      }
    }

    try {
      discountMode.dispose();
    } catch (e) {
      debugPrint("Error disposing discountMode: ${e.toString()}");
    }
    super.dispose();
  }
}
