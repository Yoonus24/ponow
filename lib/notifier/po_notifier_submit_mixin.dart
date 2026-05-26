import 'package:flutter/material.dart';
import '../models/po/po.dart';
import '../models/po/discount_model.dart';
import 'po_notifier_state.dart';

mixin PONotifierSubmitMixin on PurchaseOrderNotifierState {
  Future<bool> submitPurchaseOrder() async {
    if (disposed) return false;

    try {
      if (selectedLocation.isEmpty) {
        throw Exception("Please select location");
      }
      final vendorDetails = selectedVendorDetails;

      if (vendorDetails == null) {
        throw Exception("Please select vendor");
      }

      String getControllerTextSafelyLocal(TextEditingController controller) {
        try {
          return controller.text;
        } catch (e) {
          return '';
        }
      }

      final Map<String, dynamic> snapshot = {
        "vendorContact": getControllerTextSafelyLocal(vendorContactController),
        "paymentTerms": getControllerTextSafelyLocal(paymentTermsController),
        "billing": getControllerTextSafelyLocal(billingController),
        "shipping": getControllerTextSafelyLocal(shippingController),
        "orderedDate": getControllerTextSafelyLocal(orderedDateController),
        "expectedDate": getControllerTextSafelyLocal(
          expectedDeliveryDateController,
        ),
        "roundOff": getControllerTextSafelyLocal(roundOffController),
        "overallDiscount": getControllerTextSafelyLocal(
          overallDiscountController,
        ),
        "termsandConditions": [
          getControllerTextSafelyLocal(termsAndConditionsController),
        ],
      };

      await recalculateTotalsFromBackend();

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

      final finalItems = poItems.map((e) => e.copyWith()).toList();

      double roundOffValue = double.tryParse(snapshot["roundOff"] ?? '') ?? 0.0;

      final bool hasOverallDiscount = discountMode.value != DiscountMode.none;

      final double overallDiscountValue = hasOverallDiscount
          ? double.tryParse(snapshot["overallDiscount"] ?? '') ?? 0.0
          : 0.0;

      // ================= EDIT CASE =================
      if (editingPOInternal != null) {
        final updatedPO = editingPOInternal!.copyWith(
          vendorName: selectedVendor,
          vendorContact: snapshot["vendorContact"],
          termsandConditions: (snapshot["termsandConditions"] as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
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
          pendingDiscountAmount:
              overallDiscountAmountInternal + itemWiseDiscount,
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
          poStatus: calculatedFinalAmount > vendorDetails.creditLimit
              ? 'CreditLimit for Approve'
              : 'Pending',
        );

        await poProvider.updatePO(updatedPO);
        return true;
      }

      // ================= CREATE CASE =================
      final newPO = PO(
        purchaseOrderId: '',
        vendorName: selectedVendor,
        vendorId: selectedVendorId,
        location: selectedLocation,
        locationName: selectedLocationName,
        vendorContact: snapshot["vendorContact"],
        items: finalItems,
        totalOrderAmount: calculatedFinalAmount,
        pendingOrderAmount: calculatedFinalAmount,
        pendingDiscountAmount: overallDiscountAmountInternal + itemWiseDiscount,
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
        termsandConditions: (snapshot["termsandConditions"] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        isHoldOrder: calculatedFinalAmount > vendorDetails.creditLimit,
        overallDiscount: hasOverallDiscount
            ? PurchaseOrderDiscount(
                value: overallDiscountValue,
                mode: discountMode.value,
              )
            : null,
        poStatus: calculatedFinalAmount > vendorDetails.creditLimit
            ? 'CreditLimit for Approve'
            : 'Pending for Approve',
      );

      await poProvider.postPO(newPO, vendorDetails);
      return true;
    } catch (e) {
      debugPrint('Failed to save PO: ${e.toString()}');
      return false;
    }
  }
}
