import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import '../../models/vendorpurchasemodel.dart';

class VendorAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final PurchaseOrderNotifier notifier;
  final POProvider poProvider;
  final Function(String) onVendorSelected;

  const VendorAutocomplete({
    super.key,
    required this.controller,
    required this.notifier,
    required this.poProvider,
    required this.onVendorSelected,
  });

  @override
  State<VendorAutocomplete> createState() => _VendorAutocompleteState();
}

class _VendorAutocompleteState extends State<VendorAutocomplete> {
  Timer? _debounceTimer;

  final ValueNotifier<List<String>> _displayedVendors =
      ValueNotifier<List<String>>([]);

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);

  final Map<String, VendorAll> _vendorCache = {};
  List<VendorAll> _allVendors = [];

  int _skip = 0;
  bool _hasMore = true;
  String _currentQuery = '';
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _loadInitialVendors();
  }

  Future<void> _loadInitialVendors() async {
    _isLoading.value = true;

    _skip = 0;
    _hasMore = true;

    final fetched = await widget.poProvider.fetchingAllVendors(
      vendorName: '',
      skip: 0,
      limit: _limit,
      append: false,
    );

    _allVendors = fetched;

    _displayedVendors.value = _allVendors.map((e) => e.vendorName).toList();

    _skip += fetched.length;

    _isLoading.value = false;
  }


  void _search(String query) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        await _loadInitialVendors();
        return;
      }

      _isLoading.value = true;

      _skip = 0;
      _hasMore = true;
      _currentQuery = query;

      final fetched = await widget.poProvider.fetchingAllVendors(
        vendorName: query,
        skip: _skip,
        limit: _limit,
        append: false,
      );

      _allVendors = fetched;

      _displayedVendors.value = _allVendors.map((e) => e.vendorName).toList();

      _skip += fetched.length;
      _hasMore = fetched.length == _limit;

      _isLoading.value = false;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore.value) return;

    _isLoadingMore.value = true;

    final fetched = await widget.poProvider.fetchingAllVendors(
      vendorName: _currentQuery,
      skip: _skip,
      limit: _limit,
      append: true,
    );

    if (fetched.isEmpty) {
      _hasMore = false;
    } else {
      _allVendors.addAll(fetched);

      _displayedVendors.value = _allVendors.map((e) => e.vendorName).toList();

      _skip += fetched.length;

      if (fetched.length < _limit) {
        _hasMore = false;
      }
    }

    _isLoadingMore.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _displayedVendors,
      builder: (context, vendorList, _) {
        return Autocomplete<String>(
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();

            if (query.isEmpty) {
              return vendorList;
            }

            return vendorList.where(
              (vendor) => vendor.toLowerCase().contains(query),
            );
          },

          onSelected: (name) {
            widget.controller.text = name;

            widget.notifier.vendorAllList = _allVendors;
            widget.notifier.setSelectedVendor(name);
            widget.onVendorSelected(name);

            FocusManager.instance.primaryFocus?.unfocus();
          },

          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
                child: Container(
                  width: 250,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >=
                          scroll.metrics.maxScrollExtent - 50) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isLoadingMore,
                      builder: (_, loadingMore, __) {
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: vendorList.length + (loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i < vendorList.length) {
                              final option = vendorList[i];

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
                                onTap: () => onSelected(option),
                              );
                            }

                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },

          fieldViewBuilder: (context, textController, focusNode, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (widget.controller.text != textController.text &&
                  widget.controller.text.isNotEmpty) {
                textController.text = widget.controller.text;
              }
            });

            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
              child: TextFormField(
                controller: textController,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Select Vendor',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
                    horizontal: 7,
                  ),
                  filled: true,
                  fillColor: Colors.white,

                  suffixIcon: ValueListenableBuilder<bool>(
                    valueListenable: _isLoading,
                    builder: (_, loading, __) {
                      if (loading) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (textController.text.isNotEmpty) {
                        return IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () async {
                            textController.clear();
                            widget.controller.clear();

                            _currentQuery = '';
                            _skip = 0;
                            _hasMore = true;

                            final fetched = await widget.poProvider
                                .fetchingAllVendors(
                                  vendorName: '',
                                  skip: 0,
                                  limit: _limit,
                                  append: false,
                                );

                            _allVendors = fetched;

                            _displayedVendors.value = _allVendors
                                .map((e) => e.vendorName)
                                .toList();

                            focusNode.requestFocus();
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select a vendor';
                  }
                  return null;
                },
                onChanged: (value) {
                  widget.controller.text = value;
                  _search(value);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _displayedVendors.dispose();
    _isLoading.dispose();
    _isLoadingMore.dispose();
    super.dispose();
  }
}
