import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import '../../models/po/vendorpurchasemodel.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialVendors();
    });
  }

  Future<void> _loadInitialVendors() async {
    if (widget.poProvider.vendorCache.isNotEmpty) {
      _allVendors = widget.poProvider.vendorCache;

      if (_currentQuery.isEmpty) {
        _displayedVendors.value = _allVendors
            .map((e) => e.vendorName)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      } else {
        _displayedVendors.value = _allVendors
            .where((v) => v.vendorName.toLowerCase().startsWith(_currentQuery))
            .map((e) => e.vendorName)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      }
      return;
    }

    _isLoading.value = true;

    final fetched = await widget.poProvider.fetchingAllVendors(
      vendorName: '',
      skip: 0,
      limit: 5000,
      append: false,
    );

    _allVendors = fetched;

    widget.poProvider.vendorCache = fetched;

    _displayedVendors.value = _allVendors
        .map((e) => e.vendorName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    _isLoading.value = false;
  }

  void _search(String query) {
    _currentQuery = query.toLowerCase().trim();

    final q = _currentQuery;

    if (q.isEmpty) {
      _displayedVendors.value = _allVendors
          .map((e) => e.vendorName)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      return;
    }

    _displayedVendors.value = _allVendors
        .where((v) => v.vendorName.toLowerCase().startsWith(q))
        .map((e) => e.vendorName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore.value) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_hasMore || _isLoadingMore.value) return;

      _isLoadingMore.value = true;

      try {
        final fetched = await widget.poProvider.fetchingAllVendors(
          vendorName: _currentQuery,
          skip: _skip,
          limit: _limit,
          append: true,
        );

        if (fetched.isEmpty) {
          _hasMore = false;
        } else {
          for (var vendor in fetched) {
            if (!_allVendors.any(
              (existing) => existing.vendorName == vendor.vendorName,
            )) {
              _allVendors.add(vendor);
            }
          }

          _displayedVendors.value = _allVendors
              .map((e) => e.vendorName)
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList();

          _skip += fetched.length;

          if (fetched.length < _limit) {
            _hasMore = false;
          }
        }
      } catch (e) {
        throw Exception("VENDOR_LOAD_MORE_ERROR");
      } finally {
        _isLoadingMore.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _displayedVendors,
      builder: (context, vendorList, _) {
        return Autocomplete<String>(
          optionsBuilder: (value) {
            /// ✅ No vendor found
            if (vendorList.isEmpty && value.text.trim().isNotEmpty) {
              return ['__NO_VENDOR_FOUND__'];
            }

            return vendorList;
          },

          onSelected: (name) {
            widget.controller.text = name;

            widget.notifier.vendorAllList = _allVendors;
            widget.notifier.setSelectedVendor(name);
            widget.onVendorSelected(name);

            // Clear validation immediately
            Form.of(context)?.validate();

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
                  constraints: BoxConstraints(
                    maxHeight: min(options.length * 48.0, 200),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scroll) {
                      if (scroll.metrics.pixels >=
                          scroll.metrics.maxScrollExtent - 50) {
                        if (_currentQuery.isEmpty &&
                            !_isLoadingMore.value &&
                            _hasMore) {
                          _loadMore();
                        }
                      }
                      return false;
                    },
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isLoadingMore,
                      builder: (_, loadingMore, __) {
                        final optionList = options.toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,

                          itemCount: optionList.length + (loadingMore ? 1 : 0),

                          itemBuilder: (_, i) {
                            if (i < optionList.length) {
                              final option = optionList[i];

                              ///NO VENDOR FOUND
                              if (option == '__NO_VENDOR_FOUND__') {
                                return const ListTile(
                                  enabled: false,
                                  title: Text(
                                    'Vendor not found',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }

                              ///NORMAL VENDOR
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

                            ///LOAD MORE
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
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
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
                          onPressed: () {
                            textController.clear();
                            widget.controller.clear();
                            widget.notifier.clearSelectedVendor();
                            widget.notifier.selectedVendor = '';
                            widget.notifier.selectedVendorDetails = null;

                            _currentQuery = '';

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
                    return '';
                  }
                  return null;
                },
                onChanged: (value) {
                  widget.controller.text = value;

                  // Revalidate the field immediately to clear the red border
                  Form.of(context)?.validate();

                  if (value.trim().isEmpty) {
                    widget.notifier.clearSelectedVendor();
                    widget.notifier.selectedVendor = '';
                    widget.notifier.selectedVendorDetails = null;

                    _currentQuery = '';

                    _displayedVendors.value = _allVendors
                        .map((e) => e.vendorName)
                        .where((e) => e.isNotEmpty)
                        .toSet()
                        .toList();
                  } else {
                    _search(value);
                  }
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
