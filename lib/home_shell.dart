import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/template_provider.dart';

import 'package:purchaseorders2/screens/po_page.dart';
import 'package:purchaseorders2/screens/approved_po_page.dart';
import 'package:purchaseorders2/screens/grn_page.dart';
import 'package:purchaseorders2/screens/ap_invoice_page.dart';
import 'package:purchaseorders2/screens/outgoing_payment_page.dart';

import 'package:purchaseorders2/widgets/common_bottom_nav.dart';
import 'package:purchaseorders2/widgets/common_app_bar.dart';
import 'package:purchaseorders2/screens/create_po_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final PageController _pageController = PageController();

  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isOpeningCreatePO = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<PurchaseOrderNotifier>();

      notifier.fetchAllVendors1();
      notifier.fetchVendors1();
      notifier.fetchItems('');
      notifier.fetchBillingAddress1();
      notifier.fetchShippingAddress1();
    });
  }

  void _onTabChanged(int index) {
    _currentIndex.value = index;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openCreatePODialog() async {
    if (_isOpeningCreatePO.value) return;

    _isOpeningCreatePO.value = true;

    try {
      final notifier = context.read<PurchaseOrderNotifier>();

      if (notifier.vendorAllList.isEmpty) {
        notifier.fetchAllVendors1();
      }

      if (!mounted) return;

      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PurchaseOrderDialog(
          templateProvider: context.read<TemplateProvider>(),
        ),
      );

      CommonAppBar.selectedLabel.value = "Home";
      _onTabChanged(0);
    } catch (e) {
      debugPrint("Create PO dialog error: $e");
    } finally {
      if (mounted) {
        _isOpeningCreatePO.value = false;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    _isOpeningCreatePO.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          POPage(),
          ApprovedPOPage(),
          GRNPage(),
          APInvoicePage(),
          OutgoingPaymentPage(),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _currentIndex,
        builder: (_, currentIndex, __) {
          return ValueListenableBuilder<bool>(
            valueListenable: _isOpeningCreatePO,
            builder: (_, isOpening, __) {
              return CommonBottomNav(
                currentIndex: currentIndex,
                onTabChanged: _onTabChanged,
                onCreatePO: isOpening ? () {} : _openCreatePODialog,
              );
            },
          );
        },
      ),
    );
  }
}
