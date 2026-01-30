import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/widgets/numeric_calculator.dart';
import '../column_filter.dart';

class ApprovedPOLogic {
  final PO po;
  final POProvider poProvider;
  final BuildContext context;
  final VoidCallback onUpdated;
  bool updatingFromCalculator = false;
  bool suppressReceivedListener = false;

  // MARK: - State Variables
  final Map<Item, TextEditingController> scanpendingCountController = {};
  final Map<Item, TextEditingController> scaneachQtyControllers = {};
  final Map<Item, TextEditingController> pendingCountController = {};
  final Map<Item, TextEditingController> eachQtyControllers = {};
  final Map<Item, TextEditingController> befTaxControllers = {};
  final Map<Item, TextEditingController> afTaxControllers = {};
  final Map<Item, TextEditingController> receivedQtyController = {};
  final Map<Item, TextEditingController> expiryDateControllers = {};
  final Map<Item, ValueNotifier<Color>> countTextColors = {};
  final Map<Item, ValueNotifier<Color>> qtyTextColors = {};
  final Map<Item, ValueNotifier<String>> receivedQtyValues = {};
  final Map<Item, ValueNotifier<String>> expiryDateValues = {};
  final Map<Item, ValueNotifier<String?>> expiryDateErrors = {};
  final Map<Item, double> originalBefTaxDiscount = {};
  final Map<Item, double> originalAfTaxDiscount = {};
  final Map<Item, double> originalOrderedQty = {};

  final ValueNotifier<String> _invID = ValueNotifier<String>("");
  final ValueNotifier<String> formattedDate = ValueNotifier<String>("");
  final ValueNotifier<String?> invoiceValidationMessage =
      ValueNotifier<String?>(null);
  final ValueNotifier<String?> invoiceDateValidationMessage =
      ValueNotifier<String?>(null);
  final ValueNotifier<Map<Item, String?>> receivedQtyErrors =
      ValueNotifier<Map<Item, String?>>({});
  final ValueNotifier<String?> roundOffErrorNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<bool> isSaving = ValueNotifier(false);

  // Use the round off adjustment value from PO
  final ValueNotifier<double> roundOffAmount;

  // Received summary ValueNotifier

  late final GlobalKey<ScaffoldMessengerState> _dialogMessengerKey;
  final ScrollController _orderedHorizontalController = ScrollController();
  final ScrollController _receivedHorizontalController = ScrollController();
  final ScrollController _orderedLeftVertical = ScrollController();
  final ScrollController _orderedRightVertical = ScrollController();
  final ScrollController _receivedLeftVertical = ScrollController();
  final ScrollController _receivedRightVertical = ScrollController();

  // Constants
  static const double _rowHeight = 30.0;
  static const int _minVisibleRows = 7;
  bool isTablet = false;
  double _poBaseTotalQty = 0.0;
  double _poBaseDiscount = 0.0;
  double _approvedExtraDiscount = 0.0;

  final ValueNotifier<List<String>> sharedColumns =
      ValueNotifier<List<String>>([
        'Item',
        'Count',
        'Qty',
        'UOM',
        'Total',
        'Received',
        'Price',
        'BefTax',
        'AfTax',
        'Expiry',
        'Tax%',
        'Total Price',
        'Final',
      ]);

  final ValueNotifier<Map<String, bool>> sharedColumnVisibility =
      ValueNotifier<Map<String, bool>>({});
  final TextEditingController discountPriceController = TextEditingController();
  final ValueNotifier<double> appliedDiscount = ValueNotifier<double>(0.0);
  final TextEditingController invoiceDateController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isBefTaxDiscount = ValueNotifier<bool>(true);
  final TextEditingController discountInputController = TextEditingController();
  final ValueNotifier<double> receivedDiscountAmount = ValueNotifier<double>(
    0.0,
  );

  Timer? _debounce;

  ApprovedPOLogic({
    required this.po,
    required this.poProvider,
    required this.context,
    required this.onUpdated,
  }) : roundOffAmount = ValueNotifier<double>(po.roundOffAdjustment ?? 0.0) {
    _dialogMessengerKey = GlobalKey<ScaffoldMessengerState>(
      debugLabel: "dialog_messenger_${DateTime.now().microsecondsSinceEpoch}",
    );
  }

  // Getters for constants
  double get rowHeight => _rowHeight;
  int get minVisibleRows => _minVisibleRows;

  GlobalKey<ScaffoldMessengerState> get dialogMessengerKey =>
      _dialogMessengerKey;

  void initialize() {
    normalizePoDiscountsForApproval();
    _initializeControllers();
    _setupScrollSync();

    originalBefTaxDiscount.clear();
    originalAfTaxDiscount.clear();

    _poBaseDiscount = 0.0;

    for (var item in po.items) {
      originalBefTaxDiscount[item] = item.befTaxDiscount ?? 0.0;
      originalAfTaxDiscount[item] = item.afTaxDiscount ?? 0.0;

      _poBaseDiscount += item.pendingDiscountAmount ?? 0.0;
    }

    _approvedExtraDiscount = 0.0;

    // ---------------- ROUND OFF ----------------
    final double ro = po.roundOffAdjustment ?? 0.0;
    roundOffAmount.value = ro;
    discountPriceController.text = ro.toStringAsFixed(2);

    // ---------------- INIT RECEIVED QTY ----------------
    for (var item in po.items) {
      final qty =
          item.poQuantity ??
          item.pendingTotalQuantity ??
          ((item.count ?? 1) * (item.eachQuantity ?? 0));

      item.receivedQuantity = qty;
      receivedQtyController[item]?.text = qty.toStringAsFixed(2);
    }
  }

  bool validateRoundOff() {
    final value = roundOffAmount.value;

    // Example rule: must be between -2 and +2
    if (value < -2 || value > 2) {
      roundOffErrorNotifier.value = "Round off must be between -2 and +2";
      return false;
    }

    roundOffErrorNotifier.value = null;
    return true;
  }

  void _applyDiscountResponseToItems(Map<String, dynamic> data) {
    final List<dynamic> items = data["items"] ?? [];

    for (final res in items) {
      final item = po.items.firstWhere((i) => i.itemId == res["itemId"]);

      item.pendingBefTaxDiscountAmount =
          (res["pendingBefTaxDiscountAmount"] as num?)?.toDouble() ?? 0.0;

      item.pendingAfTaxDiscountAmount =
          (res["pendingAfTaxDiscountAmount"] as num?)?.toDouble() ?? 0.0;

      item.pendingDiscountAmount =
          (res["pendingDiscountAmount"] as num?)?.toDouble() ?? 0.0;

      item.pendingTaxAmount =
          (res["pendingTaxAmount"] as num?)?.toDouble() ?? 0.0;

      item.pendingSgst = (res["pendingSgst"] as num?)?.toDouble() ?? 0.0;

      item.pendingCgst = (res["pendingCgst"] as num?)?.toDouble() ?? 0.0;

      item.pendingIgst = (res["pendingIgst"] as num?)?.toDouble() ?? 0.0;

      item.pendingFinalPrice =
          (res["pendingFinalPrice"] as num?)?.toDouble() ?? 0.0;
    }

    final summary = data["summary"] ?? {};

    po.pendingDiscountAmount =
        (summary["totalDiscountAmount"] as num?)?.toDouble() ?? 0.0;

    po.pendingTaxAmount =
        (summary["totalTaxAmount"] as num?)?.toDouble() ?? 0.0;

    po.totalOrderAmount =
        (summary["totalFinalAmount"] as num?)?.toDouble() ?? 0.0;

    onUpdated();
  }

  Future<void> applyOverallDiscountViaAPI() async {
    final entered = double.tryParse(discountInputController.text.trim()) ?? 0.0;

    if (entered <= 0) {
      showTopError("Enter valid discount amount");
      return;
    }

    _approvedExtraDiscount += entered;

    final double totalDiscount = _poBaseDiscount + _approvedExtraDiscount;

    po.pendingDiscountAmount = totalDiscount;

    final double subTotal = po.items.fold(
      0.0,
      (sum, i) => sum + (i.pendingTotalPrice ?? i.totalPrice ?? 0.0),
    );

    final double tax = po.pendingTaxAmount ?? 0.0;
    final double roundOff = roundOffAmount.value;

    po.totalOrderAmount = subTotal - totalDiscount + tax + roundOff;
    po.pendingOrderAmount = po.totalOrderAmount;

    discountInputController.clear();

    onUpdated();

    showTopMessage(
      "Approved Discount Applied: ₹${_approvedExtraDiscount.toStringAsFixed(2)}",
      color: Colors.green,
    );
  }

  double get orderedSubTotal {
    return po.items.fold(0.0, (sum, i) => sum + (i.totalPrice ?? 0.0));
  }

  double get orderedDiscount {
    return _poBaseDiscount; // original PO discount only
  }

  double get orderedFinalAmount {
    return orderedSubTotal - orderedDiscount;
  }

  double get receivedSubTotal {
    return po.items.fold(
      0.0,
      (sum, i) => sum + (i.pendingTotalPrice ?? i.totalPrice ?? 0.0),
    );
  }

  double get receivedFinalAmount {
    final discount = po.pendingDiscountAmount ?? 0.0;
    final tax = po.pendingTaxAmount ?? 0.0;
    final roundOff = roundOffAmount.value;
    return receivedSubTotal - discount + tax + roundOff;
  }

  void recalculateFinalAmountAfterDiscount() {
    final double subTotal = po.items.fold(
      0.0,
      (sum, i) => sum + (i.totalPrice ?? 0.0),
    );

    final double discount = po.pendingDiscountAmount ?? 0.0;
    final double tax = po.pendingTaxAmount ?? 0.0;
    final double roundOff = roundOffAmount.value;

    po.totalOrderAmount = subTotal - discount + tax + roundOff;
    po.pendingOrderAmount = po.totalOrderAmount;

    debugPrint("✅ FINAL AMOUNT RECALCULATED: ${po.totalOrderAmount}");
  }

  Future<void> clearDiscountFromAllItems() async {
    try {
      for (var item in po.items) {
        item.befTaxDiscount = originalBefTaxDiscount[item] ?? 0.0;
        item.afTaxDiscount = originalAfTaxDiscount[item] ?? 0.0;
      }

      final List<Map<String, dynamic>> itemsPayload = po.items
          .where((item) => (item.receivedQuantity ?? 0) > 0)
          .map((item) {
            return {
              "itemId": item.itemId,
              "receivedQuantity": item.receivedQuantity,
              "grnPrice": item.newPrice,
              "befTaxDiscount": originalBefTaxDiscount[item] ?? 0.0,
              "afTaxDiscount": originalAfTaxDiscount[item] ?? 0.0,
              "taxPercentage": item.taxPercentage ?? 0.0,
              "taxType": item.taxType ?? "cgst_sgst",
            };
          })
          .toList();

      if (itemsPayload.isEmpty) {
        showTopError("No received items to clear discount");
        return;
      }

      final response = await poProvider.calculateGrnOverallDiscount(
        items: itemsPayload,
        discountAmount: _poBaseDiscount,
        discountType: "after",
      );

      if (response["success"] != true) {
        showTopError("Failed to clear approved discount");
        return;
      }

      _applyDiscountResponseToItems(response);

      _approvedExtraDiscount = 0.0;
      po.pendingDiscountAmount = _poBaseDiscount;

      discountInputController.clear();

      showTopMessage(
        "Approved discount cleared (PO discount retained)",
        color: Colors.blueAccent,
      );
    } catch (e) {
      showTopError("Error clearing approved discount: $e");
    }
  }

  void updateTabletStatus(double screenWidth) {
    isTablet = screenWidth > 600;
    final allColumns = Map<String, bool>.fromEntries(
      sharedColumns.value.map((column) => MapEntry(column, true)),
    );

    // Update tablet-specific columns
    allColumns['Price'] = isTablet;
    allColumns['BefTax'] = isTablet;
    allColumns['AfTax'] = isTablet;
    allColumns['Tax%'] = isTablet;
    allColumns['Total Price'] = isTablet;
    allColumns['Final'] = isTablet;

    sharedColumnVisibility.value = allColumns;
  }

  void showTopMessage(String message, {Color color = Colors.red}) {
    _dialogMessengerKey.currentState?.clearSnackBars();
    _dialogMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 12, right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showTopError(String message) {
    showTopMessage(message, color: Colors.red);
  }

  bool validateForm() {
    bool isValid = true;

    if (invoiceNumberController.text.trim().isEmpty) {
      invoiceValidationMessage.value = 'error';
      showTopError("Invoice number is required");
      isValid = false;
    } else {
      invoiceValidationMessage.value = null;
    }

    if (invoiceDateController.text.trim().isEmpty) {
      invoiceDateValidationMessage.value = 'error';
      showTopError("Invoice date is required");
      isValid = false;
    } else {
      invoiceDateValidationMessage.value = null;
    }

    return isValid;
  }

  void _setupScrollSync() {
    _orderedLeftVertical.addListener(() {
      if (_orderedRightVertical.offset != _orderedLeftVertical.offset) {
        _orderedRightVertical.jumpTo(_orderedLeftVertical.offset);
      }
    });

    _orderedRightVertical.addListener(() {
      if (_orderedLeftVertical.offset != _orderedRightVertical.offset) {
        _orderedLeftVertical.jumpTo(_orderedRightVertical.offset);
      }
    });

    _receivedLeftVertical.addListener(() {
      if (_receivedRightVertical.offset != _receivedLeftVertical.offset) {
        _receivedRightVertical.jumpTo(_receivedLeftVertical.offset);
      }
    });

    _receivedRightVertical.addListener(() {
      if (_receivedLeftVertical.offset != _receivedRightVertical.offset) {
        _receivedLeftVertical.jumpTo(_receivedRightVertical.offset);
      }
    });

    _orderedRightVertical.addListener(() {
      if (_receivedRightVertical.offset != _orderedRightVertical.offset) {
        _receivedRightVertical.jumpTo(_orderedRightVertical.offset);
      }
    });

    _receivedRightVertical.addListener(() {
      if (_orderedRightVertical.offset != _receivedRightVertical.offset) {
        _orderedRightVertical.jumpTo(_receivedRightVertical.offset);
      }
    });

    _orderedLeftVertical.addListener(() {
      if (_receivedLeftVertical.offset != _orderedLeftVertical.offset) {
        _receivedLeftVertical.jumpTo(_orderedLeftVertical.offset);
      }
    });

    _receivedLeftVertical.addListener(() {
      if (_orderedLeftVertical.offset != _receivedLeftVertical.offset) {
        _orderedLeftVertical.jumpTo(_receivedLeftVertical.offset);
      }
    });

    // ORDERED ↔ RECEIVED — HORIZONTAL SYNC
    _orderedHorizontalController.addListener(() {
      if (_receivedHorizontalController.offset !=
          _orderedHorizontalController.offset) {
        _receivedHorizontalController.jumpTo(
          _orderedHorizontalController.offset,
        );
      }
    });

    _receivedHorizontalController.addListener(() {
      if (_orderedHorizontalController.offset !=
          _receivedHorizontalController.offset) {
        _orderedHorizontalController.jumpTo(
          _receivedHorizontalController.offset,
        );
      }
    });
  }

  void _initializeControllers() {
    // Clear existing
    receivedQtyController.clear();
    pendingCountController.clear();
    eachQtyControllers.clear();
    befTaxControllers.clear();
    afTaxControllers.clear();
    expiryDateControllers.clear();
    expiryDateErrors.clear();

    for (var item in po.items) {
      item.pendingTotalQuantity =
          (item.pendingCount ?? item.count ?? 0) *
          (item.pendingQuantity ?? item.eachQuantity ?? 0);

      // ---------------- Expiry Date ----------------
      String formattedExpiry = '';

      // show expiry ONLY if nothing is received yet
      if ((item.receivedQuantity ?? 0) == 0) {
        formattedExpiry = '';
      }

      expiryDateControllers[item] = TextEditingController(
        text: formattedExpiry,
      );

      expiryDateControllers[item] = TextEditingController(
        text: formattedExpiry,
      );

      expiryDateErrors[item] = ValueNotifier<String?>(null);

      // ---------------- Default Received Qty ----------------
      double defaultReceived = 0.0;

      // Priority: received > pending total > ordered
      if ((item.receivedQuantity ?? 0) > 0) {
        defaultReceived = item.receivedQuantity ?? 0.0;
      } else if ((item.pendingTotalQuantity ?? 0) > 0) {
        defaultReceived = item.pendingTotalQuantity ?? 0.0;
      } else if ((item.poQuantity ?? 0) > 0) {
        defaultReceived = item.poQuantity ?? 0.0;
      }

      receivedQtyController[item] = TextEditingController(
        text: defaultReceived.toStringAsFixed(2),
      );

      // ---------------- Pending Count ----------------
      pendingCountController[item] = TextEditingController(
        text: (item.pendingCount ?? item.count ?? 0).toStringAsFixed(2),
      );

      // ---------------- Pending Each Qty ----------------
      eachQtyControllers[item] = TextEditingController(
        text: (item.pendingQuantity ?? item.eachQuantity ?? 0).toStringAsFixed(
          2,
        ),
      );

      // ---------------- Before Tax Discount ----------------
      befTaxControllers[item] = TextEditingController(
        text: (item.befTaxDiscount ?? 0.0).toStringAsFixed(2),
      );

      // ---------------- After Tax Discount ----------------
      afTaxControllers[item] = TextEditingController(
        text: (item.pendingAfTaxDiscountAmount ?? item.afTaxDiscountAmount ?? 0)
            .toStringAsFixed(2),
      );
    }
  }

  String formatQty(double value) {
    if (value == 0) return "0.00";
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  void updateQtyWhenReceivedChanges(Item item) {
    final received = item.receivedQuantity ?? 0.0;
    final double originalEach =
        item.pendingQuantity ?? item.poQuantity ?? item.eachQuantity ?? 0.0;
    final double originalCount = item.pendingCount ?? item.count ?? 1.0;
    item.eachQuantity = originalEach;
    item.count = originalCount;
    final totalOrdered = originalEach * originalCount;
  }

  void showNumericCalculator({
    required TextEditingController? controller,
    required String varianceName,
    double? initialValue,
    required VoidCallback onValueSelected,
  }) {
    suppressReceivedListener = true;

    showDialog(
      context: context,
      builder: (context) => NumericCalculator(
        varianceName: varianceName,
        initialValue:
            initialValue ?? double.tryParse(controller?.text ?? '') ?? 0.0,
        controller: null,
        onValueSelected: (value) {
          if (controller == null) return;

          final item = po.items.firstWhere(
            (i) => receivedQtyController[i] == controller,
            orElse: () => po.items.first,
          );

          final double orderedQty = (item.poQuantity ?? 0) > 0
              ? item.poQuantity!
              : ((item.count ?? 1.0) * (item.eachQuantity ?? 0.0));

          if (value > orderedQty) {
            receivedQtyErrors.value = {
              ...receivedQtyErrors.value,
              item: "Cannot exceed ordered qty ($orderedQty)",
            };
            showTopError("Cannot exceed ordered qty ($orderedQty)");
            return;
          }

          final newMap = Map<Item, String?>.from(receivedQtyErrors.value);
          newMap.remove(item);
          receivedQtyErrors.value = newMap;

          final formatted = value.toStringAsFixed(2);
          item.receivedQuantity = value;
          controller.text = formatted;

          updateQtyWhenReceivedChanges(item);

          onValueSelected();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            suppressReceivedListener = false;
          });
        },
      ),
    ).then((_) {
      suppressReceivedListener = false;
    });
  }

  bool validateExpiryDatesBasedOnReceived(List<Item> items) {
    bool isValid = true;

    for (var item in items) {
      final received =
          double.tryParse(receivedQtyController[item]?.text ?? '0') ?? 0.0;
      final expiry = expiryDateControllers[item]?.text.trim() ?? '';

      expiryDateErrors.putIfAbsent(item, () => ValueNotifier<String?>(null));

      if (received > 0 && expiry.isEmpty) {
        expiryDateErrors[item]!.value = "Required";
        isValid = false;
      } else {
        expiryDateErrors[item]!.value = null;
      }
    }

    return isValid;
  }

  void updateCountAndQuantityFromReceived(Item item) {
    final receivedQty = item.receivedQuantity ?? 0.0;

    final double poQuantity =
        item.poQuantity ?? ((item.count ?? 1.0) * (item.eachQuantity ?? 0.0));

    final int pendingCount = (item.pendingCount ?? item.count ?? 1).toInt();

    if (receivedQty <= 0 || poQuantity <= 0 || pendingCount <= 0) {
      item.count = 0.0;
      item.eachQuantity = 0.0;
      return;
    }

    if (pendingCount > 1) {
      final expectedQuantityPerCount = poQuantity / pendingCount;

      final fullPackages = (receivedQty / expectedQuantityPerCount).floor();
      final remainder = receivedQty % expectedQuantityPerCount;

      item.count = fullPackages.toDouble();
      item.eachQuantity = expectedQuantityPerCount;

      if (remainder > 0) {
        item.count = (item.count ?? 0.0) + 1.0;
        item.eachQuantity = remainder;
      }
    } else {
      item.count = 1.0;
      item.eachQuantity = receivedQty;
    }
  }

  void updateRoundOff(String value) {
    double roundOffValue = double.tryParse(value) ?? 0.0;

    roundOffAmount.value = roundOffValue;
    discountPriceController.text = value;

    recalculateFinalAmountAfterDiscount(); // ✅ THIS IS THE KEY

    onUpdated(); // ✅ forces UI rebuild

    debugPrint('Round off updated: $roundOffValue');
  }

  void showColumnFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ColumnFilterDialog(
        columns: sharedColumns.value,
        columnVisibility: sharedColumnVisibility.value,
        onApply: (newColumns, newVisibility) {
          sharedColumns.value = List<String>.from(newColumns);
          sharedColumnVisibility.value = Map<String, bool>.from(newVisibility);
        },
      ),
    );
  }

  Future<void> selectInvoiceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              surface: Colors.white,
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      invoiceDateController.text =
          '${picked.day.toString().padLeft(2, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.year}';
    }
  }

  Future<void> selectExpiryDate(BuildContext context, Item item) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              surface: Colors.white,
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.year}';

      expiryDateControllers[item]?.text = formatted;

      expiryDateErrors[item]?.value = null;
    }
  }

  void showDiscountCalculator() {
    showNumericCalculator(
      controller: discountPriceController,
      varianceName: 'Enter Discount',
      onValueSelected: () {
        appliedDiscount.value =
            double.tryParse(discountPriceController.text) ?? 0.0;
      },
    );
  }

  void revertPO(BuildContext context) {
    _confirmRevertToPo(context);
  }

  void _confirmRevertToPo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Confirm Revert',
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            'Are you sure you want to revert PO ${po.randomId} to Pending status?',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 74, 122, 227)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await poProvider.changePoStatusToPending(po.purchaseOrderId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showTopError('PO reverted to Pending successfully');
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showTopError('Failed to revert PO: $e');
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> convertPoToGRN(BuildContext context) async {
    if (isSaving.value) return;

    final poProvider = Provider.of<POProvider>(context, listen: false);
    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    try {
      isSaving.value = true;

      if (!validateForm()) {
        isSaving.value = false;
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await poProvider.updatePO(
        po.copyWith(
          items: po.items.map((item) {
            final double resolvedPoQuantity =
                (item.poQuantity != null && item.poQuantity! > 0)
                ? item.poQuantity!
                : ((item.count ?? 1) * (item.eachQuantity ?? 0));

            return item.copyWith(poQuantity: resolvedPoQuantity);
          }).toList(),
        ),
      );

      final double overallDiscount =
          po.pendingDiscountAmount ?? po.overallDiscountValue ?? 0.0;

      Map<String, dynamic>? discountResult;

      if (overallDiscount > 0) {
        discountResult = await poProvider.calculateGrnOverallDiscount(
          items: po.items.map((item) {
            return {
              "itemId": item.itemId,
              "receivedQuantity": item.receivedQuantity ?? item.quantity,
              "grnPrice": item.newPrice,
              "befTaxDiscount": 0.0,
              "afTaxDiscount": 0.0,
              "taxPercentage": item.taxPercentage ?? 0.0,
              "taxType": item.taxType ?? "cgst_sgst",
            };
          }).toList(),
          discountAmount: overallDiscount,
          discountType: "after",
        );
      }

      final List<Item> receivedItems = po.items.map((item) {
        final calculatedItem = discountResult?["items"]?.firstWhere(
          (e) => e["itemId"] == item.itemId,
          orElse: () => null,
        );

        return item.copyWith(
          receivedQuantity: item.receivedQuantity ?? item.quantity,
          befTaxDiscount: calculatedItem?["befTaxDiscount"] ?? 0.0,
          afTaxDiscount: calculatedItem?["afTaxDiscount"] ?? 0.0,
          befTaxDiscountType: "percentage",
          afTaxDiscountType: "percentage",
        );
      }).toList();

      final DateTime parsedInvoiceDate = DateFormat(
        'dd-MM-yyyy',
      ).parse(invoiceDateController.text.trim());

      final response = await poProvider.updatePoDetails(
        po.purchaseOrderId,
        receivedItems,
        invoiceNumberController.text.trim(),
        parsedInvoiceDate,
        overallDiscount,
        roundOffAdjustment: roundOffAmount.value,
      );

      if (response["grnCreated"] != true) {
        throw Exception("GRN creation failed");
      }

      await poProvider.convertPoToGrn(
        context,
        po.purchaseOrderId,
        invoiceNumberController.text.trim(),
        overallDiscount,
        response["grnId"],
        roundOffAdjustment: roundOffAmount.value,
      );

      await poProvider.applyCurrentFilters();
      await grnProvider.fetchFilteredGRNs();

      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e, stack) {
      debugPrint("❌ Convert PO to GRN failed: $e");
      debugPrintStack(stackTrace: stack);

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to convert PO to GRN"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isSaving.value = false;
    }
  }

  void normalizePoDiscountsForApproval() {
    for (var item in po.items) {
      item.befTaxDiscount = 0.0;
      item.afTaxDiscount = 0.0;

      item.befTaxDiscountAmount = 0.0;
      item.afTaxDiscountAmount = 0.0;
      item.discountAmount = 0.0;
    }
    _poBaseDiscount = po.pendingDiscountAmount ?? 0.0;
    _approvedExtraDiscount = 0.0;
  }

  void resetPoDiscountsForApproval() {
    for (var item in po.items) {
      item.befTaxDiscount = 0.0;
      item.afTaxDiscount = 0.0;
      item.befTaxDiscountAmount = 0.0;
      item.afTaxDiscountAmount = 0.0;
      item.discountAmount = 0.0;

      item.befTaxDiscountType = 'percentage';
      item.afTaxDiscountType = 'percentage';
    }
  }

  double getColumnWidth(String column) {
    switch (column) {
      case 'Item':
        return 130.0;
      case 'UOM':
        return 45.0;
      case 'Count':
        return 55.0;
      case 'Qty':
        return 55.0;
      case 'Total':
        return 55.0;
      case 'Received':
        return 60.0;
      case 'Price':
        return 70.0;
      case 'BefTax':
        return 70.0;
      case 'AfTax':
        return 70.0;
      case 'Expiry':
        return 90.0;
      case 'Tax%':
        return 60.0;
      case 'Total Price':
        return 75.0;
      case 'Final':
        return 75.0;
      default:
        return 70.0;
    }
  }

  double calculateTotalWidth(
    List<String> columns,
    Map<String, bool> visibility, {
    required bool isOrdered,
  }) {
    double totalWidth = 0.0;

    for (var column in columns) {
      if (column == 'Item') continue;
      final isVisible = visibility[column] ?? true;
      if (!isVisible) continue;
      if (isOrdered && column == 'Received') continue;
      if (!isOrdered && column == 'Total') continue;

      totalWidth += getColumnWidth(column);
    }

    return totalWidth;
  }

  String getOrderedItemValue(Item item, String column) {
    switch (column) {
      case 'Count':
        return item.pendingCount?.toStringAsFixed(2) ?? '0.00';
      case 'Qty':
        return item.pendingQuantity?.toStringAsFixed(2) ?? '0.00';
      case 'Total':
        return item.pendingTotalQuantity?.toStringAsFixed(2) ?? '0.00';
      case 'Price':
        return item.newPrice?.toStringAsFixed(2) ?? '0.00';
      case 'BefTax':
        return item.befTaxDiscount?.toStringAsFixed(2) ?? '0.00';
      case 'AfTax':
        return item.afTaxDiscount?.toStringAsFixed(2) ?? '0.00';
      case 'Tax%':
        return item.taxPercentage?.toStringAsFixed(2) ?? '0.00';
      case 'Total Price':
        return item.pendingTotalPrice?.toStringAsFixed(2) ?? '0.00';
      case 'Final':
        return item.pendingFinalPrice?.toStringAsFixed(2) ?? '0.00';
      default:
        return '';
    }
  }

  // Getters for table widget
  ScrollController get orderedHorizontalController =>
      _orderedHorizontalController;
  ScrollController get receivedHorizontalController =>
      _receivedHorizontalController;
  ScrollController get orderedLeftVertical => _orderedLeftVertical;
  ScrollController get orderedRightVertical => _orderedRightVertical;
  ScrollController get receivedLeftVertical => _receivedLeftVertical;
  ScrollController get receivedRightVertical => _receivedRightVertical;

  // Getters for controllers and value notifiers
  Map<Item, TextEditingController> get receivedQtyControllers =>
      receivedQtyController;
  Map<Item, TextEditingController> get expiryDateControllersMap =>
      expiryDateControllers;
  Map<Item, TextEditingController> get befTaxControllersMap =>
      befTaxControllers;
  Map<Item, TextEditingController> get afTaxControllersMap => afTaxControllers;
  Map<Item, ValueNotifier<String>> get expiryDateValuesMap => expiryDateValues;
  Map<Item, ValueNotifier<String?>> get expiryDateErrorsMap => expiryDateErrors;
  ValueNotifier<Map<Item, String?>> get receivedQtyErrorsValue =>
      receivedQtyErrors;

  void dispose() {
    _orderedHorizontalController.dispose();
    _receivedHorizontalController.dispose();
    _orderedLeftVertical.dispose();
    _orderedRightVertical.dispose();
    _receivedLeftVertical.dispose();
    _receivedRightVertical.dispose();
    discountInputController.dispose();
    roundOffAmount.dispose();
    appliedDiscount.dispose();
    roundOffErrorNotifier.dispose();
    isSaving.dispose();

    for (var controller in receivedQtyController.values) {
      controller.dispose();
    }
    for (var controller in expiryDateControllers.values) {
      controller.dispose();
    }
    for (var controller in befTaxControllers.values) {
      controller.dispose();
    }
    for (var controller in afTaxControllers.values) {
      controller.dispose();
    }
    for (var controller in scanpendingCountController.values) {
      controller.dispose();
    }
    for (var controller in scaneachQtyControllers.values) {
      controller.dispose();
    }
    for (var controller in pendingCountController.values) {
      controller.dispose();
    }
    for (var controller in eachQtyControllers.values) {
      controller.dispose();
    }
    discountPriceController.dispose();
    invoiceDateController.dispose();
    invoiceNumberController.dispose();
    _debounce?.cancel();
    isBefTaxDiscount.dispose();
    receivedDiscountAmount.dispose();
  }
}
