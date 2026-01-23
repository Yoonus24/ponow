import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/pdfs/approved_pdf.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/widgets/approved po/approved_po_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ApprovedPOWidget extends StatefulWidget {
  final PO po;
  final POProvider poProvider;

  const ApprovedPOWidget({
    super.key,
    required this.po,
    required this.poProvider,
  });

  @override
  _ApprovedPOWidgetState createState() => _ApprovedPOWidgetState();
}

class _ApprovedPOWidgetState extends State<ApprovedPOWidget> {
  late PO po;

  @override
  void initState() {
    super.initState();
    po = widget.po;
  }

  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ApprovedPODialog(
          po: po,
          poProvider: widget.poProvider,
          onUpdated: () async {
            final provider = Provider.of<POProvider>(context, listen: false);
            await provider.fetchPOs();
            provider.notifyListeners();
          },
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.blueAccent],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header with PO No and buttons - ALIGNED PROPERLY
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Changed to center
                children: [
                  Expanded(
                    child: Text(
                      'PO No: ${po.randomId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showItemDetails(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () async {
                          try {
                            final poService = PurchaseOrderService();
                            final purchaseOrderId = po.purchaseOrderId;

                            final pdfFile = await poService
                                .generatePurchaseOrderPdf(purchaseOrderId);

                            await Printing.layoutPdf(
                              onLayout: (_) => pdfFile.readAsBytesSync(),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PDF generated successfully'),
                              ),
                            );
                          } catch (e) {
                            print("PDF error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to generate PDF: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // Vendor Name
              Text(
                'Vendor: ${po.vendorName ?? 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),
              // Total Order Amount
              Text(
                'Total Order Amount: ${po.pendingOrderAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),
              // Order Date
              Text(
                'Order Date: ${po.orderDate != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(po.orderDate!)) : 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
