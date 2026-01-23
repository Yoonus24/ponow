// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/home_shell.dart';

// ===================== PROVIDERS =====================
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/payment_dialog_provider.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:purchaseorders2/providers/connectivity_provider.dart';

// ===================== SCREENS =====================
import 'package:purchaseorders2/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔐 Replace with real auth logic later
    final bool isAuthenticated = false;

    return MultiProvider(
      providers: [
        // 🌐 INTERNET CONNECTIVITY (TOP MOST)
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        ChangeNotifierProvider(create: (_) => POProvider()),
        ChangeNotifierProvider(create: (_) => GRNProvider()),
        ChangeNotifierProvider(create: (_) => APInvoiceProvider()),
        ChangeNotifierProvider(create: (_) => OutgoingPaymentProvider()),

        ChangeNotifierProvider(
          create: (_) => PurchaseOrderNotifier(POProvider()),
        ),

        ChangeNotifierProvider(
          create: (_) => PaymentDialogProvider(
            totalPayableAmount: 0,
            isBulkPayment: false,
          ),
        ),

        ChangeNotifierProvider(create: (_) => TemplateProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        builder: (context, child) {
          final bottomInset = MediaQuery.of(context).padding.bottom;

          return Consumer<ConnectivityProvider>(
            builder: (context, net, _) {
              final bool showOffline = !net.isConnected;
              final bool showOnline = net.showBackOnline;

              return Stack(
                children: [
                  child!,

                  // 🔻 CONNECTIVITY INDICATOR
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: 16,
                    right: 16,

                    // 👇 MORE HEIGHT ABOVE BOTTOM BAR
                    bottom: (showOffline || showOnline)
                        ? kBottomNavigationBarHeight +
                              bottomInset +
                              32.0 // 👈 EXTRA LIFT
                        : -100.0,

                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(30),
                      color: showOffline
                          ? Colors.grey.shade900
                          : Colors.green.shade600,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              showOffline ? Icons.wifi_off : Icons.wifi,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              showOffline ? 'You are offline' : 'Back online',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },

        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.blueAccent,
          ),

          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),

        // 🔑 ENTRY POINT
        initialRoute: isAuthenticated ? '/home' : '/login',

        routes: {
          '/login': (_) => const LoginPage(),
          '/home': (_) => const HomeShell(),
        },
      ),
    );
  }
}
