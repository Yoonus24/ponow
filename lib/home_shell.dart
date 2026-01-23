// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:purchaseorders2/notifier/purchasenotifier.dart';

// import 'package:purchaseorders2/providers/template_provider.dart';
// import 'package:purchaseorders2/providers/grn_provider.dart';

// import 'package:purchaseorders2/screens/po_page.dart';
// import 'package:purchaseorders2/screens/approved_po_page.dart';
// import 'package:purchaseorders2/screens/grn_page.dart';
// import 'package:purchaseorders2/screens/ap_invoice_page.dart';
// import 'package:purchaseorders2/screens/outgoing_payment_page.dart';
// import 'package:purchaseorders2/screens/create_po_page.dart';

// import 'package:purchaseorders2/widgets/common_bottom_nav.dart';
// import 'package:purchaseorders2/widgets/common_app_bar.dart';

// class HomeShell extends StatefulWidget {
//   const HomeShell({super.key});

//   @override
//   State<HomeShell> createState() => _HomeShellState();
// }

// class _HomeShellState extends State<HomeShell> {
//   final PageController _pageController = PageController();
//   int _currentIndex = 0; // Home default

//   void _onTabChanged(int index) {
//     setState(() => _currentIndex = index);

//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 280),
//       curve: Curves.easeOutCubic,
//     );
//   }

//   void _openCreatePODialog() async {
//     final notifier = context.read<PurchaseOrderNotifier>();

//     // 🔥 STEP 1: PRELOAD VENDORS BEFORE DIALOG
//     if (notifier.vendorAllList.isEmpty) {
//       await notifier.fetchAllVendors1();
//     }

//     if (!mounted) return;

//     // 🔥 STEP 2: OPEN DIALOG AFTER DATA READY
//     await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => PurchaseOrderDialog(
//         templateProvider: context.read<TemplateProvider>(),
//       ),
//     );

//     // Optional: go back to Home tab
//     CommonAppBar.selectedLabel.value = "Home";
//     _onTabChanged(0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PageView(
//         controller: _pageController,
//         physics: const NeverScrollableScrollPhysics(),
//         children: const [
//           POPage(), // index 0 → Home
//           ApprovedPOPage(), // index 1
//           GRNPage(), // index 2
//           APInvoicePage(), // index 3
//           OutgoingPaymentPage(), // index 4
//         ],
//       ),
//       bottomNavigationBar: CommonBottomNav(
//         currentIndex: _currentIndex,
//         onTabChanged: _onTabChanged,
//         onCreatePO: _openCreatePODialog, // 🔥 Create PO dialog
//       ),
//     );
//   }
// }

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
  int _currentIndex = 0;

  /// 🔐 Prevent multiple Create PO taps
  final ValueNotifier<bool> _isOpeningCreatePO = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    /// 🔥 PRELOAD heavy data ONCE (background)
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
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// ✅ SAFE + INSTANT Create PO dialog opener
  Future<void> _openCreatePODialog() async {
    // 🛑 Block multi-tap
    if (_isOpeningCreatePO.value) return;

    _isOpeningCreatePO.value = true;

    try {
      final notifier = context.read<PurchaseOrderNotifier>();

      // ❗ DO NOT await heavy API here
      if (notifier.vendorAllList.isEmpty) {
        notifier.fetchAllVendors1(); // background
      }

      if (!mounted) return;

      // 🔥 Open dialog immediately
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PurchaseOrderDialog(
          templateProvider: context.read<TemplateProvider>(),
        ),
      );

      // Reset UI after dialog close
      CommonAppBar.selectedLabel.value = "Home";
      _onTabChanged(0);
    } catch (e) {
      debugPrint("❌ Create PO dialog error: $e");
    } finally {
      if (mounted) {
        _isOpeningCreatePO.value = false;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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

      /// 🔒 Bottom nav reacts to Create PO loading state
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _isOpeningCreatePO,
        builder: (_, isOpening, __) {
          return CommonBottomNav(
            currentIndex: _currentIndex,
            onTabChanged: _onTabChanged,

            /// Disable Create PO while opening
            onCreatePO: isOpening ? () {} : _openCreatePODialog,
          );
        },
      ),
    );
  }
}
