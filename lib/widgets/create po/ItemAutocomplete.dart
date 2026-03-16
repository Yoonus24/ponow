// ignore_for_file: unnecessary_null_comparison, unnecessary_non_null_assertion, dead_null_aware_expression, invalid_null_aware_operator, empty_catches

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import '../../models/vendorpurchasemodel.dart';

class ItemAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final PurchaseOrderNotifier notifier;
  final POProvider poProvider;
  final Function(String) onItemSelected;
  static const double _fieldHeight = 60;

  const ItemAutocomplete({
    super.key,
    required this.controller,
    required this.notifier,
    required this.poProvider,
    required this.onItemSelected,
  });

  @override
  State<ItemAutocomplete> createState() => _ItemAutocompleteState();
}

class _ItemAutocompleteState extends State<ItemAutocomplete> {
  Timer? _debounceTimer;
  List<String> _allItemNames = [];
  final ValueNotifier<List<String>> _displayedItemsNotifier =
      ValueNotifier<List<String>>([]);

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');

  int _skip = 0;
  bool _hasMore = true;
  String _currentQuery = '';
  final int _limit = 50;

  final Map<String, PurchaseItem> _itemCache = {};
  List<PurchaseItem> _allPurchaseItems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
  }

  Future<void> _loadInitialItems() async {
    while (widget.poProvider.purchaseItems.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _allPurchaseItems = List.from(widget.poProvider.purchaseItems);

    _displayedItemsNotifier.value = _allPurchaseItems
        .map((e) => e.itemName ?? '')
        .toList();
  }

  void _cacheItems(List<PurchaseItem> items) {
    for (var item in items) {
      if (item.itemName != null && item.itemName!.isNotEmpty) {
        _itemCache[item.itemName!] = item;
      }
    }
  }

  void _searchItems(String query) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) {
      _displayedItemsNotifier.value = _allPurchaseItems
          .map((e) => e.itemName ?? '')
          .toList();
      return;
    }

    _displayedItemsNotifier.value = _allPurchaseItems
        .where((item) => (item.itemName ?? '').toLowerCase().contains(q))
        .map((e) => e.itemName ?? '')
        .toList();
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMoreNotifier.value || !_hasMore) return;

    _isLoadingMoreNotifier.value = true;

    try {
      await widget.poProvider.searchPurchaseItems(
        query: _currentQuery,
        skip: _skip,
        limit: _limit,
        append: true,
      );

      final fetched = widget.poProvider.purchaseItems;

      if (fetched.isEmpty) {
        _hasMore = false;
        return;
      }

      final existingIds = _allPurchaseItems
          .map((i) => i.purchaseItemId)
          .toSet();

      final newItems = fetched
          .where((item) => !existingIds.contains(item.purchaseItemId))
          .toList();

      if (newItems.isEmpty) {
        _hasMore = false;
        return;
      }

      _cacheItems(newItems);

      _allPurchaseItems.addAll(newItems);

      final newNames = newItems
          .map((e) => e.itemName ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      _allItemNames.addAll(newNames);

      _displayedItemsNotifier.value = [
        ..._displayedItemsNotifier.value,
        ...newNames,
      ];

      _skip += newItems.length;

      _hasMore = newItems.length == _limit;
    } catch (e) {
    } finally {
      _isLoadingMoreNotifier.value = false;
    }
  }

  PurchaseItem? _findItemByName(String itemName) {
    if (_itemCache.containsKey(itemName)) {
      return _itemCache[itemName];
    }

    for (var item in _allPurchaseItems) {
      if (item.itemName == itemName) {
        _itemCache[itemName] = item;
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          final input = textEditingValue.text.trim();

          if (input != _currentQuery) {
            _searchItems(input);
          }

          return _displayedItemsNotifier.value;
        },

        onSelected: (selectedItemName) async {
          widget.controller.text = selectedItemName;
          final selectedItem = _findItemByName(selectedItemName);
          if (selectedItem != null) {
            widget.notifier.updateItemDetailsFromCache(selectedItem);
            _updateItemDetailsDirectly(selectedItem);
          } else {
            try {
              await widget.poProvider.searchPurchaseItems(
                query: selectedItemName,
                skip: 0,
                limit: 10,
                append: false,
              );

              final foundItem = widget.poProvider.purchaseItems.firstWhere(
                (item) =>
                    item.itemName?.toLowerCase() ==
                    selectedItemName.toLowerCase(),
                orElse: () {
                  return PurchaseItem(
                    itemName: selectedItemName,
                    purchasePrice: 0,
                    purchasetaxName: 0,
                    uom: '',
                    purchaseItemId: '',
                    purchasecategoryName: '',
                    purchasesubcategoryName: '',
                    hsnCode: '',
                  );
                },
              );

              if (foundItem.itemName?.isNotEmpty ?? false) {
                _itemCache[selectedItemName] = foundItem;
                _allPurchaseItems.add(foundItem);

                widget.notifier.updateItemDetailsFromCache(foundItem);
              } else {}
            } catch (e) {}
          }

          widget.onItemSelected(selectedItemName);

          Future.microtask(() {
            FocusManager.instance.primaryFocus?.unfocus();
          });
        },

        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.controller.text != textEditingController.text &&
                    widget.controller.text.isNotEmpty) {
                  textEditingController.text = widget.controller.text;
                }
              });

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
                child: TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Select Item*',
                    floatingLabelBehavior: FloatingLabelBehavior.never,

                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade500),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade500),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 74, 122, 227),
                        width: 2.0,
                      ),
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 40,
                    ),

                    suffixIcon: _buildSuffixIcon(
                      textEditingController,
                      focusNode,
                    ),

                    errorStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select an item';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    widget.controller.text = value;
                    _searchItems(value);
                  },
                ),
              );
            },

        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _displayedItemsNotifier,
                builder: (context, displayedItems, _) {
                  return Container(
                    width: 250,
                    constraints: BoxConstraints(
                      maxHeight: min(displayedItems.length * 50.0, 200),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification.metrics.pixels >=
                            scrollNotification.metrics.maxScrollExtent - 50) {
                          if (!_isLoadingMoreNotifier.value && _hasMore) {
                            _loadMoreItems();
                          }
                        }
                        return false;
                      },
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isLoadingMoreNotifier,
                        builder: (context, isLoadingMore, __) {
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount:
                                displayedItems.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < displayedItems.length) {
                                final option = displayedItems[index];

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 2,
                                  ),
                                  minVerticalPadding: 0,
                                  visualDensity: const VisualDensity(
                                    vertical: -3,
                                  ),
                                  title: Text(
                                    option,
                                    style: const TextStyle(fontSize: 13),
                                    softWrap: true,
                                    maxLines: null,
                                  ),
                                  onTap: () {
                                    onSelected(option);

                                    Future.microtask(() {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    });
                                  },
                                );
                              }

                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateItemDetailsDirectly(PurchaseItem item) {
    widget.notifier.safeControllerAction(() {
      widget.notifier.existingPriceController.text = item.purchasePrice
          .toStringAsFixed(2);
      widget.notifier.newPriceController.text = item.purchasePrice
          .toStringAsFixed(2);
      widget.notifier.taxPercentageController.text = item.purchasetaxName
          .toStringAsFixed(2);
      widget.notifier.uomController.text = item.uom;

      if (widget.notifier.befTaxDiscountController.text.isEmpty ||
          widget.notifier.befTaxDiscountController.text == '0') {
        widget.notifier.befTaxDiscountController.text = '0';
      }

      if (widget.notifier.afTaxDiscountController.text.isEmpty ||
          widget.notifier.afTaxDiscountController.text == '0') {
        widget.notifier.afTaxDiscountController.text = '0';
      }
    });

    widget.notifier.updateVariance();
  }

  Widget? _buildSuffixIcon(
    TextEditingController textEditingController,
    FocusNode focusNode,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          );
        }

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: textEditingController,
          builder: (context, value, __) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }

            return IconButton(
              icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
              tooltip: "Clear",
              onPressed: () {
                textEditingController.clear();
                widget.controller.clear();

                _queryNotifier.value = '';
                _currentQuery = '';

                // reset dropdown list
                _displayedItemsNotifier.value = _allPurchaseItems
                    .map((e) => e.itemName ?? '')
                    .toList();

                widget.onItemSelected('');

                focusNode.requestFocus();
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _displayedItemsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isLoadingMoreNotifier.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }
}
