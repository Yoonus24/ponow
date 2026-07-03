import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/providers/template_provider.dart';

import 'package:purchaseorders2/screens/po_page.dart';
import 'package:purchaseorders2/screens/approved_po_page.dart';
import 'package:purchaseorders2/screens/grn_page.dart';
import 'package:purchaseorders2/screens/ap_invoice_page.dart';
import 'package:purchaseorders2/screens/outgoing_payment_page.dart';
import 'package:purchaseorders2/services/session_service.dart';

import 'package:purchaseorders2/widgets/common_bottom_nav.dart';
import 'package:purchaseorders2/widgets/common_app_bar.dart';
import 'package:purchaseorders2/screens/create_po_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isOpeningCreatePO = ValueNotifier(false);
  bool _isLoginSnackShown = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      SessionService.start();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<PurchaseOrderNotifier>();

      // notifier.fetchAllVendors1();
      // notifier.fetchVendors1();
      notifier.fetchItems('');
      notifier.fetchBillingAddress1();
      notifier.fetchShippingAddress1();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PermissionProvider>().loadPermissions();
    }
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

      // if (notifier.vendorAllList.isEmpty) {
      //   notifier.fetchAllVendors1();
      // }

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
      debugPrint("Error opening PO dialog: $e");
    } finally {
      if (mounted) {
        _isOpeningCreatePO.value = false;
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex.value != 0) {
      _onTabChanged(0);
      return false;
    }

    final now = DateTime.now();

    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
        ),
      );

      return false;
    }

    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    SessionService.stop();

    _pageController.dispose();
    _currentIndex.dispose();
    _isOpeningCreatePO.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoginSnackShown) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args?["loginSuccess"] == true) {
      _isLoginSnackShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final notifier = context.read<PurchaseOrderNotifier>();
        final poProvider = context.read<POProvider>();

        await poProvider.refreshPOList();

        await notifier.fetchItems('');
        await notifier.fetchBillingAddress1();
        await notifier.fetchShippingAddress1();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          // physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            _currentIndex.value = index;

            final provider = context.read<POProvider>();

            if (index == 0) {
              provider.refreshPOList();
            }
            if (index == 1 && provider.pos.isEmpty) {
              provider.fetchApprovedPOsOnly();
            } else if (index == 2) {
              provider.fetchGRNConvertedPOsOnly();
            }
          },
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
      ),
    );
  }
}
