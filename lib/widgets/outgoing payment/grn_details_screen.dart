import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';

class GRNDetailsDialog extends StatelessWidget {
  final GRN grn;

  const GRNDetailsDialog({super.key, required this.grn});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.center,
      insetPadding: isTablet
          ? const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0)
          : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? MediaQuery.of(context).size.width * 0.5 : 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('GRN No:', grn.randomId ?? 'N/A'),
                _buildInfoRow('Vendor:', grn.vendorName ?? 'N/A'),
                _buildInfoRow('Date:', _formatDate(grn.grnDate)),
                const SizedBox(height: 20),
                _buildItemsListView(),
                const SizedBox(height: 20),
                _buildSummarySection(),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildItemsListView() {
    if (grn.itemDetails == null || grn.itemDetails!.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[300],
            child: const Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    'Item Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'UOM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Count',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Received Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Total Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Tax',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Final Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Expiry Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ...grn.itemDetails!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Text('${index + 1}')),
                  SizedBox(
                    width: 150,
                    child: Text(
                      item.itemName ?? 'N/A',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 80, child: Text(item.uom ?? 'N/A')),
                  SizedBox(width: 80, child: Text(_formatNumber(item.nos))),
                  SizedBox(
                    width: 80,
                    child: Text(_formatNumber(item.eachQuantity)),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(_formatCurrency(item.unitPrice)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(_formatNumber(item.receivedQuantity)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(_formatCurrency(item.totalPrice)),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(_formatCurrency(item.taxAmount)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(_formatCurrency(item.finalPrice)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(_formatDate(item.expiryDate)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    // ✅ Item total (same as GRNModal)
    double itemTotal = 0.0;

    for (final item in grn.itemDetails ?? []) {
      itemTotal += item.finalPrice ?? 0.0;
    }

    // ✅ Freight
    final double freightAmount = grn.totalFreightAmount ?? 0.0;
    final double freightTax = grn.totalFreightTaxAmount ?? 0.0;
    final double freightTotal = freightAmount + freightTax;

    // ✅ Discount
    final double discount = grn.totalDiscount ?? grn.discountPrice ?? 0.0;

    // ✅ Round off
    final double roundOff = grn.roundOffAdjustment ?? 0.0;

    // ✅ Final total (same formula as GRNModal)
    final double finalTotal = itemTotal + freightTotal - discount + roundOff;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow('Items Total:', _formatCurrency(itemTotal)),

              _buildSummaryRow('Discount:', _formatCurrency(discount)),

              _buildSummaryRow(
                'Freight Amount:',
                _formatCurrency(freightAmount),
              ),

              _buildSummaryRow('Freight Tax:', _formatCurrency(freightTax)),

              _buildSummaryRow('Total Freight:', _formatCurrency(freightTotal)),

              if (roundOff != 0)
                _buildSummaryRow('Round Off:', _formatCurrency(roundOff)),

              const Divider(),

              _buildSummaryRow(
                'Final Total:',
                _formatCurrency(finalTotal),
                isBold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String _formatNumber(double? value) => value?.toStringAsFixed(2) ?? '0.00';
  String _formatCurrency(double? value) => value?.toStringAsFixed(2) ?? '0.00';
}
