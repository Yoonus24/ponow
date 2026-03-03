import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:purchaseorders2/providers/connectivity_provider.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();

    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    connectivityProvider.onReconnect = () async {

      try {
        await Provider.of<POProvider>(
          context,
          listen: false,
        ).fetchPOsWithFilters(clearExisting: true);

        await Provider.of<GRNProvider>(
          context,
          listen: false,
        ).fetchFilteredGRNs();

        await Provider.of<APInvoiceProvider>(
          context,
          listen: false,
        ).fetchAPInvoices();

        await Provider.of<OutgoingPaymentProvider>(
          context,
          listen: false,
        ).fetchPayments();
      } catch (e) {
        // Handle errors if needed
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
