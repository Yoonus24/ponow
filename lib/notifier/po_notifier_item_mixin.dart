import 'package:flutter/material.dart';
import '../models/po/po_item.dart';
import '../models/po/vendorpurchasemodel.dart';
import 'po_notifier_state.dart';

mixin PONotifierItemMixin on PurchaseOrderNotifierState {
  Future<void> fetchItems(String query) async {
    if (disposed) return;
    try {
      await poProvider.searchPurchaseItems(query: query);
      purchaseItems = poProvider.purchaseItems;

      filteredItems = purchaseItems
          .map((item) => item.itemName)
          .where((name) => name.isNotEmpty)
          .take(50)
          .toList();

      safeNotify();
    } catch (e) {
      debugPrint("ERROR: ${e.toString()}");
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception(errorMessage.isNotEmpty ? errorMessage : 'Something went wrong');
    }
  }

  void selectEditItem(Item item) {
    if (disposed) return;
    editItemInternal = item;
    safeNotify();
  }

  void clearEditItem() {
    if (disposed) return;
    editItemInternal = null;
    safeNotify();
  }

  void setEditItem(Item item) {
    if (disposed) return;
    editItemInternal = item;
    safeNotify();
  }

  void updateItemAtIndex(int index, Item updatedItem) {
    if (disposed || index >= poItems.length) return;
    poItems[index] = updatedItem;
    safeNotify();
  }

  void clearSelectedItem() {
    if (disposed) return;
    selectedItemInternal = null;
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
    poItems.remove(item);

    if (poItems.isEmpty) {
      totalFreightAmount = 0;
      totalFreightTaxAmount = 0;
    }
    calculateTotals();
  }

  void setSelectedItem(String itemName) {
    if (disposed) return;

    try {
      final normalizedName = itemName.trim().toLowerCase();

      final foundItem = purchaseItems.firstWhere(
        (item) => item.itemName.trim().toLowerCase() == normalizedName,
      );

      selectedPurchaseItem = foundItem;
      selectedItemInternal = foundItem;

      try {
        itemController.text = foundItem.itemName;
        uomController.text = foundItem.uom.toString();
        existingPriceController.text = foundItem.purchasePrice.toStringAsFixed(2);
        newPriceController.text = foundItem.purchasePrice.toStringAsFixed(2);
        taxPercentageController.text = foundItem.purchasetaxName.toStringAsFixed(2);
        befTaxDiscountController.text = '0';
        afTaxDiscountController.text = '0';
      } catch (e) {
        debugPrint("ERROR: ${e.toString()}");
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        throw Exception(errorMessage.isNotEmpty ? errorMessage : 'Something went wrong');
      }

      debugPrint("=========== SELECTED ITEM DEBUG ===========");
      debugPrint("Item Name: ${foundItem.itemName}");
      debugPrint("Item Code: ${foundItem.itemCode}");
      debugPrint("Purchase Item ID: ${foundItem.purchaseItemId}");
      debugPrint("Random ID: ${foundItem.randomId}");
      debugPrint("===========================================");

      safeNotify();
    } catch (e) {
      debugPrint("ERROR: ${e.toString()}");
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception(errorMessage.isNotEmpty ? errorMessage : "Item not found: $itemName");
    }
  }

  void updateItemDetailsFromCache(PurchaseItem item) {
    if (disposed) return;
    selectedPurchaseItem = item;
    selectedItemInternal = item;

    try {
      itemController.text = item.itemName;
      existingPriceController.text = item.purchasePrice.toStringAsFixed(2);
      newPriceController.text = item.purchasePrice.toStringAsFixed(2);
      taxPercentageController.text = item.purchasetaxName.toStringAsFixed(2);
      uomController.text = item.uom;
      befTaxDiscountController.text = '0';
      afTaxDiscountController.text = '0';
    } catch (e) {
      debugPrint("ERROR: ${e.toString()}");
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception(errorMessage.isNotEmpty ? errorMessage : 'Something went wrong');
    }

    updateVariance();

    final index = purchaseItems.indexWhere(
      (e) => e.purchaseItemId == item.purchaseItemId,
    );

    if (index == -1) {
      purchaseItems.add(item);
    }

    debugPrint("=========== CACHE ITEM DEBUG ===========");
    debugPrint("Item Name: ${item.itemName}");
    debugPrint("Purchase Item ID: ${item.purchaseItemId}");
    debugPrint("Random ID: ${item.randomId}");
    debugPrint("=======================================");

    safeNotify();
  }

  void clearAllItems() {
    if (disposed) return;
    poItems.clear();
    totalOrderAmount = 0.0;
    safeNotify();
  }

  void addItem(Item item) {
    if (disposed) return;
    poItems.add(item);
    calculateTotals();
    safeNotify();
  }

  void resetItemFields() {
    if (disposed) return;

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
    countController.value = const TextEditingValue(text: '1');

    safeNotify();
  }
}