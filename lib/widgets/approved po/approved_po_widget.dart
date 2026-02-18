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
  State<ApprovedPOWidget> createState() => _ApprovedPOWidgetState();
}

class _ApprovedPOWidgetState extends State<ApprovedPOWidget> {
  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ApprovedPODialog(
          po: widget.po,
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
            children: [
              // ===== HEADER =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'PO No: ${widget.po.randomId}',
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
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => _showItemDetails(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          try {
                            final poService = PurchaseOrderService();
                            final pdfFile = await poService
                                .generatePurchaseOrderPdf(
                                  widget.po.purchaseOrderId,
                                );

                            await Printing.layoutPdf(
                              onLayout: (_) => pdfFile.readAsBytesSync(),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('PDF failed: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== VENDOR =====
              Text(
                'Vendor: ${widget.po.vendorName ?? 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // ===== AMOUNT =====
              Text(
                'Total Order Amount: '
                '${widget.po.pendingOrderAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              // ===== DATE =====
              Text(
                'Order Date: '
                '${widget.po.orderDate != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(widget.po.orderDate!)) : 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
