import '../models/po/discount_model.dart';
import 'po_notifier_state.dart';

mixin PONotifierDiscountMixin on PurchaseOrderNotifierState {
  bool get hasItemWiseDiscount {
    return poItems.any(
      (item) =>
          (item.befTaxDiscountAmount ?? 0) > 0 ||
          (item.afTaxDiscountAmount ?? 0) > 0,
    );
  }

  Future<void> applyOverallDiscountToAllItemsAfTax(
    double discountValue,
    DiscountMode mode,
  ) async {
    if (disposed) return;
    isOverallDiscountActive = true;
    discountMode.value = mode;
    overallDiscountValueInternal = discountValue;
    overallDiscountController.text = discountValue.toStringAsFixed(2);
    await recalculateTotalsFromBackend();
  }

  void updateAfTaxForAllItems(double discountValue, DiscountMode mode) {
    if (disposed) return;
    for (var item in poItems) {
      item.afTaxDiscount = discountValue;

      item.afTaxDiscountType = mode == DiscountMode.percentage
          ? "percentage"
          : "amount";
    }
    safeCalculateTotals();
  }
}