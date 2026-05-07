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

    // CONNECTIVITY PROVIDER
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    final poProvider = Provider.of<POProvider>(context, listen: false);

    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    final apInvoiceProvider = Provider.of<APInvoiceProvider>(
      context,
      listen: false,
    );

    final outgoingPaymentProvider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );

    // AUTO REFRESH ON INTERNET RECONNECT
    connectivityProvider.onReconnect = () async {
      try {
        await poProvider.fetchPOsWithFilters(clearExisting: true);

        await grnProvider.fetchFilteredGRNs();

        await apInvoiceProvider.fetchAPInvoices();

        await outgoingPaymentProvider.fetchPayments();
      } catch (e) {
        debugPrint('Error during auto-refresh on reconnect: $e');
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
