import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/core/utils/app_snackbar.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/models/po/po_item.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'package:purchaseorders2/widgets/numeric_calculator.dart';
import '../column_filter.dart';

class ApprovedPOLogic {
  final PO po;
  final POProvider poProvider;
  final BuildContext context;
  final VoidCallback onUpdated;
  bool updatingFromCalculator = false;
  bool suppressReceivedListener = false;
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
  final Map<Item, TextEditingController> priceControllersMap = {};
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
  final ValueNotifier<bool> isReverting = ValueNotifier(false);
  final ValueNotifier<double> roundOffAmount;
  late final GlobalKey<ScaffoldMessengerState> _dialogMessengerKey;
  final ScrollController _orderedHorizontalController = ScrollController();
  final ScrollController _receivedHorizontalController = ScrollController();
  final ScrollController _orderedLeftVertical = ScrollController();
  final ScrollController _orderedRightVertical = ScrollController();
  final ScrollController _receivedLeftVertical = ScrollController();
  final ScrollController _receivedRightVertical = ScrollController();
  final ValueNotifier<bool> isSummaryDiscountActive = ValueNotifier(false);
  final ValueNotifier<bool> isItemDiscountActive = ValueNotifier(false);

  static const double _rowHeight = 30.0;
  static const int _minVisibleRows = 7;
  bool isTablet = false;
  final double _poBaseTotalQty = 0.0;
  double _poBaseDiscount = 0.0;
  double _approvedExtraDiscount = 0.0;
  double addedFreightAmount = 0.0;
  double addedFreightTaxAmount = 0.0;
  bool _disposed = false;
  final AIInvoiceResponse? aiResponse;
  final ValueNotifier<List<String>> sharedColumns = ValueNotifier<List<String>>(
    [
      'Item',
      // 'Count',
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
    ],
  );

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
  final ValueNotifier<int> uiRefresh = ValueNotifier(0);
  final ValueNotifier<Set<Item>> aiHighlightedItems = ValueNotifier<Set<Item>>(
    {},
  );
  final ValueNotifier<bool> isInvoiceDrivenMode = ValueNotifier(false);
  final ValueNotifier<List<Item>> invoiceReceivedItems =
      ValueNotifier<List<Item>>([]);
  final ValueNotifier<bool> isInvoiceHighlighted = ValueNotifier(false);
  final Map<Item, GlobalKey> receivedFieldKeys = {};
  final Map<Item, GlobalKey> expiryFieldKeys = {};
  void refreshUI() {
    uiRefresh.value++;
  }

  Timer? _debounce;

  ApprovedPOLogic({
    required this.po,
    required this.poProvider,
    required this.context,
    required this.onUpdated,
    this.aiResponse,
  }) : roundOffAmount = ValueNotifier<double>(po.roundOffAdjustment ?? 0.0) {
    _dialogMessengerKey = GlobalKey<ScaffoldMessengerState>(
      debugLabel: "dialog_messenger_${DateTime.now().microsecondsSinceEpoch}",
    );
  }

  double get rowHeight => _rowHeight;
  int get minVisibleRows => _minVisibleRows;

  GlobalKey<ScaffoldMessengerState> get dialogMessengerKey =>
      _dialogMessengerKey;

  void initialize() {
    _initializeControllers();
    _setupScrollSync();

    /// RESET AI MODE
    isInvoiceDrivenMode.value = false;
    invoiceReceivedItems.value = [];
    originalBefTaxDiscount.clear();
    originalAfTaxDiscount.clear();

    _poBaseDiscount = 0.0;

    /// STORE ORIGINAL DISCOUNTS

    for (var item in po.items) {
      originalBefTaxDiscount[item] = item.befTaxDiscount ?? 0.0;
      originalAfTaxDiscount[item] = item.afTaxDiscount ?? 0.0;

      _poBaseDiscount += item.pendingDiscountAmount ?? 0.0;
    }

    _approvedExtraDiscount = 0.0;
    final double ro = po.roundOffAdjustment ?? 0.0;
    roundOffAmount.value = ro;
    discountPriceController.text = ro.toStringAsFixed(2);

    /// MANUAL MODE AUTO LOAD
    /// AI MODE WILL OVERRIDE LATER

    for (var item in po.items) {
      double qtyToLoad = 0.0;

      /// MANUAL FLOW
      /// LOAD PENDING QTY

      if (!isInvoiceDrivenMode.value) {
        final double pendingQty = item.pendingTotalQuantity ?? 0.0;

        if (pendingQty > 0) {
          qtyToLoad = pendingQty;
        } else {
          qtyToLoad = (item.poQuantity ?? 0) > 0
              ? item.poQuantity!
              : ((item.count ?? 1) * (item.eachQuantity ?? 0));
        }
      }

      item.receivedQuantity = qtyToLoad;

      if (receivedQtyController.containsKey(item)) {
        receivedQtyController[item]!.text = qtyToLoad.toStringAsFixed(2);
      }
    }

    /// DEFAULT INVOICE DATE

    final now = ServerTimeService.now;
    invoiceDateController.text =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';

    /// APPLY AI RESPONSE IF EXISTS

    _applyAIResponse();
  }

  bool validateRoundOff() {
    final value = roundOffAmount.value;

    if (value < -2 || value > 2) {
      roundOffErrorNotifier.value = "Round off must be between -2 and +2";
      return false;
    }

    roundOffErrorNotifier.value = null;
    return true;
  }

  List<Item> get activeReceivedItems {
    return isInvoiceDrivenMode.value ? invoiceReceivedItems.value : po.items;
  }

  void _applyAIResponse() {
    try {
      final response = aiResponse;

      debugPrint("========== AI RESPONSE APPLY START ==========");

      if (response == null) {
        debugPrint("❌ AI RESPONSE NULL");
        return;
      }

      debugPrint("✅ AI RESPONSE FOUND");
      debugPrint("📦 Matched Items: ${response.matchedItems.length}");

      /// ENABLE INVOICE MODE
      isInvoiceDrivenMode.value = true;

      /// AUTO FILL INVOICE NUMBER
      invoiceNumberController.text = response.invoiceNumber;

      debugPrint("🧾 Invoice Number Applied: ${response.invoiceNumber}");

      /// AUTO FILL INVOICE DATE
      if (response.invoiceDate.isNotEmpty) {
        try {
          final parsedDate = DateTime.parse(response.invoiceDate);

          invoiceDateController.text = DateFormat(
            'dd-MM-yyyy',
          ).format(parsedDate);

          debugPrint("📅 Invoice Date Applied: ${response.invoiceDate}");
        } catch (e) {
          throw Exception(
            "Invalid date format in AI response: ${response.invoiceDate}",
          );
        }
      }

      /// HIGHLIGHT INVOICE FIELD
      isInvoiceHighlighted.value = true;

      Future.delayed(const Duration(seconds: 3), () {
        isInvoiceHighlighted.value = false;
      });

      /// RESET ALL ITEMS
      for (final item in po.items) {
        item.receivedQuantity = 0;

        item.newPrice = item.newPrice ?? 0;

        item.befTaxDiscount = 0;

        item.afTaxDiscount = 0;

        expiryDateControllers[item]?.text = "";

        item.expiryDate = "";

        /// RESET RECEIVED FIELD UI
        receivedQtyController[item]?.text = "0.00";

        receivedQtyValues[item]?.value = "0.00";

        /// RESET PRICE FIELD UI
        if (priceControllersMap.containsKey(item)) {
          priceControllersMap[item]!.text = (item.newPrice ?? 0)
              .toStringAsFixed(2);
        }
      }

      debugPrint("🧹 RESET OLD VALUES");

      /// CLEAR OLD AI ITEMS
      invoiceReceivedItems.value = [];

      /// MATCH AI ITEMS TO PO ITEMS
      for (final aiItem in response.matchedItems) {
        debugPrint("🔍 MATCHING AI ITEM: ${aiItem.itemName}");

        Item? matchedPOItem;

        for (final poItem in po.items) {
          final poName = (poItem.itemName ?? "").trim().toLowerCase();

          final aiName = aiItem.itemName.trim().toLowerCase();

          if (poName == aiName) {
            matchedPOItem = poItem;
            break;
          }
        }

        /// NO MATCH FOUND
        if (matchedPOItem == null) {
          debugPrint("❌ NO MATCH FOUND: ${aiItem.itemName}");
          continue;
        }

        debugPrint("✅ MATCH FOUND: ${matchedPOItem.itemName}");

        /// APPLY RECEIVED QTY
        matchedPOItem.receivedQuantity = aiItem.receivedQuantity;

        /// UPDATE RECEIVED FIELD UI
        receivedQtyController[matchedPOItem]?.text = aiItem.receivedQuantity
            .toStringAsFixed(2);

        receivedQtyValues[matchedPOItem]?.value = aiItem.receivedQuantity
            .toStringAsFixed(2);

        /// APPLY PRICE
        matchedPOItem.newPrice = aiItem.newPrice;

        /// UPDATE PRICE FIELD UI
        if (priceControllersMap.containsKey(matchedPOItem)) {
          priceControllersMap[matchedPOItem]!.text = aiItem.newPrice
              .toStringAsFixed(2);
        }

        /// APPLY DISCOUNTS
        matchedPOItem.befTaxDiscount = aiItem.befTaxDiscount;

        matchedPOItem.afTaxDiscount = aiItem.afTaxDiscount;

        /// APPLY EXPIRY DATE
        if (aiItem.expiryDate.isNotEmpty) {
          matchedPOItem.expiryDate = aiItem.expiryDate;

          expiryDateControllers[matchedPOItem]?.text = aiItem.expiryDate;
        }

        /// HIGHLIGHT AI UPDATED ITEMS
        aiHighlightedItems.value = {...aiHighlightedItems.value, matchedPOItem};

        /// ONLY ADD MATCHED ITEMS
        invoiceReceivedItems.value = [
          ...invoiceReceivedItems.value,
          matchedPOItem,
        ];
      }

      debugPrint(
        "📦 FINAL INVOICE ITEMS: "
        "${invoiceReceivedItems.value.length}",
      );

      /// RECALCULATE SUMMARY
      recalculateReceivedSummary();

      recalculateFinalAmountAfterDiscount();

      /// REFRESH UI
      refreshUI();

      debugPrint("✅ AI RESPONSE APPLIED SUCCESSFULLY");

      debugPrint("========== AI RESPONSE APPLY END ==========");
    } catch (e, stackTrace) {
      debugPrint("AI response apply failed: $e");
      debugPrintStack(stackTrace: stackTrace);

      final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

      AppSnackbar.showError(context, appError);
    }
  }

  void _applyDiscountResponseToItems(Map<String, dynamic> data) {
    final List<dynamic> items = data["items"] ?? [];

    for (final res in items) {
      final item = po.items.firstWhere((i) => i.itemId == res["itemId"]);

      item.befTaxDiscount = (res["befTaxDiscount"] as num?)?.toDouble() ?? 0.0;
      item.afTaxDiscount = (res["afTaxDiscount"] as num?)?.toDouble() ?? 0.0;
      befTaxControllers[item]?.text = item.befTaxDiscount!.toStringAsFixed(2);
      afTaxControllers[item]?.text = item.afTaxDiscount!.toStringAsFixed(2);
      item.pendingDiscountAmount =
          (res["pendingDiscountAmount"] as num?)?.toDouble() ?? 0.0;
      item.pendingTaxAmount =
          (res["pendingTaxAmount"] as num?)?.toDouble() ?? 0.0;
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

    refreshUI();
  }

  Future<void> applyOverallDiscountViaAPI() async {
    final entered = double.tryParse(discountInputController.text.trim()) ?? 0.0;

    if (entered <= 0) {
      showTopError("Enter valid discount amount");
      return;
    }

    try {
      _approvedExtraDiscount = entered;

      final double totalDiscount = _poBaseDiscount + entered;

      final response = await poProvider.calculateGrnOverallDiscount(
        items: po.items.map((item) {
          return {
            "itemId": item.itemId,
            "receivedQuantity": item.receivedQuantity ?? item.quantity,
            "grnPrice": item.newPrice,
            "befTaxDiscount": 0,
            "afTaxDiscount": 0,
            "taxPercentage": item.taxPercentage ?? 0.0,
            "taxType": item.taxType ?? "cgst_sgst",
          };
        }).toList(),
        discountAmount: totalDiscount,
        discountType: isBefTaxDiscount.value ? "before" : "after",
      );

      if (response["success"] != true) {
        showTopError("Discount API failed");
        return;
      }

      isSummaryDiscountActive.value = true;
      isItemDiscountActive.value = false;

      _applyDiscountResponseToItems(response);

      po.pendingDiscountAmount =
          (response["summary"]["totalDiscountAmount"] as num?)?.toDouble() ??
          0.0;

      po.pendingTaxAmount =
          (response["summary"]["totalTaxAmount"] as num?)?.toDouble() ?? 0.0;

      po.totalOrderAmount =
          (response["summary"]["totalFinalAmount"] as num?)?.toDouble() ?? 0.0;

      discountInputController.clear();

      refreshUI();

      showTopMessage(
        "Total Discount: ₹${po.pendingDiscountAmount!.toStringAsFixed(2)}",
        color: Colors.green,
      );
    } catch (e, stackTrace) {
      final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

      showTopError(appError.message);
    }
  }

  double get orderedSubTotal {
    return po.items.fold(
      0.0,
      (sum, i) =>
          sum + (i.poQuantitypendingTotalPrice ?? i.pendingTotalPrice ?? 0.0),
    );
  }

  double get orderedDiscount {
    return po.items.fold(
      0.0,
      (sum, i) => sum + (i.poQuantityDiscountAmount ?? 0.0),
    );
  }

  double get orderedTaxAmount {
    return po.items.fold(
      0.0,
      (sum, i) => sum + (i.poQuantityTaxAmount ?? i.pendingTaxAmount ?? 0.0),
    );
  }

  double get orderedFinalAmount {
    return po.items.fold(
      0.0,
      (sum, i) =>
          sum + (i.poQuantitypendingFinalPrice ?? i.pendingFinalPrice ?? 0.0),
    );
  }

  double get receivedSubTotal {
    return activeReceivedItems.fold(
      0.0,
      (sum, i) => sum + (i.pendingTotalPrice ?? 0.0),
    );
  }

  double get pendingDiscountFromItems {
    return po.pendingDiscountAmount ?? 0.0;
  }

  double get totalFreightAmount {
    return (po.totalFreightAmount ?? 0.0) + (po.totalFreightTaxAmount ?? 0.0);
  }

  double get receivedFinalAmount {
    final double itemsFinal = activeReceivedItems.fold(
      0.0,
      (sum, item) => sum + (item.pendingFinalPrice ?? 0.0),
    );

    return itemsFinal + totalFreightAmount + roundOffAmount.value;
  }

  double get itemTaxAmount {
    return po.pendingTaxAmount ?? 0.0;
  }

  void recalculateFinalAmountAfterDiscount() {
    final double subTotal = po.items.fold(
      0.0,
      (sum, i) => sum + (i.totalPrice ?? 0.0),
    );

    final double discount = po.pendingDiscountAmount ?? 0.0;
    final double tax = po.pendingTaxAmount ?? 0.0;
    final double roundOff = roundOffAmount.value;

    final freight = totalFreightAmount;

    po.totalOrderAmount = subTotal - discount + tax + freight + roundOff;
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
              "item_rand": item.randomId,
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
        discountAmount: 0,
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
      refreshUI();
    } catch (e, stackTrace) {
      final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

      showTopError(appError.message);
    }
  }

  void updateTabletStatus(double screenWidth) {
    isTablet = screenWidth > 600;

    final allColumns = Map<String, bool>.fromEntries(
      sharedColumns.value.map((column) => MapEntry(column, true)),
    );
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
    receivedQtyController.clear();
    pendingCountController.clear();
    eachQtyControllers.clear();
    befTaxControllers.clear();
    afTaxControllers.clear();
    expiryDateControllers.clear();
    expiryDateErrors.clear();
    priceControllersMap.clear();

    for (var item in po.items) {
      final count = item.pendingCount ?? item.count ?? 1;

      final qty = item.pendingQuantity ?? item.eachQuantity ?? 0;

      item.pendingCount = count;
      item.pendingQuantity = qty;
      item.pendingTotalQuantity = count * qty;

      String formattedExpiry = '';

      if ((item.receivedQuantity ?? 0) == 0) {
        formattedExpiry = '';
      }

      expiryDateControllers[item] = TextEditingController(
        text: formattedExpiry,
      );

      expiryDateErrors[item] = ValueNotifier<String?>(null);

      double defaultReceived = item.receivedQuantity ?? 0.0;

      receivedQtyController[item] = TextEditingController(
        text: defaultReceived.toStringAsFixed(2),
      );

      pendingCountController[item] = TextEditingController(
        text: count.toStringAsFixed(2),
      );

      eachQtyControllers[item] = TextEditingController(
        text: qty.toStringAsFixed(2),
      );

      befTaxControllers[item] = TextEditingController(
        text: (item.befTaxDiscount ?? 0.0).toStringAsFixed(2),
      );

      afTaxControllers[item] = TextEditingController(
        text: (item.pendingAfTaxDiscountAmount ?? item.afTaxDiscountAmount ?? 0)
            .toStringAsFixed(2),
      );

      receivedFieldKeys[item] = GlobalKey();
      expiryFieldKeys[item] = GlobalKey();
      priceControllersMap[item] = TextEditingController(
        text: (item.newPrice ?? 0.0).toStringAsFixed(2),
      );
    }
  }

  Future<void> scrollToField(GlobalKey key) async {
    final context = key.currentContext;

    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  void onPriceChanged(Item item, double newPrice) {
    item.newPrice = newPrice;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _recalculateAfterPriceChange();
    });
  }

  Future<void> _recalculateAfterPriceChange() async {
    try {
      final response = await poProvider.calculateGrnOverallDiscount(
        items: po.items.map((item) {
          return {
            "itemId": item.itemId,
            "receivedQuantity": item.receivedQuantity ?? 0,
            "grnPrice": item.newPrice,
            "befTaxDiscount": item.befTaxDiscount ?? 0,
            "afTaxDiscount": item.afTaxDiscount ?? 0,
            "taxPercentage": item.taxPercentage ?? 0.0,
            "taxType": item.taxType ?? "cgst_sgst",
          };
        }).toList(),
        discountAmount: po.pendingDiscountAmount ?? 0,
        discountType: isBefTaxDiscount.value ? "before" : "after",
      );

      if (response["success"] == true) {
        _applyDiscountResponseToItems(response);
        refreshUI();
      }
    } catch (e, stackTrace) {
      final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

      showTopError(appError.message);
    }
  }

  void normalizeBeforeApi() {
    for (var item in po.items) {
      final count = item.pendingCount ?? item.count ?? 1;
      final qty = item.pendingQuantity ?? item.eachQuantity ?? 0;

      item.pendingCount = count;
      item.pendingQuantity = qty;
      item.pendingTotalQuantity = count * qty;
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

  Future<void> recalculateReceivedSummary() async {
    try {
      final response = await poProvider.calculateGrnOverallDiscount(
        items: activeReceivedItems.map((item) {
          return {
            "itemId": item.itemId,
            "receivedQuantity": item.receivedQuantity ?? 0,
            "grnPrice": item.newPrice,
            "befTaxDiscount": item.befTaxDiscount ?? 0,
            "afTaxDiscount": item.afTaxDiscount ?? 0,
            "taxPercentage": item.taxPercentage ?? 0.0,
            "taxType": item.taxType ?? "cgst_sgst",
          };
        }).toList(),
        discountAmount: po.pendingDiscountAmount ?? 0,
        discountType: isBefTaxDiscount.value ? "before" : "after",
      );

      if (response["success"] == true) {
        _applyDiscountResponseToItems(response);

        refreshUI();
      }
    } catch (e, stackTrace) {
      final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

      showTopError(appError.message);
    }
  }

  void showNumericCalculator({
    required TextEditingController? controller,
    required String varianceName,
    double? initialValue,
    required VoidCallback onValueSelected,
    bool isItemField = true,
    Item? item,
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

          final formatted = value.toStringAsFixed(2);

          if (!isItemField) {
            controller.text = formatted;
            onValueSelected();
            suppressReceivedListener = false;
            return;
          }

          if (item == null) {
            suppressReceivedListener = false;
            return;
          }

          if (receivedQtyController[item] == controller) {
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

            item.receivedQuantity = value;
            refreshUI();

            updateQtyWhenReceivedChanges(item);
          }

          controller.text = formatted;

          onValueSelected();

          suppressReceivedListener = false;
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

  void onDiscountChanged({required bool isBefTax}) {
    isBefTaxDiscount.value = isBefTax;

    for (var item in po.items) {
      if (isBefTax) {
        item.afTaxDiscount = 0.0;
        afTaxControllers[item]?.text = "0.00";
      } else {
        item.befTaxDiscount = 0.0;
        befTaxControllers[item]?.text = "0.00";
      }
    }

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      await _recalculateAfterDiscountChange();
    });
  }

  Future<void> _recalculateAfterDiscountChange() async {
    try {
      final response = await poProvider.calculateGrnOverallDiscount(
        items: po.items.map((item) {
          return {
            "itemId": item.itemId,
            "receivedQuantity": item.receivedQuantity ?? 0,
            "grnPrice": item.newPrice,
            "befTaxDiscount": item.befTaxDiscount ?? 0,
            "afTaxDiscount": item.afTaxDiscount ?? 0,
            "taxPercentage": item.taxPercentage ?? 0.0,
            "taxType": item.taxType ?? "cgst_sgst",
          };
        }).toList(),
        discountAmount: 0,
        discountType: isBefTaxDiscount.value ? "before" : "after",
      );

      if (response["success"] == true) {
        _applyDiscountResponseToItems(response);
        refreshUI();
      }
    } catch (e, stackTrace) {
      final appError = AppErrorHandler.handle(e, stackTrace: stackTrace);

      showTopError(appError.message);
    }
  }

  void updateRoundOff(String value) {
    double roundOffValue = double.tryParse(value) ?? 0.0;

    roundOffAmount.value = roundOffValue;
    discountPriceController.text = value;

    recalculateFinalAmountAfterDiscount();

    refreshUI();
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
    final DateTime now = ServerTimeService.now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              surface: Colors.white,
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
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
    final DateTime now = ServerTimeService.now;
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
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

                isReverting.value = true;

                try {
                  await poProvider.changePoStatusToPending(po.purchaseOrderId);

                  await poProvider.applyCurrentFilters();

                  isReverting.value = false;

                  if (!context.mounted) return;

                  Navigator.of(context).pop();

                  onUpdated();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PO reverted to Pending successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    ),
                  );
                } catch (e, stackTrace) {
                  isReverting.value = false;

                  if (!context.mounted) return;

                  final appError = AppErrorHandler.handle(
                    e,
                    stackTrace: stackTrace,
                  );

                  AppSnackbar.showError(context, appError);
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
    debugPrint("convertPoToGRN() CALLED");

    final navigator = Navigator.of(context);

    if (isSaving.value) {
      debugPrint("Already saving, skipping...");
      return;
    }

    final poProvider = Provider.of<POProvider>(context, listen: false);
    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    try {
      isSaving.value = true;

      debugPrint("=========== GRN CONVERSION START ===========");

      normalizeBeforeApi();

      final List<Item> receivedItems = activeReceivedItems.map((item) {
        return item.copyWith(
          receivedQuantity: item.receivedQuantity ?? 0,
          befTaxDiscount: item.befTaxDiscount ?? 0,
          afTaxDiscount: item.afTaxDiscount ?? 0,
          befTaxDiscountType: "percentage",
          afTaxDiscountType: "percentage",
          expiryDate: item.expiryDate,
        );
      }).toList();

      final rawDate = invoiceDateController.text.trim();
      DateTime pickedDate;

      try {
        if (rawDate.isEmpty) {
          throw Exception("Invoice date is empty");
        }

        debugPrint("📅 Parsing date: '$rawDate'");

        DateTime? parsedDate;

        final dateFormats = [
          DateFormat('dd-MM-yyyy'),
          DateFormat('dd/MM/yyyy'),
          DateFormat('yyyy-MM-dd'),
          DateFormat('yyyy/MM/dd'),
          DateFormat('MM-dd-yyyy'),
          DateFormat('MM/dd/yyyy'),
          DateFormat('dd.MM.yyyy'),
          DateFormat('yyyy.MM.dd'),
        ];

        for (var format in dateFormats) {
          try {
            parsedDate = format.parseStrict(rawDate);
            debugPrint("✅ Parsed with format: ${format.pattern}");
            break;
          } catch (_) {}
        }

        if (parsedDate == null) {
          final numbers = RegExp(
            r'\d+',
          ).allMatches(rawDate).map((m) => int.parse(m.group(0)!)).toList();

          if (numbers.length >= 3) {
            int first = numbers[0];
            int second = numbers[1];
            int year = numbers[2];

            if (year < 100) {
              year += 2000;
            }

            if (first > 12) {
              parsedDate = DateTime(year, second, first);
            } else if (second > 12) {
              parsedDate = DateTime(year, first, second);
            } else {
              parsedDate = DateTime(year, second, first);
            }
          }
        }

        if (parsedDate == null) {
          throw Exception("Could not parse date");
        }

        if (parsedDate.year < 2000 || parsedDate.year > 2100) {
          throw Exception("Invalid year");
        }

        pickedDate = parsedDate;

        debugPrint(
          "✅ FINAL DATE: ${DateFormat('dd-MM-yyyy').format(pickedDate)}",
        );
      } catch (e) {
        throw const AppException("Invalid invoice date format. Use DD-MM-YYYY");
      }

      final now = ServerTimeService.now;

      final parsedInvoiceDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      debugPrint("📅 FINAL INVOICE DATE: $parsedInvoiceDate");

      final response = await poProvider.updatePoDetails(
        po.purchaseOrderId,
        receivedItems,
        invoiceNumberController.text.trim(),
        parsedInvoiceDate,
        0,
        roundOffAdjustment: roundOffAmount.value,
      );

      if (response["grnCreated"] != true) {
        throw Exception("GRN creation failed");
      }

      final String grnNumber =
          response["grnRandomId"] ??
          response["randomId"] ??
          response["grnNumber"] ??
          response["grnNo"] ??
          response["grn_code"] ??
          response["grnId"] ??
          "N/A";

      debugPrint("✅ GRN CREATED: $grnNumber");

      await poProvider.fetchApprovedPOsOnly();
      await grnProvider.fetchFilteredGRNs();

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "GRN Generated",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Text(
              "GRN has been generated successfully.\n\nGRN No: $grnNumber",
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  navigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      debugPrint("=========== GRN CONVERSION END ===========");
    } catch (e, stack) {
      debugPrint("Convert PO to GRN failed: $e");
      debugPrintStack(stackTrace: stack);

      final appError = AppErrorHandler.handle(e, stackTrace: stack);

      showTopError(appError.message);
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> validateBeforeGRN() async {
    /// INVOICE VALIDATION

    if (invoiceNumberController.text.trim().isEmpty) {
      invoiceValidationMessage.value = "error";

      showTopError("Invoice number is required");

      return false;
    }

    invoiceValidationMessage.value = null;

    if (invoiceDateController.text.trim().isEmpty) {
      invoiceDateValidationMessage.value = "error";

      showTopError("Invoice date is required");

      return false;
    }

    invoiceDateValidationMessage.value = null;

    /// IMPORTANT FIX
    /// USE ONLY ACTIVE RECEIVED ITEMS

    final itemsToValidate = activeReceivedItems;

    /// ITEM VALIDATION

    for (final item in itemsToValidate) {
      final received = item.receivedQuantity ?? 0.0;

      final expiry = expiryDateControllers[item]?.text.trim() ?? '';

      /// RECEIVED EMPTY

      if (received <= 0) {
        receivedQtyErrors.value = {
          ...receivedQtyErrors.value,
          item: "Required",
        };

        refreshUI();

        showTopError("Enter received quantity");

        await Future.delayed(const Duration(milliseconds: 200));

        final key = receivedFieldKeys[item];

        if (key != null) {
          await scrollToField(key);
        }

        return false;
      }

      /// EXPIRY EMPTY

      if (received > 0 && expiry.isEmpty) {
        expiryDateErrors[item]?.value = "Required";

        refreshUI();

        showTopError("Select expiry date");

        await Future.delayed(const Duration(milliseconds: 200));

        final key = expiryFieldKeys[item];

        if (key != null) {
          await scrollToField(key);
        }

        return false;
      }

      expiryDateErrors[item]?.value = null;
    }

    return true;
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
        return 150.0;
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
        return (item.count ?? 0).toStringAsFixed(2);

      case 'Qty':
        return (item.poQuantity ?? 0).toStringAsFixed(2);

      case 'Tax%':
        return (item.taxPercentage ?? 0).toStringAsFixed(2);

      case 'Price':
        return (item.newPrice ?? 0).toStringAsFixed(2);

      case 'Total Price':
        return (item.pendingTotalPrice ?? 0).toStringAsFixed(2);

      case 'Final':
        return (item.pendingFinalPrice ?? 0).toStringAsFixed(2);

      case 'BefTax':
        return (item.befTaxDiscount ?? 0).toStringAsFixed(2);

      case 'AfTax':
        return (item.afTaxDiscount ?? 0).toStringAsFixed(2);

      case 'Total':
        return (item.poQuantity ?? 0).toStringAsFixed(2);

      default:
        return '';
    }
  }

  ScrollController get orderedHorizontalController =>
      _orderedHorizontalController;
  ScrollController get receivedHorizontalController =>
      _receivedHorizontalController;
  ScrollController get orderedLeftVertical => _orderedLeftVertical;
  ScrollController get orderedRightVertical => _orderedRightVertical;
  ScrollController get receivedLeftVertical => _receivedLeftVertical;
  ScrollController get receivedRightVertical => _receivedRightVertical;

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
    _disposed = true;

    _debounce?.cancel();

    // SCROLL CONTROLLERS
    _orderedHorizontalController.dispose();
    _receivedHorizontalController.dispose();
    _orderedLeftVertical.dispose();
    _orderedRightVertical.dispose();
    _receivedLeftVertical.dispose();
    _receivedRightVertical.dispose();

    // TEXT CONTROLLERS
    discountInputController.dispose();
    discountPriceController.dispose();
    invoiceDateController.dispose();
    invoiceNumberController.dispose();

    // VALUE NOTIFIERS
    roundOffAmount.dispose();
    appliedDiscount.dispose();
    roundOffErrorNotifier.dispose();
    isSaving.dispose();
    isBefTaxDiscount.dispose();
    receivedDiscountAmount.dispose();

    invoiceValidationMessage.dispose();
    invoiceDateValidationMessage.dispose();
    receivedQtyErrors.dispose();

    sharedColumns.dispose();
    sharedColumnVisibility.dispose();

    uiRefresh.dispose();

    aiHighlightedItems.dispose();
    isInvoiceHighlighted.dispose();

    isSummaryDiscountActive.dispose();
    isItemDiscountActive.dispose();

    // MAP CONTROLLERS
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

    // ✅ PRICE CONTROLLERS DISPOSE FIX
    for (var controller in priceControllersMap.values) {
      controller.dispose();
    }

    // VALUE NOTIFIER MAPS
    for (var notifier in expiryDateErrors.values) {
      notifier.dispose();
    }

    for (var notifier in countTextColors.values) {
      notifier.dispose();
    }

    for (var notifier in qtyTextColors.values) {
      notifier.dispose();
    }

    for (var notifier in receivedQtyValues.values) {
      notifier.dispose();
    }

    for (var notifier in expiryDateValues.values) {
      notifier.dispose();
    }
  }
}
