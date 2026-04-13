// ignore_for_file: library_private_types_in_public_api, unnecessary_to_list_in_spreads, use_build_context_synchronously, unnecessary_non_null_assertion, unnecessary_null_comparison, avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grnitem.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../../models/grn.dart';
import '../../providers/grn_provider.dart';
import 'package:provider/provider.dart';
import '../../utils/calculator_utils.dart';

class GRNReturn extends StatefulWidget {
  final GRN grn;

  const GRNReturn({super.key, required this.grn});

  @override
  _GRNModalState createState() => _GRNModalState();
}

class _GRNModalState extends State<GRNReturn> {
  late GRN grn;
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
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _fixedColumnScrollController = ScrollController();
  final ScrollController _rightHeaderHorizontal = ScrollController();
  final ScrollController _rightBodyHorizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    grn = widget.grn;

    Future.microtask(() {
      Provider.of<GRNProvider>(context, listen: false).fetchReturnReasons();
    });

    _syncHorizontalScroll();

    selectedRowsNotifier = ValueNotifier<List<bool>>(
      List<bool>.filled(grn.itemDetails?.length ?? 0, false),
    );
    isReturnAllEnabledNotifier = ValueNotifier<bool>(false);
    enableReturnSelectedFieldsNotifier = ValueNotifier<bool>(false);
    isSpecificQuantityReturnNotifier = ValueNotifier<bool>(false);
    originalQuantities = {};
    originalEachQuantities = {};
    for (var item in grn.itemDetails ?? []) {
      originalQuantities[item] = item.receivedQuantity ?? 0;
      originalEachQuantities[item] = item.eachQuantity ?? 1;
    }
    scenarioNotifier = ValueNotifier<String?>(null);
    grnId = grn.grnId ?? '';
    returnedBy = 'user123';
    returnDateNotifier = ValueNotifier<DateTime?>(ServerTimeService.now);
    itemReasonsNotifier = ValueNotifier<Map<int, String>>({});
    itemsNotifier = ValueNotifier<List<Map<String, dynamic>>?>([]);
    reasonErrorNotifier = ValueNotifier<String?>(null);
    quantityErrorsNotifier = ValueNotifier<Map<int, String?>>({});
    reasonErrorsNotifier = ValueNotifier<Map<int, String?>>({});

    _verticalScrollController.addListener(_syncVerticalScroll);
    _fixedColumnScrollController.addListener(_syncVerticalScroll);
  }

  void _syncVerticalScroll() {
    if (_verticalScrollController.hasClients &&
        _fixedColumnScrollController.hasClients) {
      if (_verticalScrollController.position.activity?.isScrolling ?? false) {
        _fixedColumnScrollController.jumpTo(_verticalScrollController.offset);
      }
    }
  }

  void _syncHorizontalScroll() {
    _rightHeaderHorizontal.addListener(() {
      if (_rightBodyHorizontal.hasClients &&
          _rightBodyHorizontal.offset != _rightHeaderHorizontal.offset) {
        _rightBodyHorizontal.jumpTo(_rightHeaderHorizontal.offset);
      }
    });

    _rightBodyHorizontal.addListener(() {
      if (_rightHeaderHorizontal.hasClients &&
          _rightHeaderHorizontal.offset != _rightBodyHorizontal.offset) {
        _rightHeaderHorizontal.jumpTo(_rightBodyHorizontal.offset);
      }
    });
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
    originalQuantities.clear();
    originalEachQuantities.clear();
    _verticalScrollController.dispose();
    _fixedColumnScrollController.dispose();
    _rightHeaderHorizontal.dispose();
    _rightBodyHorizontal.dispose();
    _isSubmitting.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<PermissionProvider>();

    final canReturnGRN = permission.hasEditAction('grns', 'return_grn');

    // 🔥 BLOCK FULL SCREEN
    // if (permission.permissions.isEmpty) {
    //   return const Scaffold(
    //     body: Center(child: Text("Loading permissions...")),
    //   );
    // }

    // if (!canReturnGRN) {
    //   return Scaffold(body: Center(child: Text("You don't have permission")));
    // }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRN No: ${grn.randomId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Text(
                          'Vendor: ${grn.vendorName ?? 'N/A'}',
                          style: const TextStyle(fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      Text('Date: ${formatDate(grn.grnDate)}'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14.0),

            // Return Options Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: isReturnAllEnabledNotifier,
                builder: (context, isReturnAllEnabled, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Consumer<GRNProvider>(
                              builder: (context, grnProvider, child) {
                                if (grnProvider.isLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (grnProvider.error != null) {
                                  return Text(
                                    grnProvider.error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13.0,
                                    ),
                                  );
                                }

                                final reasons = List<String>.from(
                                  grnProvider.returnReasons,
                                );

                                return ValueListenableBuilder<Map<int, String>>(
                                  valueListenable: itemReasonsNotifier,
                                  builder: (context, itemReasons, _) {
                                    return Autocomplete<String>(
                                      optionsBuilder:
                                          (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return reasons;
                                            }

                                            return reasons.where(
                                              (reason) =>
                                                  reason.toLowerCase().contains(
                                                    textEditingValue.text
                                                        .toLowerCase(),
                                                  ),
                                            );
                                          },

                                      onSelected: (String selection) {
                                        if (isReturnAllEnabled) {
                                          final updatedReasons =
                                              <int, String>{};
                                          for (
                                            int i = 0;
                                            i < (grn.itemDetails?.length ?? 0);
                                            i++
                                          ) {
                                            updatedReasons[i] = selection;
                                          }
                                          itemReasonsNotifier.value =
                                              updatedReasons;
                                          _updateItems();
                                        }

                                        FocusScope.of(context).unfocus();
                                      },

                                      fieldViewBuilder:
                                          (
                                            BuildContext context,
                                            TextEditingController
                                            textEditingController,
                                            FocusNode focusNode,
                                            VoidCallback onFieldSubmitted,
                                          ) {
                                            return ValueListenableBuilder<
                                              TextEditingValue
                                            >(
                                              valueListenable:
                                                  textEditingController,
                                              builder: (context, value, _) {
                                                return TextField(
                                                  controller:
                                                      textEditingController,
                                                  focusNode: focusNode,

                                                  onTap: () {
                                                    focusNode.requestFocus();
                                                  },

                                                  onChanged: (value) {
                                                    if (isReturnAllEnabled) {
                                                      final updatedReasons =
                                                          <int, String>{};
                                                      for (
                                                        int i = 0;
                                                        i <
                                                            (grn
                                                                    .itemDetails
                                                                    ?.length ??
                                                                0);
                                                        i++
                                                      ) {
                                                        updatedReasons[i] =
                                                            value;
                                                      }
                                                      itemReasonsNotifier
                                                              .value =
                                                          updatedReasons;
                                                      _updateItems();
                                                    }
                                                  },

                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Return all Reason',

                                                    labelStyle: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                    floatingLabelStyle:
                                                        const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.black,
                                                        ),

                                                    hintText: 'Reason',
                                                    hintStyle: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),

                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),

                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300,
                                                              ),
                                                        ),

                                                    focusedBorder:
                                                        const OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  8,
                                                                ),
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .blueAccent,
                                                                width: 1.5,
                                                              ),
                                                        ),

                                                    isDense: true,
                                                  ),

                                                  enabled: isReturnAllEnabled,
                                                );
                                              },
                                            );
                                          },

                                      optionsViewBuilder:
                                          (
                                            BuildContext context,
                                            AutocompleteOnSelected<String>
                                            onSelected,
                                            Iterable<String> options,
                                          ) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                color: Colors.white,
                                                elevation: 4.0,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight: 200,
                                                      ),
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          final String option =
                                                              options.elementAt(
                                                                index,
                                                              );
                                                          return ListTile(
                                                            title: Text(
                                                              option,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                            dense: true,
                                                            onTap: () {
                                                              onSelected(
                                                                option,
                                                              );
                                                            },
                                                          );
                                                        },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 15),

                          Flexible(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isSpecificQuantityReturnNotifier,
                              builder: (context, isSpecificQuantityReturn, _) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          (!canReturnGRN ||
                                              isSpecificQuantityReturn)
                                          ? null
                                          : () {
                                              if (isReturnAllEnabled) {
                                                isReturnAllEnabledNotifier
                                                        .value =
                                                    false;
                                                scenarioNotifier.value = null;

                                                itemReasonsNotifier.value = {};
                                                itemsNotifier.value = null;

                                                selectedRowsNotifier
                                                    .value = List<bool>.filled(
                                                  grn.itemDetails?.length ?? 0,
                                                  false,
                                                );
                                              } else {
                                                itemReasonsNotifier.value = {};
                                                itemsNotifier.value = null;

                                                selectedRowsNotifier
                                                    .value = List<bool>.filled(
                                                  grn.itemDetails?.length ?? 0,
                                                  false,
                                                );

                                                isReturnAllEnabledNotifier
                                                        .value =
                                                    true;
                                                isSpecificQuantityReturnNotifier
                                                        .value =
                                                    false;
                                                scenarioNotifier.value = 'full';
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isReturnAllEnabled
                                            ? Colors.blueAccent
                                            : Colors.grey.shade300,
                                        foregroundColor: isReturnAllEnabled
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      child: const Text('Return All'),
                                    ),

                                    const SizedBox(height: 8),

                                    ElevatedButton(
                                      onPressed: isReturnAllEnabled
                                          ? null
                                          : () {
                                              if (isSpecificQuantityReturn) {
                                                isSpecificQuantityReturnNotifier
                                                        .value =
                                                    false;
                                                scenarioNotifier.value = null;

                                                selectedRowsNotifier
                                                    .value = List<bool>.filled(
                                                  grn.itemDetails?.length ?? 0,
                                                  false,
                                                );

                                                itemReasonsNotifier.value = {};
                                                itemsNotifier.value = null;
                                              } else {
                                                itemReasonsNotifier.value = {};
                                                itemsNotifier.value = null;

                                                selectedRowsNotifier
                                                    .value = List<bool>.filled(
                                                  grn.itemDetails?.length ?? 0,
                                                  false,
                                                );

                                                isSpecificQuantityReturnNotifier
                                                        .value =
                                                    true;
                                                isReturnAllEnabledNotifier
                                                        .value =
                                                    false;
                                                scenarioNotifier.value =
                                                    'quantity_wise';

                                                _updateItems();
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isSpecificQuantityReturn
                                            ? Colors.blueAccent
                                            : Colors.grey.shade300,
                                        foregroundColor:
                                            isSpecificQuantityReturn
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      child: const Text('Return Specific'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16.0),
                    ],
                  );
                },
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 130,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Text(
                              'Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _rightHeaderHorizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Received Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Returned Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Returnable Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Return Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Nos',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Each Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        'Return Reason',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Unit Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Total Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Select',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: ValueListenableBuilder<List<bool>>(
                              valueListenable: selectedRowsNotifier,
                              builder: (context, selectedRows, _) {
                                return ListView.builder(
                                  controller: _fixedColumnScrollController,
                                  padding: EdgeInsets.zero,
                                  itemCount: grn.itemDetails?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final item = grn.itemDetails![index];
                                    return Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item.itemName ?? '',
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              controller: _rightBodyHorizontal,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                child: SingleChildScrollView(
                                  controller: _verticalScrollController,
                                  physics: const ClampingScrollPhysics(),
                                  child: ValueListenableBuilder<List<bool>>(
                                    valueListenable: selectedRowsNotifier,
                                    builder: (context, selectedRows, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable:
                                            enableReturnSelectedFieldsNotifier,
                                        builder: (context, enableReturnSelectedFields, _) {
                                          return ValueListenableBuilder<bool>(
                                            valueListenable:
                                                isSpecificQuantityReturnNotifier,
                                            builder: (context, isSpecificQuantityReturn, _) {
                                              return ValueListenableBuilder<
                                                Map<int, String>
                                              >(
                                                valueListenable:
                                                    itemReasonsNotifier,
                                                builder: (context, itemReasons, _) {
                                                  if (grn
                                                          .itemDetails
                                                          ?.isEmpty ??
                                                      true) {
                                                    return const Center(
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                          20.0,
                                                        ),
                                                        child: Text(
                                                          'No items found',
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  return Column(
                                                    children: List.generate(grn.itemDetails!.length, (
                                                      index,
                                                    ) {
                                                      final item = grn
                                                          .itemDetails![index];
                                                      final returnableQuantity =
                                                          (item.receivedQuantity ??
                                                              0) -
                                                          (item.returnedQuantity ??
                                                              0);
                                                      final returnQtyController =
                                                          TextEditingController(
                                                            text:
                                                                item.returnedQuantity
                                                                    ?.toStringAsFixed(
                                                                      2,
                                                                    ) ??
                                                                '0.00',
                                                          );

                                                      return Container(
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color: Colors
                                                                  .grey
                                                                  .shade300,
                                                            ),
                                                          ),
                                                          color: Colors.white,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildCenteredText(
                                                                item.receivedQuantity
                                                                        ?.toStringAsFixed(
                                                                          2,
                                                                        ) ??
                                                                    '0.00',
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildCenteredText(
                                                                item.returnedQuantity
                                                                        ?.toStringAsFixed(
                                                                          2,
                                                                        ) ??
                                                                    '0.00',
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildCenteredText(
                                                                returnableQuantity
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildReturnQtyField(
                                                                returnQtyController,
                                                                item,
                                                                index,
                                                                selectedRows,
                                                                isSpecificQuantityReturn,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildReadOnlyField(
                                                                item.nos?.toStringAsFixed(
                                                                      2,
                                                                    ) ??
                                                                    '0.00',
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildReadOnlyField(
                                                                item.eachQuantity
                                                                        ?.toStringAsFixed(
                                                                          2,
                                                                        ) ??
                                                                    '0.00',
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 180,
                                                              child: _buildReasonField(
                                                                item,
                                                                index,
                                                                selectedRows,
                                                                enableReturnSelectedFields,
                                                                isSpecificQuantityReturn,
                                                                itemReasons,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildCenteredText(
                                                                item.unitPrice
                                                                        ?.toStringAsFixed(
                                                                          2,
                                                                        ) ??
                                                                    '0.00',
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 120,
                                                              child: _buildCenteredText(
                                                                (item.totalPrice ??
                                                                        0)
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 80,
                                                              child: Center(
                                                                child: Checkbox(
                                                                  value:
                                                                      selectedRows[index],
                                                                  onChanged:
                                                                      (enableReturnSelectedFields ||
                                                                          isSpecificQuantityReturn)
                                                                      ? (
                                                                          bool?
                                                                          value,
                                                                        ) {
                                                                          final updatedSelectedRows =
                                                                              List<
                                                                                bool
                                                                              >.from(
                                                                                selectedRows,
                                                                              );
                                                                          updatedSelectedRows[index] =
                                                                              value ??
                                                                              false;
                                                                          selectedRowsNotifier.value =
                                                                              updatedSelectedRows;
                                                                          _updateItems();
                                                                        }
                                                                      : null,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canReturnGRN) ...[
                    _buildSubmitButton(),
                    const SizedBox(width: 12),
                    _buildCancelButton(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredText(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: TextEditingController(text: text),
        readOnly: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReturnQtyField(
    TextEditingController controller,
    ItemDetail item,
    int index,
    List<bool> selectedRows,
    bool isSpecificQuantityReturn,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        readOnly: true,
        enabled: isSpecificQuantityReturn && selectedRows[index],
        onTap: isSpecificQuantityReturn && selectedRows[index]
            ? () {
                showNumericCalculator(
                  context: context,
                  controller: controller,
                  varianceName: 'Return Quantity',
                  onValueSelected: () {
                    double newReturnedQty =
                        double.tryParse(controller.text) ?? 0;
                    double originalQty =
                        originalQuantities[item] ?? item.receivedQuantity ?? 0;
                    if (newReturnedQty <= originalQty) {
                      item.returnedQuantity = newReturnedQty;
                      item.receivedQuantity =
                          originalQty - item.returnedQuantity!;
                      _updateItemQuantities(item);
                      _recalculateItemTotals(item);
                      _recalculateGRNTotal();
                      _updateItems();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Returned quantity cannot exceed original received quantity',
                          ),
                        ),
                      );
                      controller.text =
                          item.returnedQuantity?.toStringAsFixed(2) ?? '0.00';
                    }
                  },
                  fieldType: '',
                );
              }
            : null,
        decoration: const InputDecoration(
          hintText: '0.00',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReasonField(
    ItemDetail item,
    int index,
    List<bool> selectedRows,
    bool enableReturnSelectedFields,
    bool isSpecificQuantityReturn,
    Map<int, String> itemReasons,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Consumer<GRNProvider>(
        builder: (context, grnProvider, child) {
          if (grnProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final returnReasons = List<String>.from(grnProvider.returnReasons);

          return Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return returnReasons;
              }

              return returnReasons
                  .where(
                    (reason) => reason.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  )
                  .toList();
            },
            onSelected: (String selection) {
              final updatedReasons = Map<int, String>.from(itemReasons);
              updatedReasons[index] = selection;
              itemReasonsNotifier.value = updatedReasons;
              _updateItems();
              FocusScope.of(context).unfocus();
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  textEditingController.text = itemReasons[index] ?? '';
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onChanged: (value) {
                      final updatedReasons = Map<int, String>.from(itemReasons);
                      updatedReasons[index] = value;
                      itemReasonsNotifier.value = updatedReasons;
                      _updateItems();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Reason',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    enabled:
                        (enableReturnSelectedFields ||
                            isSpecificQuantityReturn) &&
                        selectedRows[index],
                    style: const TextStyle(fontSize: 12),
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Colors.white,
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option,
                                style: const TextStyle(fontSize: 12),
                              ),
                              dense: true,
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    final permission = context.watch<PermissionProvider>(); // 🔥 ADD THIS

    final canReturnGRN = permission.hasEditAction(
      'grns',
      'return_grn',
    ); // 🔥 ADD THIS

    return ValueListenableBuilder<String?>(
      valueListenable: scenarioNotifier,
      builder: (context, scenario, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: returnDateNotifier,
          builder: (context, returnDate, _) {
            return ValueListenableBuilder<List<Map<String, dynamic>>?>(
              valueListenable: itemsNotifier,
              builder: (context, items, _) {
                return ValueListenableBuilder<Map<int, String>>(
                  valueListenable: itemReasonsNotifier,
                  builder: (context, itemReasons, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _isSubmitting,
                      builder: (context, submitting, _) {
                        final isDisabled =
                            !canReturnGRN || // 🔥 PERMISSION CHECK
                            scenario == null ||
                            returnDate == null ||
                            (scenario == 'partial' &&
                                (items == null || items.isEmpty));

                        return ElevatedButton(
                          onPressed: (isDisabled || submitting)
                              ? null
                              : () async {
                                  if (_isSubmitting.value) return;
                                  _isSubmitting.value = true;

                                  try {
                                    await _submitReturn();
                                  } finally {
                                    _isSubmitting.value = false;
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Return',
                                  style: TextStyle(fontSize: 16),
                                ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        minimumSize: const Size(120, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
    );
  }

  Future<void> _submitReturn() async {
    final permission = context.read<PermissionProvider>();

    if (!permission.hasEditAction('grns', 'return_grn')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No permission")));
      return;
    }
    if (scenarioNotifier.value == null || returnDateNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a return scenario and date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (scenarioNotifier.value == 'full') {
      final reason = itemReasonsNotifier.value.isNotEmpty
          ? itemReasonsNotifier.value.values.first
          : '';

      if (reason.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter return reason'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (scenarioNotifier.value == 'quantity_wise') {
      final selectedIndexes = selectedRowsNotifier.value
          .asMap()
          .entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      if (selectedIndexes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one item to return'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      for (final index in selectedIndexes) {
        final reason = itemReasonsNotifier.value[index] ?? '';

        if (reason.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter return reason for selected items'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    bool isValid = true;
    String? errorMessage;

    if (scenarioNotifier.value == 'full') {
      if (itemReasonsNotifier.value.isEmpty ||
          itemReasonsNotifier.value.values.every(
            (reason) => reason.trim().isEmpty,
          )) {
        isValid = false;
        errorMessage = 'Please enter a reason for full return.';
      }
    } else {
      for (int i = 0; i < grn.itemDetails!.length; i++) {
        if (!selectedRowsNotifier.value[i]) continue;

        final item = grn.itemDetails![i];
        final reason = itemReasonsNotifier.value[i] ?? '';
        final returnQty = item.returnedQuantity ?? 0;
        final originalQty =
            originalQuantities[item] ?? item.receivedQuantity ?? 0;

        if (reason.trim().isEmpty) {
          isValid = false;
          errorMessage = 'Please enter a reason for selected items.';
          break;
        }

        if (returnQty > originalQty) {
          isValid = false;
          errorMessage = 'Returned quantity cannot exceed received quantity.';
          break;
        }
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Validation failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
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
        ? _buildFullReturnItems()
        : itemsNotifier.value
              ?.where(
                (item) =>
                    item['itemId'] != null &&
                    item['itemId'].toString().isNotEmpty,
              )
              .map((item) => ReturnItem.fromMap(item))
              .toList();

    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    try {
      await grnProvider.returnGrn(
        grnId,
        ReturnGRNRequest(
          scenario: mapScenario(scenarioNotifier.value!),
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

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return processed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process return: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String mapScenario(String scenario) {
    if (scenario == "full") return "full";
    return "partial";
  }

  List<ReturnItem> _buildFullReturnItems() {
    final items = <ReturnItem>[];

    for (int i = 0; i < (grn.itemDetails?.length ?? 0); i++) {
      final item = grn.itemDetails![i];

      if (item.itemId != null &&
          item.itemId!.isNotEmpty &&
          _isValidObjectId(item.itemId!)) {
        final returnItem = ReturnItem(
          itemId: item.itemId!,
          nos: item.nos,
          eachQuantity: item.eachQuantity,
          returnReason: itemReasonsNotifier.value[i] ?? 'Full return',
          returnedQuantity: item.receivedQuantity,
        );

        items.add(returnItem);
      } else {}
    }

    if (items.isEmpty) {}

    return items;
  }

  bool _isValidObjectId(String id) {
    if (id.length != 24) return false;
    final hexRegex = RegExp(r'^[0-9a-fA-F]{24}$');
    return hexRegex.hasMatch(id);
  }

  void _updateItems() {
    if (scenarioNotifier.value == 'item_wise' ||
        scenarioNotifier.value == 'quantity_wise') {
      final updatedItems = grn.itemDetails
          ?.asMap()
          .entries
          .where((entry) => selectedRowsNotifier.value[entry.key])
          .where(
            (entry) =>
                entry.value.itemId != null &&
                entry.value.itemId!.isNotEmpty &&
                _isValidObjectId(entry.value.itemId!),
          )
          .map((entry) {
            final index = entry.key;
            final item = entry.value;

            return {
              'itemId': item.itemId,
              'nos': item.nos,
              'eachQuantity': item.eachQuantity,
              'returnReason': itemReasonsNotifier.value[index] ?? '',
              if (scenarioNotifier.value == 'quantity_wise')
                'returnedQuantity': item.returnedQuantity,
            };
          })
          .toList();

      itemsNotifier.value = updatedItems;
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
  }

  void _recalculateGRNTotal() {
    grn.totalReceivedAmount =
        grn.itemDetails?.fold(
          0.0,
          (total, item) => total! + (item.finalPrice ?? 0),
        ) ??
        0.0;
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'No Date';
    try {
      final DateTime parsedDate = DateTime.parse(date).toUtc().toLocal();
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date ?? 'No Date';
    }
  }
}
