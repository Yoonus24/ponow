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
  final bool hasError;
  final bool isPreloading;

  const ItemAutocomplete({
    super.key,
    required this.controller,
    required this.notifier,
    required this.poProvider,
    required this.onItemSelected,
    this.hasError = false,
    this.isPreloading = false,
  });

  @override
  State<ItemAutocomplete> createState() => _ItemAutocompleteState();
}

class _ItemAutocompleteState extends State<ItemAutocomplete> {
  Timer? _debounceTimer;
  final ValueNotifier<List<String>> _displayedItemsNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');

  int _skip = 0;
  bool _hasMore = true;
  String _currentQuery = '';
  final int _limit = 50;
  bool _isDisposed = false;
  final Map<String, PurchaseItem> _itemCache = {};
  List<PurchaseItem> _allPurchaseItems = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    if (_isDisposed) return;

    _isLoadingNotifier.value = true;

    try {
      _allPurchaseItems = widget.poProvider.purchaseItems;

      _displayedItemsNotifier.value = _allPurchaseItems
          .map((e) => e.itemName ?? '')
          .toList();
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> _filterItems(String query) async {
    final q = query.trim().toLowerCase();

    // ✅ Empty na clear
    if (q.isEmpty) {
      _displayedItemsNotifier.value = [];
      return;
    }

    final results = await widget.poProvider.searchPurchaseItems(
      query: q,
      skip: 0,
      limit: 50,
      append: false,
    );

    // ✅ Exact match first
    results.sort((a, b) {
      final aName = (a.itemName ?? '').toLowerCase();
      final bName = (b.itemName ?? '').toLowerCase();

      // 1. Exact match highest priority
      if (aName == q && bName != q) return -1;
      if (bName == q && aName != q) return 1;

      // 2. Starts with query second priority
      if (aName.startsWith(q) && !bName.startsWith(q)) return -1;
      if (bName.startsWith(q) && !aName.startsWith(q)) return 1;

      // 3. Contains query third priority
      if (aName.contains(q) && !bName.contains(q)) return -1;
      if (bName.contains(q) && !aName.contains(q)) return 1;

      // 4. Alphabetical fallback
      return aName.compareTo(bName);
    });

    _allPurchaseItems = results;
    _cacheItems(results);

    _displayedItemsNotifier.value = results
        .map((e) => e.itemName ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _cacheItems(List<PurchaseItem> items) {
    for (var item in items) {
      if (item.itemName != null && item.itemName!.isNotEmpty) {
        _itemCache[item.itemName!] = item;
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isDisposed) return;
    if (_isLoadingMoreNotifier.value || !_hasMore) return;

    _isLoadingMoreNotifier.value = true;

    try {
      final newItems = await widget.poProvider.searchPurchaseItems(
        query: _currentQuery,
        skip: _skip,
        limit: _limit,
        append: true,
      );

      if (_isDisposed) return;

      if (newItems.isEmpty) {
        _hasMore = false;
        return;
      }

      _cacheItems(newItems);

      for (var item in newItems) {
        if (!_allPurchaseItems.any(
          (existing) => existing.itemName == item.itemName,
        )) {
          _allPurchaseItems.add(item);
        }
      }

      final newNames = newItems
          .map((e) => e.itemName ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      _displayedItemsNotifier.value = [
        ...{..._displayedItemsNotifier.value, ...newNames},
      ];

      _skip += _limit;
      _hasMore = newItems.length == _limit;
    } catch (e) {
      if (!_isDisposed) {
        debugPrint("Load more error: $e");
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingMoreNotifier.value = false;
      }
    }
  }

  PurchaseItem? _findItemByName(String itemName) {
    final normalizedName = itemName.trim().toLowerCase();

    // ✅ Check cache first
    for (var entry in _itemCache.entries) {
      if (entry.key.trim().toLowerCase() == normalizedName) {
        return entry.value;
      }
    }

    // ✅ Check loaded purchase items
    for (var item in _allPurchaseItems) {
      final currentName = item.itemName?.trim().toLowerCase();

      if (currentName == normalizedName) {
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
        optionsBuilder: (TextEditingValue textEditingValue) async {
          final input = textEditingValue.text.trim().toLowerCase();

          _currentQuery = input;

          _searchDebounce?.cancel();

          await Future.delayed(const Duration(milliseconds: 300));

          if (input != _currentQuery) {
            return [];
          }

          await _filterItems(input);

          if (_displayedItemsNotifier.value.isEmpty && input.isNotEmpty) {
            return ['__NO_ITEM_FOUND__'];
          }

          return _displayedItemsNotifier.value;
        },
        onSelected: (selectedItemName) async {
          widget.controller.text = selectedItemName;

          final selectedItem = _findItemByName(selectedItemName);

          if (selectedItem != null) {
            print("✅ ITEM FOUND FROM CACHE");
            print("✅ ITEM CODE = ${selectedItem.itemCode}");

            widget.notifier.updateItemDetailsFromCache(selectedItem);
            _updateItemDetailsDirectly(selectedItem);
          } else {
            try {
              final results = await widget.poProvider.searchPurchaseItems(
                query: selectedItemName,
                skip: 0,
                limit: 10,
                append: false,
              );

              final foundItem = results.firstWhere(
                (item) =>
                    item.itemName?.trim().toLowerCase() ==
                    selectedItemName.trim().toLowerCase(),
                orElse: () =>
                    throw Exception("Item not found: $selectedItemName"),
              );

              print("✅ ITEM FOUND FROM API");
              print("✅ ITEM CODE = ${foundItem.itemCode}");

              _itemCache[selectedItemName] = foundItem;

              if (!_allPurchaseItems.any(
                (item) =>
                    item.itemName?.trim().toLowerCase() ==
                    foundItem.itemName?.trim().toLowerCase(),
              )) {
                _allPurchaseItems.add(foundItem);
              }

              widget.notifier.updateItemDetailsFromCache(foundItem);
              _updateItemDetailsDirectly(foundItem);
            } catch (e) {
              debugPrint("❌ Error fetching item details: $e");
            }
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

              final isLoading = widget.isPreloading;

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
                child: TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,

                  enabled: !isLoading,
                  readOnly: isLoading,

                  style: const TextStyle(fontSize: 14),

                  decoration: InputDecoration(
                    labelText: 'Select Item*',
                    floatingLabelBehavior: FloatingLabelBehavior.never,

                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: widget.hasError
                          ? Colors.red.shade700
                          : Colors.grey.shade800,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade500),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? Colors.red.shade400
                            : Colors.grey.shade500,
                        width: widget.hasError ? 2 : 1,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? Colors.red.shade700
                            : const Color.fromARGB(255, 74, 122, 227),
                        width: 2,
                      ),
                    ),

                    errorText: widget.hasError ? " " : null,

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),

                    filled: true,
                    fillColor: isLoading ? Colors.grey.shade200 : Colors.white,

                    suffixIcon: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _buildSuffixIcon(textEditingController, focusNode),
                  ),
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
                  final optionList = options.toList();

                  return Container(
                    width: 250,
                    constraints: BoxConstraints(
                      maxHeight: min(optionList.length * 50.0, 200),
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
                                optionList.length + (isLoadingMore ? 1 : 0),

                            itemBuilder: (context, index) {
                              if (index < optionList.length) {
                                final option = optionList[index];

                                /// ✅ NO ITEM FOUND UI
                                if (option == '__NO_ITEM_FOUND__') {
                                  return const ListTile(
                                    enabled: false,
                                    title: Text(
                                      'Item not found',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }

                                /// ✅ NORMAL ITEMS
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

                              /// ✅ LOAD MORE LOADER
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
    print("📍 SELECTED ITEM LOCATION ID: ${item.locationId}");
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
            padding: EdgeInsets.all(10),
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (textEditingController.text.isNotEmpty) {
          return IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              textEditingController.clear();
              widget.controller.clear();
              widget.onItemSelected('');

              widget.notifier.safeControllerAction(() {
                widget.notifier.existingPriceController.clear();
                widget.notifier.newPriceController.clear();
                widget.notifier.taxPercentageController.clear();
                widget.notifier.uomController.clear();
                widget.notifier.eachQuantityController.clear();
                widget.notifier.quantityController.clear();
                widget.notifier.befTaxDiscountController.clear();
                widget.notifier.afTaxDiscountController.clear();
              });

              _skip = 0;
              _hasMore = true;
              _currentQuery = '';

              if (!_isDisposed) {
                _isLoadingNotifier.value = true;
              }

              try {
                // await widget.poProvider.preloadAllPurchaseItems();
                if (_isDisposed) return;
                _allPurchaseItems = widget.poProvider.purchaseItems;
                _displayedItemsNotifier.value = _allPurchaseItems
                    .map((e) => e.itemName ?? '')
                    .toList();
              } finally {
                if (!_isDisposed) {
                  _isLoadingNotifier.value = false;
                }
              }

              focusNode.requestFocus();
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _searchDebounce?.cancel();

    _displayedItemsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isLoadingMoreNotifier.dispose();
    _queryNotifier.dispose();

    super.dispose();
  }
}
