import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';

class APViewInvoiceModal extends StatelessWidget {
  final ApInvoice apinvoice;

  const APViewInvoiceModal({super.key, required this.apinvoice});

@override
Widget build(BuildContext context) {
  double totalSgst = 0.0, totalCgst = 0.0;
  if (apinvoice.itemDetails != null) {
    for (var item in apinvoice.itemDetails!) {
      totalSgst += (item.sgst ?? 0.0);
      totalCgst += (item.cgst ?? 0.0);
    }
  }

  return Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(maxWidth: 1000),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            Text('Invoice No: ${apinvoice.randomId ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Vendor: ${apinvoice.vendorName ?? 'Unknown Vendor'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Date: ${_formatDate(apinvoice.invoiceDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Status: ${apinvoice.status ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12.0),

            // Custom Table using ListView
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[300],
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: _HeaderCell('No', 0)),
                        Expanded(flex: 3, child: _HeaderCell('Item Name', 0)),
                        Expanded(flex: 2, child: _HeaderCell('UOM', 0)),
                        Expanded(flex: 2, child: _HeaderCell('Qty', 0)),
                        Expanded(flex: 2, child: _HeaderCell('Stock Qty', 0)),
                        Expanded(flex: 2, child: _HeaderCell('BefTax', 0)),
                        Expanded(flex: 2, child: _HeaderCell('AfTax', 0)),
                        Expanded(flex: 2, child: _HeaderCell('Price', 0)),
                        Expanded(flex: 2, child: _HeaderCell('Total Price', 0)),
                        Expanded(flex: 2, child: _HeaderCell('Final Price', 0)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  // Data Rows
                  Column(
                    children: apinvoice.itemDetails?.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: _DataCell('${index + 1}', 0)),
                                Expanded(flex: 3, child: _DataCell(item.itemName ?? 'N/A', 0)),
                                Expanded(flex: 2, child: _DataCell(item.uom ?? 'N/A', 0)),
                                Expanded(flex: 2, child: _DataCell(_formatNumber(item.quantity), 0)),
                                Expanded(flex: 2, child: _DataCell(_formatNumber(item.stockQuantity), 0)),
                                Expanded(flex: 2, child: _DataCell(_formatNumber(item.befTaxDiscount), 0)),
                                Expanded(flex: 2, child: _DataCell(_formatNumber(item.afTaxDiscount), 0)),
                                Expanded(flex: 2, child: _DataCell(_formatCurrency(item.unitPrice), 0)),
                                Expanded(flex: 2, child: _DataCell(_formatNumber(item.totalPrice), 0)),
                                Expanded(flex: 2, child: _DataCell(_formatNumber(item.finalPrice), 0)),
                              ],
                            ),
                          );
                        }).toList() ??
                        [],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Discount: ${_formatCurrency(apinvoice.discountDetails)}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('SGST: ${totalSgst.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14)),
                  Text('CGST: ${totalCgst.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14)),
                  Text('Total Invoice Amount: ${_formatCurrency(apinvoice.invoiceAmount)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  static String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'No Date';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  static String _formatNumber(double? value) {
    return value?.toStringAsFixed(2) ?? '0.00';
  }

  static String _formatCurrency(double? value) {
    return '₹${value?.toStringAsFixed(2) ?? '0.00'}';
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final double width;

  const _DataCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.right,
      ),
    );
  }
}
