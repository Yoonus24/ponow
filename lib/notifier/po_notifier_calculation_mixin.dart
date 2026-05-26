import 'po_notifier_state.dart';

mixin PONotifierCalculationMixin on PurchaseOrderNotifierState {
  @override
  void calculateTotals({bool fromEditLoad = false}) {
    if (editingPOInternal != null && !isEditTotalsInitialized) {
      recalculateFromLoadedPO(notify: false);
    }

    if (disposed) return;

    double subTotalAccumulator = 0.0;
    double totalTaxAccumulator = 0.0;
    double totalBefTaxDiscount = 0.0;
    double totalAfTaxDiscount = 0.0;
    double totalFinalAccumulator = 0.0;

    for (final item in poItems) {
      final double itemTotal = item.totalPrice ?? item.pendingTotalPrice ?? 0.0;
      final double itemFinal = item.finalPrice ?? item.pendingFinalPrice ?? 0.0;

      subTotalAccumulator += itemTotal;
      totalFinalAccumulator += itemFinal;

      totalTaxAccumulator += item.taxAmount ?? item.pendingTaxAmount ?? 0.0;
      totalBefTaxDiscount += item.befTaxDiscountAmount ?? 0.0;
      totalAfTaxDiscount += item.afTaxDiscountAmount ?? 0.0;
    }

    bool hasOverallDiscount = isOverallDiscountActive;

    if (hasOverallDiscount) {
      itemWiseDiscountInternal = 0.0;
      overallDiscountAmountInternal = totalAfTaxDiscount;
    } else {
      itemWiseDiscountInternal = totalBefTaxDiscount + totalAfTaxDiscount;
      overallDiscountAmountInternal = 0.0;
    }

    subTotalInternal = subTotalAccumulator;
    pendingTaxAmount = totalTaxAccumulator;

    final double roundOff = double.tryParse(roundOffController.text) ?? 0.0;

    calculatedFinalAmountInternal =
        totalFinalAccumulator + totalFreightAmount + totalFreightTaxAmount + roundOff;

    totalOrderAmount = calculatedFinalAmountInternal;
    pendingOrderAmount = calculatedFinalAmountInternal;

    pendingDiscountAmount = itemWiseDiscountInternal + overallDiscountAmountInternal;

    safeNotify();
  }

  @override
  void recalculateFromLoadedPO({bool notify = false}) {
    double subtotalAccumulator = 0.0;
    double totalTaxAccumulator = 0.0;
    double totalDiscountAccumulator = 0.0;
    double finalTotalAccumulator = 0.0;

    for (var item in poItems) {
      final base = item.pendingTotalPrice ?? 0.0;
      final finalPrice = item.pendingFinalPrice ?? 0.0;
      final tax = item.pendingTaxAmount ?? 0.0;
      final discount = item.pendingDiscountAmount ?? 0.0;

      subtotalAccumulator += base;
      totalTaxAccumulator += tax;
      totalDiscountAccumulator += discount;
      finalTotalAccumulator += finalPrice;
    }

    final roundOff = double.tryParse(roundOffController.text) ?? 0.0;

    finalTotalAccumulator =
        finalTotalAccumulator + totalFreightAmount + totalFreightTaxAmount + roundOff;

    subTotalInternal = subtotalAccumulator;
    pendingTaxAmount = totalTaxAccumulator;
    pendingDiscountAmount = totalDiscountAccumulator;

    calculatedFinalAmountInternal = finalTotalAccumulator;
    totalOrderAmount = finalTotalAccumulator;
    pendingOrderAmount = finalTotalAccumulator;
    if (notify) safeNotify();
  }

  @override
  Future<void> recalculateTotalsFromBackend() async {
    final result = await poProvider.calculatePOTotals(
      items: poItems.map((e) => e.toJson()).toList(),
      freights: freights.map((e) => e.toJson()).toList(),
    );

    subTotalInternal = result["subTotal"];
    totalFreightAmount = result["totalFreightAmount"];
    totalFreightTaxAmount = result["totalFreightTaxAmount"];
    final double roundOff = double.tryParse(roundOffController.text) ?? 0.0;
    calculatedFinalAmountInternal = result["finalAmount"] + roundOff;
    totalOrderAmount = calculatedFinalAmountInternal;
    pendingOrderAmount = calculatedFinalAmountInternal;
    safeNotify();
  }
}