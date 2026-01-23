import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:provider/provider.dart';

class APInvoicePopup extends StatelessWidget {
  final ApInvoice apinvoice;

  const APInvoicePopup({super.key, required this.apinvoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AP Invoice No: ${apinvoice.randomId}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Vendor: ${apinvoice.vendorName}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Date: ${apinvoice.createdDate}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey[300],
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 200,
                              child: Text(
                                'Item Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'UOM',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Stock Qty',
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
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),

                      // Data Rows
                      Column(
                        children: List.generate(
                          apinvoice.itemDetails?.length ?? 0,
                          (index) {
                            final item = apinvoice.itemDetails![index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: Text(item.itemName ?? ''),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(item.uom ?? ''),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text('${item.stockQuantity ?? 0}'),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      item.unitPrice?.toStringAsFixed(2) ??
                                          '0.00',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (apinvoice.invoiceId != null) {
                      Provider.of<APInvoiceProvider>(
                        context,
                        listen: false,
                      ).postOutgoingAndUpdateStatus(apinvoice.invoiceId!);
                      Navigator.of(context).pop();
                    } else {
                      // Handle the case where invoiceId is null
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invoice ID is missing')),
                      );
                    }
                  },
                  child: Text('Move to Outgoing Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
