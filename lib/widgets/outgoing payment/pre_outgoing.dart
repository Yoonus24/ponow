import 'package:flutter/material.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/payment_dialogue.dart';
import 'package:provider/provider.dart';

import '../../models/outgoing.dart';
import '../../providers/outgoing_payment_provider.dart';
import '../../providers/po_provider.dart';

class PreOutgoing extends StatefulWidget {
  const PreOutgoing({super.key});

  @override
  State<PreOutgoing> createState() => _PreOutgoingState();
}

class _PreOutgoingState extends State<PreOutgoing> {
  final TextEditingController _vendorSearchController = TextEditingController();

  final FocusNode _vendorFocusNode = FocusNode();

  String? _selectedVendor;

  final int _skip = 0;
  final int _limit = 50;

  // 🔹 Called when user types in vendor field
  void _onVendorSearchChanged(String value) {
    context.read<POProvider>().fetchingVendors(
      vendorName: value.trim(),
      skip: 0,
      limit: _limit,
    );
  }

  @override
  void initState() {
    super.initState();

    final poProvider = context.read<POProvider>();
    poProvider.initVendorScrollListener();

    // ✅ SAFE: call provider AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      poProvider.fetchingVendors(vendorName: '', skip: _skip, limit: _limit);
    });
  }

  @override
  void dispose() {
    _vendorSearchController.dispose();
    _vendorFocusNode.dispose();
    super.dispose();
  }

  void _showVendorDialog(String vendorName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vendor Selected'),
          content: Text('Selected Vendor: $vendorName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentDialog(vendorName);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('PAY'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(String vendorName) {
    showDialog(
      context: context,
      builder: (context) {
        return PaymentDialog(
          totalPayableAmount: 0.0,
          isBulkPayment: false,
          onPaymentConfirmed:
              (
                String paymentType,
                double amount,
                String paymentMode,
                String paymentMethod,
                Map<String, dynamic> transactionDetails,
              ) async {
                if (!mounted) return;

                final outgoingProvider = context
                    .read<OutgoingPaymentProvider>();

                String status;
                switch (paymentType) {
                  case 'full':
                    status = 'Fully Paid';
                    break;
                  case 'partial':
                    status = 'Partially Paid';
                    break;
                  case 'advance':
                    status = 'Advance Paid';
                    break;
                  default:
                    status = 'Pending';
                }

                double? fullPaymentAmount;
                double? partialAmount;
                double? advanceAmount;

                if (status == 'Fully Paid') fullPaymentAmount = amount;
                if (status == 'Partially Paid') partialAmount = amount;
                if (status == 'Advance Paid') advanceAmount = amount;

                final outgoing = Outgoing(
                  outgoingId: _generateOutgoingId(),
                  vendorName: vendorName,
                  createdDate: DateTime.now(),
                  status: status,
                  paymentType: paymentType,
                  totalPayableAmount: amount,
                  paymentMode: paymentMode,
                  paymentMethod: paymentMethod,
                  paymentDate: DateTime.now(),
                  fullPaymentAmount: fullPaymentAmount,
                  partialAmount: partialAmount,
                  advanceAmount: advanceAmount,
                );

                final outgoingId = await outgoingProvider.saveOutgoingPayment(
                  outgoing,
                );

                await outgoingProvider.processOutgoingPayment(outgoingId);

                if (!mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Payment done')));

                Navigator.pop(context);
              },
        );
      },
    );
  }

  String _generateOutgoingId() {
    return 'OUT-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<POProvider>(
            builder: (context, poProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 TITLE + SEARCH
                  Row(
                    children: [
                      Text(
                        'Pre Outgoing',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),

                      /// 🔹 VENDOR AUTOCOMPLETE
                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final input = textEditingValue.text.toLowerCase();

                            if (input.isEmpty) {
                              return poProvider.filteredVendorNames;
                            }

                            return poProvider.filteredVendorNames.where(
                              (v) => v.toLowerCase().contains(input),
                            );
                          },
                          onSelected: (selectedVendor) {
                            _selectedVendor = selectedVendor;
                            _vendorSearchController.text = selectedVendor;
                            FocusScope.of(context).unfocus();
                            _showVendorDialog(selectedVendor);
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, _) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: _vendorFocusNode,
                                  onChanged:
                                      _onVendorSearchChanged, // ✅ CORRECT PLACE
                                  decoration: const InputDecoration(
                                    labelText: 'Search Vendor',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                );
                              },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Material(
                              elevation: 4,
                              child: SizedBox(
                                height: 300,
                                child: ListView.builder(
                                  controller: poProvider.vendorScrollController,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: Center(
                      child: Text(
                        _selectedVendor != null
                            ? 'Selected Vendor: $_selectedVendor'
                            : 'Please select a vendor',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
