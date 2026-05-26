import 'package:flutter/material.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'po_notifier_state.dart';

mixin PONotifierHelperMixin on PurchaseOrderNotifierState {
  @override
  void safeNotify() {
    if (disposed) return;
    notifyListeners();
  }

  @override
  void safeCalculateTotals() {
    if (disposed) return;
    calculateTotals();
  }

  void throwUserFriendlyError(Object error, {String? fallbackMessage}) {
    debugPrint("ERROR: ${error.toString()}");

    final errorMessage = error.toString().replaceFirst('Exception: ', '');

    throw Exception(
      errorMessage.isNotEmpty
          ? errorMessage
          : (fallbackMessage ?? 'Something went wrong'),
    );
  }

  String getControllerTextSafely(TextEditingController controller) {
    try {
      return controller.text;
    } catch (e) {
      return '';
    }
  }

  void safeControllerAction(void Function() action) {
    if (disposed) return;

    try {
      action();
    } catch (e) {
      throwUserFriendlyError(e);
    }
  }

  void setLocationFocus(bool focused) {
    if (isLocationFocusedInternal != focused) {
      isLocationFocusedInternal = focused;
      notifyListeners();
    }
  }

  void setLocation({required String location, String? locationName}) {
    if (disposed) return;
    selectedLocation = location;
    selectedLocationName = locationName ?? '';
    safeNotify();
  }

  void clearLocation() {
    if (disposed) return;
    selectedLocation = '';
    selectedLocationName = '';
    safeNotify();
  }

  Future<void> selectDate(BuildContext context) async {
    if (disposed) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ServerTimeService.now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      expectedDeliveryDateController.text = "${picked.toLocal()}".split(' ')[0];
      safeNotify();
    }
  }

  Future<void> selectOrderedDate(BuildContext context) async {
    if (disposed) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ServerTimeService.now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      orderedDateController.text = "${picked.toLocal()}".split(' ')[0];
      safeNotify();
    }
  }
}