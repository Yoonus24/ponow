import 'package:purchaseorders2/models/po/po_item.dart';

import '../models/po/freight.dart';
import '../models/po/po.dart';
import '../models/po/discount_model.dart';
import 'po_notifier_state.dart';

mixin PONotifierFreightMixin on PurchaseOrderNotifierState {
  void setEditingPO(PO? po, {bool notify = true}) {
    if (disposed) return;

    editingPOInternal = po;
    isEditTotalsInitialized = false;

    if (po != null) {
      poItems = List<Item>.from(po.items);
      freights = List<FreightData>.from(po.freights ?? []);
      totalFreightAmount = po.totalFreightAmount ?? 0.0;
      totalFreightTaxAmount = po.totalFreightTaxAmount ?? 0.0;

      roundOffAdjustment = po.roundOffAdjustment ?? 0.0;
      roundOffController.text = roundOffAdjustment.toStringAsFixed(2);

      double totalDiscount = 0.0;
      double totalBefore = 0.0;

      for (final item in po.items) {
        final double base = item.pendingTotalPrice ?? item.totalPrice ?? 0.0;
        final double finalPrice = item.pendingFinalPrice ?? item.finalPrice ?? 0.0;

        totalBefore += base;
        totalDiscount += (base - finalPrice);
      }

      if (totalDiscount > 0) {       
        isOverallDiscountActive = true;
        overallDiscountValueInternal = totalDiscount;
        discountMode.value = DiscountMode.amount;
        overallDiscountController.text = overallDiscountValueInternal.toStringAsFixed(2);
      } else {
        isOverallDiscountActive = false;
        overallDiscountValueInternal = 0.0;
        overallDiscountController.text = '0';
        discountMode.value = DiscountMode.none;
      }

      if (!isEditTotalsInitialized) {
        recalculateFromLoadedPO(notify: notify);
        isEditTotalsInitialized = true;
      }
    }
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
    safeNotify();
  }

  void clearFreights() {
    freights.clear();
    totalFreightAmount = 0.0;
    totalFreightTaxAmount = 0.0;
    safeNotify();
  }

  Future<void> addFreight(FreightData freight) async {
    freights.add(freight);
    await recalculateTotalsFromBackend();
  }
}