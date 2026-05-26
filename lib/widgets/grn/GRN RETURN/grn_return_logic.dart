import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn/grnitem.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../../../models/grn/grn.dart';
import '../../../providers/grn_provider.dart';
import 'package:provider/provider.dart';

class GRNReturnLogic extends ChangeNotifier {
  final GRN grn;
  late BuildContext _context;

  // Notifiers
  late ValueNotifier<List<bool>> selectedRowsNotifier;
  late ValueNotifier<bool> isReturnAllEnabledNotifier;
  late ValueNotifier<bool> enableReturnSelectedFieldsNotifier;
  late ValueNotifier<bool> isSpecificQuantityReturnNotifier;
  late Map<ItemDetail, double?> originalQuantities;
  late Map<ItemDetail, double?> originalEachQuantities;
  late ValueNotifier<String?> scenarioNotifier;
  late String grnId;
  late ValueNotifier<DateTime?> returnDateNotifier;
  late String returnedBy;
  late ValueNotifier<Map<int, String>> itemReasonsNotifier;
  late ValueNotifier<List<Map<String, dynamic>>?> itemsNotifier;
  late ValueNotifier<String?> reasonErrorNotifier;
  late ValueNotifier<Map<int, String?>> quantityErrorsNotifier;
  late ValueNotifier<Map<int, String?>> reasonErrorsNotifier;
  late ValueNotifier<bool> selectItemErrorNotifier;
  final ValueNotifier<bool> isSubmitting = ValueNotifier(false);

  // Scroll Controllers
  final ScrollController verticalScrollController = ScrollController();
  final ScrollController fixedColumnScrollController = ScrollController();
  final ScrollController rightHeaderHorizontal = ScrollController();
  final ScrollController rightBodyHorizontal = ScrollController();

  GRNReturnLogic({required this.grn}) {
    _initNotifiers();
    _initData();
    _setupScrollListeners();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void _initNotifiers() {
    selectedRowsNotifier = ValueNotifier<List<bool>>(
      List<bool>.filled(grn.itemDetails?.length ?? 0, false),
    );
    isReturnAllEnabledNotifier = ValueNotifier<bool>(false);
    enableReturnSelectedFieldsNotifier = ValueNotifier<bool>(false);
    isSpecificQuantityReturnNotifier = ValueNotifier<bool>(false);
    originalQuantities = {};
    originalEachQuantities = {};
    scenarioNotifier = ValueNotifier<String?>(null);
    grnId = grn.grnId ?? '';
    returnedBy = 'user123';
    returnDateNotifier = ValueNotifier<DateTime?>(ServerTimeService.now);
    itemReasonsNotifier = ValueNotifier<Map<int, String>>({});
    itemsNotifier = ValueNotifier<List<Map<String, dynamic>>?>([]);
    reasonErrorNotifier = ValueNotifier<String?>(null);
    quantityErrorsNotifier = ValueNotifier<Map<int, String?>>({});
    reasonErrorsNotifier = ValueNotifier<Map<int, String?>>({});
    selectItemErrorNotifier = ValueNotifier<bool>(false);
  }

  void _initData() {
    for (var item in grn.itemDetails ?? []) {
      originalQuantities[item] = item.receivedQuantity ?? 0;
      originalEachQuantities[item] = item.eachQuantity ?? 1;
    }
  }

  void _setupScrollListeners() {
    verticalScrollController.addListener(_syncVerticalScroll);
    fixedColumnScrollController.addListener(_syncVerticalScroll);

    rightHeaderHorizontal.addListener(() {
      if (rightBodyHorizontal.hasClients &&
          rightBodyHorizontal.offset != rightHeaderHorizontal.offset) {
        rightBodyHorizontal.jumpTo(rightHeaderHorizontal.offset);
      }
    });

    rightBodyHorizontal.addListener(() {
      if (rightHeaderHorizontal.hasClients &&
          rightHeaderHorizontal.offset != rightBodyHorizontal.offset) {
        rightHeaderHorizontal.jumpTo(rightBodyHorizontal.offset);
      }
    });
  }

  void _syncVerticalScroll() {
    if (verticalScrollController.hasClients &&
        fixedColumnScrollController.hasClients) {
      if (verticalScrollController.position.activity?.isScrolling ?? false) {
        fixedColumnScrollController.jumpTo(verticalScrollController.offset);
      }
    }
  }

  bool getCanReturnGRN(BuildContext context) {
    final permission = context.read<PermissionProvider>();
    return permission.hasEditAction('grns', 'return_grn');
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'No Date';
    try {
      final DateTime parsedDate = DateTime.parse(date).toUtc().toLocal();
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      throw Exception("DATE_FORMAT_ERROR");
    }
  }

  String getGrnNo() => grn.randomId ?? 'N/A';
  String getVendorName() => grn.vendorName ?? 'N/A';
  String getGrnDate() => formatDate(grn.grnDate);
  List<ItemDetail> getItemDetails() => grn.itemDetails ?? [];

  double getReturnableQuantity(ItemDetail item) {
    return originalQuantities[item] ?? item.receivedQuantity ?? 0;
  }

  double getOriginalQuantity(ItemDetail item) {
    return originalQuantities[item] ?? item.receivedQuantity ?? 0;
  }

  void updateSelectedRow(int index, bool value) {
    final updatedSelectedRows = List<bool>.from(selectedRowsNotifier.value);

    updatedSelectedRows[index] = value;

    selectedRowsNotifier.value = updatedSelectedRows;

    // CLEAR ERRORS WHEN UNSELECTING
    if (!value) {
      // CLEAR QTY ERROR
      final updatedQtyErrors = Map<int, String?>.from(
        quantityErrorsNotifier.value,
      );

      updatedQtyErrors.remove(index);

      quantityErrorsNotifier.value = updatedQtyErrors;

      // CLEAR REASON ERROR
      final updatedReasonErrors = Map<int, String?>.from(
        reasonErrorsNotifier.value,
      );

      updatedReasonErrors.remove(index);

      reasonErrorsNotifier.value = updatedReasonErrors;

      // RESET VALUES
      final item = grn.itemDetails![index];

      item.returnedQuantity = 0;

      item.receivedQuantity = originalQuantities[item] ?? item.receivedQuantity;

      item.nos = 0;
      item.eachQuantity = 0;

      // CLEAR REASON
      final updatedReasons = Map<int, String>.from(itemReasonsNotifier.value);

      updatedReasons.remove(index);

      itemReasonsNotifier.value = updatedReasons;

      // FORCE UI REFRESH
      quantityErrorsNotifier.notifyListeners();
      reasonErrorsNotifier.notifyListeners();
      itemReasonsNotifier.notifyListeners();
      selectedRowsNotifier.notifyListeners();
    }

    _updateItems();

    notifyListeners();
  }

  void selectAllItems(bool value) {
    final updatedSelectedRows = List<bool>.filled(
      grn.itemDetails?.length ?? 0,
      value,
    );
    selectedRowsNotifier.value = updatedSelectedRows;
    _updateItems();
  }

  void enableReturnAll() {
    itemReasonsNotifier.value = {};
    itemsNotifier.value = null;
    selectedRowsNotifier.value = List<bool>.filled(
      grn.itemDetails?.length ?? 0,
      false,
    );
    isReturnAllEnabledNotifier.value = true;
    isSpecificQuantityReturnNotifier.value = false;
    scenarioNotifier.value = 'full';
  }

  void disableReturnAll() {
    isReturnAllEnabledNotifier.value = false;

    scenarioNotifier.value = null;

    itemReasonsNotifier.value = {};

    itemsNotifier.value = null;

    // CLEAR RETURN ALL ERROR
    reasonErrorNotifier.value = null;

    selectedRowsNotifier.value = List<bool>.filled(
      grn.itemDetails?.length ?? 0,
      false,
    );

    // FORCE UI REFRESH
    reasonErrorNotifier.notifyListeners();
    itemReasonsNotifier.notifyListeners();
    selectedRowsNotifier.notifyListeners();

    notifyListeners();
  }

  void enableSpecificQuantityReturn() {
    itemReasonsNotifier.value = {};
    itemsNotifier.value = null;
    selectedRowsNotifier.value = List<bool>.filled(
      grn.itemDetails?.length ?? 0,
      false,
    );
    isSpecificQuantityReturnNotifier.value = true;
    isReturnAllEnabledNotifier.value = false;
    scenarioNotifier.value = 'quantity_wise';
    _updateItems();
  }

  void disableSpecificQuantityReturn() {
    isSpecificQuantityReturnNotifier.value = false;

    scenarioNotifier.value = null;

    selectedRowsNotifier.value = List<bool>.filled(
      grn.itemDetails?.length ?? 0,
      false,
    );

    itemReasonsNotifier.value = {};

    itemsNotifier.value = null;

    // CLEAR ALL INLINE ERRORS
    quantityErrorsNotifier.value = {};

    reasonErrorsNotifier.value = {};

    // RESET ITEM VALUES
    for (final item in grn.itemDetails ?? []) {
      item.returnedQuantity = 0;

      item.receivedQuantity = originalQuantities[item] ?? item.receivedQuantity;

      item.nos = 0;

      item.eachQuantity = 0;
    }

    // FORCE UI REFRESH
    quantityErrorsNotifier.notifyListeners();

    reasonErrorsNotifier.notifyListeners();

    itemReasonsNotifier.notifyListeners();

    selectedRowsNotifier.notifyListeners();

    notifyListeners();
  }

  void setReturnAllReason(String reason) {
    final updatedReasons = <int, String>{};
    for (int i = 0; i < (grn.itemDetails?.length ?? 0); i++) {
      updatedReasons[i] = reason;
    }
    itemReasonsNotifier.value = updatedReasons;
    _updateItems();
  }

  void setItemReason(int index, String reason) {
    final updatedReasons = Map<int, String>.from(itemReasonsNotifier.value);
    updatedReasons[index] = reason;
    itemReasonsNotifier.value = updatedReasons;
    _updateItems();
  }

  void updateReturnQuantity(ItemDetail item, int index, double newReturnedQty) {
    double originalQty = originalQuantities[item] ?? item.receivedQuantity ?? 0;
    if (newReturnedQty <= originalQty) {
      item.returnedQuantity = newReturnedQty;
      item.receivedQuantity = originalQty - item.returnedQuantity!;
      _updateItemQuantities(item);
      _recalculateItemTotals(item);
      _recalculateGRNTotal();
      _updateItems();
    }
  }

  void _updateItemQuantities(ItemDetail item) {
    double? originalEachQty =
        originalEachQuantities[item] ?? item.eachQuantity ?? 1;
    double? originalNos = item.nos ?? 1;

    if (item.returnedQuantity != null && item.returnedQuantity! > 0) {
      if (originalNos > 0) {
        item.eachQuantity = (item.returnedQuantity! / originalNos);
        item.nos = originalNos;
      } else if (originalEachQty > 0) {
        item.nos = (item.returnedQuantity! / originalEachQty);
        item.eachQuantity = originalEachQty;
      } else {
        item.nos = item.returnedQuantity!;
        item.eachQuantity = 1;
      }
    } else {
      item.nos = 0;
      item.eachQuantity = 0;
    }
  }

  void _recalculateItemTotals(ItemDetail item) {
    item.discountAmount =
        ((item.receivedQuantity ?? 0) * (item.unitPrice ?? 0)) *
        (grn.discountPrice ?? 0) /
        100;
    double discountedPrice =
        ((item.receivedQuantity ?? 0) * (item.unitPrice ?? 0)) -
        (item.discountAmount ?? 0);
    item.taxAmount = discountedPrice * (item.purchasetaxName ?? 0) / 100;
    item.finalPrice = discountedPrice + (item.taxAmount ?? 0);
  }

  void _recalculateGRNTotal() {
    grn.totalReceivedAmount =
        grn.itemDetails?.fold(
          0.0,
          (total, item) => total! + (item.finalPrice ?? 0),
        ) ??
        0.0;
  }

  void _updateItems() {
    if (scenarioNotifier.value == 'quantity_wise') {
      final updatedItems = grn.itemDetails
          ?.asMap()
          .entries
          .where((entry) => selectedRowsNotifier.value[entry.key])
          // PREVENT ZERO QTY ITEMS
          .where((entry) => (entry.value.returnedQuantity ?? 0) > 0)
          .where(
            (entry) =>
                entry.value.itemId.isNotEmpty &&
                _isValidObjectId(entry.value.itemId),
          )
          .map((entry) {
            final index = entry.key;
            final item = entry.value;

            return {
              'itemId': item.itemId,
              'nos': item.nos,
              'eachQuantity': item.eachQuantity,
              'returnReason': itemReasonsNotifier.value[index] ?? '',
              'returnedQuantity': item.returnedQuantity,
            };
          })
          .toList();

      itemsNotifier.value = updatedItems;
    }
  }

  bool _isValidObjectId(String id) {
    if (id.length != 24) return false;
    final hexRegex = RegExp(r'^[0-9a-fA-F]{24}$');
    return hexRegex.hasMatch(id);
  }

  List<ReturnItem> buildFullReturnItems() {
    final items = <ReturnItem>[];
    for (int i = 0; i < (grn.itemDetails?.length ?? 0); i++) {
      final item = grn.itemDetails![i];
      if (item.itemId.isNotEmpty && _isValidObjectId(item.itemId)) {
        final returnItem = ReturnItem(
          itemId: item.itemId,
          nos: item.nos,
          eachQuantity: item.eachQuantity,
          returnReason: itemReasonsNotifier.value[i] ?? 'Full return',
          returnedQuantity: item.receivedQuantity,
        );
        items.add(returnItem);
      }
    }
    return items;
  }

  void scrollToIndex(int index, {bool scrollToReason = false}) {
    const double rowHeight = 60.0;

    final targetOffset = index * rowHeight;

    // VERTICAL SCROLL
    verticalScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    fixedColumnScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // HORIZONTAL SCROLL
    double horizontalOffset = 0;

    if (scrollToReason) {
      // Return Reason column
      horizontalOffset = 650;
    } else {
      // Return Qty column
      horizontalOffset = 300;
    }

    rightBodyHorizontal.animateTo(
      horizontalOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    rightHeaderHorizontal.animateTo(
      horizontalOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  bool validateReturn() {
    if (scenarioNotifier.value == null) {
      showTopSnackBar('Please select return type');

      return false;
    }

    // ===== RETURN ALL VALIDATION =====

    if (scenarioNotifier.value == 'full') {
      final reason = itemReasonsNotifier.value.isNotEmpty
          ? itemReasonsNotifier.value.values.first
          : '';

      if (reason.trim().isEmpty) {
        reasonErrorNotifier.value = 'Reason required';

        showTopSnackBar('Please enter return reason');

        return false;
      }

      reasonErrorNotifier.value = null;
    }

    // ===== RETURN SPECIFIC VALIDATION =====

    if (scenarioNotifier.value == 'quantity_wise') {
      final selectedIndexes = selectedRowsNotifier.value
          .asMap()
          .entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      if (selectedIndexes.isEmpty) {
        // SHOW SELECT COLUMN ERROR
        selectItemErrorNotifier.value = true;

        // SCROLL TO CHECKBOX COLUMN
        rightBodyHorizontal.animateTo(
          1200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );

        rightHeaderHorizontal.animateTo(
          1200,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );

        showTopSnackBar('Please select at least one item to return');

        return false;
      }

      for (final index in selectedIndexes) {
        final item = grn.itemDetails![index];

        // ===== CLEAR OLD ERRORS =====

        final updatedQtyErrors = Map<int, String?>.from(
          quantityErrorsNotifier.value,
        );

        final updatedReasonErrors = Map<int, String?>.from(
          reasonErrorsNotifier.value,
        );

        updatedQtyErrors.remove(index);
        updatedReasonErrors.remove(index);

        // ===== VALIDATE RETURN QUANTITY =====

        if ((item.returnedQuantity ?? 0) <= 0) {
          scrollToIndex(index);

          updatedQtyErrors[index] = 'Qty must be > 0';

          quantityErrorsNotifier.value = updatedQtyErrors;

          showTopSnackBar('Return quantity must be greater than 0');

          return false;
        }

        quantityErrorsNotifier.value = updatedQtyErrors;

        // ===== VALIDATE REASON =====

        final reason = itemReasonsNotifier.value[index] ?? '';

        if (reason.trim().isEmpty) {
          scrollToIndex(index, scrollToReason: true);

          updatedReasonErrors[index] = 'Reason required';

          reasonErrorsNotifier.value = updatedReasonErrors;

          showTopSnackBar('Please enter return reason for selected items');

          return false;
        }

        reasonErrorsNotifier.value = updatedReasonErrors;
      }
    }

    return true;
  }

  void showTopSnackBar(String message, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),

        backgroundColor: backgroundColor,

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 80),

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> submitReturn(BuildContext context) async {
    final permission = context.read<PermissionProvider>();

    if (!permission.hasEditAction('grns', 'return_grn')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No permission")));

      return;
    }

    if (!validateReturn()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Builder(
              builder: (innerContext) {
                final String message = scenarioNotifier.value == 'full'
                    ? 'Do you want to return all items?'
                    : 'Do you want to return selected items?';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm GRN Return',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(innerContext, false),

                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: () => Navigator.pop(innerContext, true),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),

                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final convertedItems = scenarioNotifier.value == 'full'
        ? buildFullReturnItems()
        : itemsNotifier.value
              ?.where(
                (item) =>
                    item['itemId'] != null &&
                    item['itemId'].toString().isNotEmpty,
              )
              .map((item) => ReturnItem.fromMap(item))
              .toList();

    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    // START LOADING
    isSubmitting.value = true;

    try {
      await grnProvider.returnGrn(
        grnId,
        ReturnGRNRequest(
          scenario: scenarioNotifier.value == 'full' ? "full" : "partial",

          returnedDate: returnDateNotifier.value!,

          returnedBy: returnedBy,

          comments: scenarioNotifier.value == 'full'
              ? (itemReasonsNotifier.value.isNotEmpty
                    ? itemReasonsNotifier.value.values.first
                    : null)
              : null,

          items: convertedItems,
        ),
      );

      if (context.mounted) {
        Navigator.of(context).pop(true);

        showTopSnackBar(
          'Return processed successfully',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar('Failed to process return: $e');
      }
    } finally {
      // STOP LOADING
      isSubmitting.value = false;
    }
  }

  @override
  void dispose() {
    selectedRowsNotifier.dispose();
    isReturnAllEnabledNotifier.dispose();
    enableReturnSelectedFieldsNotifier.dispose();
    isSpecificQuantityReturnNotifier.dispose();
    scenarioNotifier.dispose();
    returnDateNotifier.dispose();
    itemReasonsNotifier.dispose();
    itemsNotifier.dispose();
    reasonErrorNotifier.dispose();
    quantityErrorsNotifier.dispose();
    reasonErrorsNotifier.dispose();
    selectItemErrorNotifier.dispose();
    originalQuantities.clear();
    originalEachQuantities.clear();
    verticalScrollController.dispose();
    fixedColumnScrollController.dispose();
    rightHeaderHorizontal.dispose();
    rightBodyHorizontal.dispose();
    isSubmitting.dispose();
    super.dispose();
  }
}
