// ignore_for_file: unused_local_variable, library_private_types_in_public_api, unnecessary_to_list_in_spreads, use_build_context_synchronously, unnecessary_non_null_assertion, unnecessary_null_comparison, avoid_print

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/grnitem.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import '../../../models/grn.dart';
import '../../../providers/grn_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/calculator_utils.dart';
import 'grn_return_logic.dart';

class GRNReturn extends StatefulWidget {
  final GRN grn;

  const GRNReturn({super.key, required this.grn});

  @override
  State<GRNReturn> createState() => _GRNReturnState();
}

class _GRNReturnState extends State<GRNReturn> {
  late GRNReturnLogic logic;

  @override
  void initState() {
    super.initState();
    logic = GRNReturnLogic(grn: widget.grn);
    Future.microtask(() {
      Provider.of<GRNProvider>(context, listen: false).fetchReturnReasons();
    });
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logic.setContext(context);
    final permission = context.watch<PermissionProvider>();
    final canReturnGRN = logic.getCanReturnGRN(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14.0),
            _buildReturnOptionsSection(canReturnGRN),
            Expanded(child: _buildItemsTable()),
            const SizedBox(height: 16.0),
            _buildActionButtons(canReturnGRN),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GRN No: ${logic.getGrnNo()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                width: 250,
                child: Text(
                  'Vendor: ${logic.getVendorName()}',
                  style: const TextStyle(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
              Text('Date: ${logic.getGrnDate()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnOptionsSection(bool canReturnGRN) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: logic.isReturnAllEnabledNotifier,
        builder: (context, isReturnAllEnabled, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildReturnAllReasonField(
                      isReturnAllEnabled,
                      canReturnGRN,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: _buildReturnButtons(
                      isReturnAllEnabled,
                      canReturnGRN,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReturnAllReasonField(
    bool isReturnAllEnabled,
    bool canReturnGRN,
  ) {
    return Consumer<GRNProvider>(
      builder: (context, grnProvider, child) {
        if (grnProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (grnProvider.error != null) {
          return Text(
            grnProvider.error!,
            style: const TextStyle(color: Colors.red, fontSize: 13.0),
          );
        }
        final reasons = List<String>.from(grnProvider.returnReasons);
        return ValueListenableBuilder<Map<int, String>>(
          valueListenable: logic.itemReasonsNotifier,
          builder: (context, itemReasons, _) {
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return reasons;
                return reasons.where(
                  (reason) => reason.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                if (isReturnAllEnabled) {
                  logic.setReturnAllReason(selection);
                }
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder:
                  (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: textEditingController,
                      builder: (context, value, _) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onTap: () => focusNode.requestFocus(),
                          onChanged: (value) {
                            if (isReturnAllEnabled) {
                              logic.setReturnAllReason(value);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Return all Reason',
                            labelStyle: const TextStyle(fontSize: 11),
                            floatingLabelStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                            ),
                            hintText: 'Reason',
                            hintStyle: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: Colors.blueAccent,
                                width: 1.5,
                              ),
                            ),
                            isDense: true,
                          ),
                          enabled: isReturnAllEnabled && canReturnGRN,
                        );
                      },
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
                        borderRadius: BorderRadius.circular(8),
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
        );
      },
    );
  }

  Widget _buildReturnButtons(bool isReturnAllEnabled, bool canReturnGRN) {
    return ValueListenableBuilder<bool>(
      valueListenable: logic.isSpecificQuantityReturnNotifier,
      builder: (context, isSpecificQuantityReturn, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: (!canReturnGRN || isSpecificQuantityReturn)
                  ? null
                  : () {
                      if (isReturnAllEnabled) {
                        logic.disableReturnAll();
                      } else {
                        logic.enableReturnAll();
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
              onPressed: (!canReturnGRN || isReturnAllEnabled)
                  ? null
                  : () {
                      if (isSpecificQuantityReturn) {
                        logic.disableSpecificQuantityReturn();
                      } else {
                        logic.enableSpecificQuantityReturn();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSpecificQuantityReturn
                    ? Colors.blueAccent
                    : Colors.grey.shade300,
                foregroundColor: isSpecificQuantityReturn
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text('Return Specific'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemsTable() {
    final items = logic.getItemDetails();
    if (items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFixedColumn(items),
                Expanded(child: _buildScrollableColumns(items)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: logic.rightHeaderHorizontal,
              physics: const ClampingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.only(left: 20, right: 20),
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
    );
  }

  Widget _buildFixedColumn(List<ItemDetail> items) {
    return SizedBox(
      width: 130,
      child: ValueListenableBuilder<List<bool>>(
        valueListenable: logic.selectedRowsNotifier,
        builder: (context, selectedRows, _) {
          return ListView.builder(
            controller: logic.fixedColumnScrollController,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
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
    );
  }

  Widget _buildScrollableColumns(List<ItemDetail> items) {
    return SingleChildScrollView(
      controller: logic.rightBodyHorizontal,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: SingleChildScrollView(
        controller: logic.verticalScrollController,
        physics: const ClampingScrollPhysics(),
        child: ValueListenableBuilder<List<bool>>(
          valueListenable: logic.selectedRowsNotifier,
          builder: (context, selectedRows, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: logic.isSpecificQuantityReturnNotifier,
              builder: (context, isSpecificQuantityReturn, _) {
                return ValueListenableBuilder<Map<int, String>>(
                  valueListenable: logic.itemReasonsNotifier,
                  builder: (context, itemReasons, _) {
                    return Column(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final returnableQuantity = logic.getReturnableQuantity(
                          item,
                        );
                        final returnQtyController = TextEditingController(
                          text:
                              item.returnedQuantity?.toStringAsFixed(2) ??
                              '0.00',
                        );
                        return Container(
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              _buildCenteredText(
                                item.receivedQuantity?.toStringAsFixed(2) ??
                                    '0.00',
                                width: 120,
                              ),
                              _buildCenteredText(
                                item.returnedQuantity?.toStringAsFixed(2) ??
                                    '0.00',
                                width: 120,
                              ),
                              _buildCenteredText(
                                returnableQuantity.toStringAsFixed(2),
                                width: 120,
                              ),
                              _buildReturnQtyField(
                                returnQtyController,
                                item,
                                index,
                                selectedRows,
                                isSpecificQuantityReturn,
                              ),
                              _buildReadOnlyField(
                                item.nos?.toStringAsFixed(2) ?? '0.00',
                                width: 120,
                              ),
                              _buildReadOnlyField(
                                item.eachQuantity?.toStringAsFixed(2) ?? '0.00',
                                width: 120,
                              ),
                              _buildReasonField(
                                item,
                                index,
                                selectedRows,
                                isSpecificQuantityReturn,
                                itemReasons,
                              ),
                              _buildCenteredText(
                                item.unitPrice?.toStringAsFixed(2) ?? '0.00',
                                width: 120,
                              ),
                              _buildCenteredText(
                                (item.totalPrice ?? 0).toStringAsFixed(2),
                                width: 120,
                              ),
                              _buildCheckbox(
                                index,
                                selectedRows,
                                isSpecificQuantityReturn,
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
        ),
      ),
    );
  }

  Widget _buildCenteredText(String text, {double width = 120}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String text, {double width = 120}) {
    return SizedBox(
      width: width,
      child: Container(
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
    return SizedBox(
      width: 120,
      child: Container(
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
                      double originalQty = logic.getOriginalQuantity(item);
                      if (newReturnedQty <= originalQty) {
                        logic.updateReturnQuantity(item, index, newReturnedQty);
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
      ),
    );
  }

  Widget _buildReasonField(
    ItemDetail item,
    int index,
    List<bool> selectedRows,
    bool isSpecificQuantityReturn,
    Map<int, String> itemReasons,
  ) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Consumer<GRNProvider>(
          builder: (context, grnProvider, child) {
            final returnReasons = List<String>.from(grnProvider.returnReasons);
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return returnReasons;
                return returnReasons.where(
                  (reason) => reason.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                logic.setItemReason(index, selection);
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
                      onChanged: (value) => logic.setItemReason(index, value),
                      decoration: const InputDecoration(
                        hintText: 'Reason',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      enabled: isSpecificQuantityReturn && selectedRows[index],
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
                            itemBuilder: (BuildContext context, int idx) {
                              final String option = options.elementAt(idx);
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
      ),
    );
  }

  Widget _buildCheckbox(
    int index,
    List<bool> selectedRows,
    bool isSpecificQuantityReturn,
  ) {
    return SizedBox(
      width: 80,
      child: Center(
        child: Checkbox(
          value: selectedRows[index],
          onChanged: isSpecificQuantityReturn
              ? (bool? value) => logic.updateSelectedRow(index, value ?? false)
              : null,
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool canReturnGRN) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (canReturnGRN) ...[
            ValueListenableBuilder<bool>(
              valueListenable: logic.isSubmitting,
              builder: (context, submitting, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: logic.scenarioNotifier,
                  builder: (context, scenario, _) {
                    final isDisabled = scenario == null;
                    return ElevatedButton(
                      onPressed: (isDisabled || submitting)
                          ? null
                          : () => logic.submitReturn(context),
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
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                minimumSize: const Size(120, 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
