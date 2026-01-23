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
    // 🔐 Replace this with real auth logic later
    final bool isAuthenticated = false;

    return MultiProvider(
      providers: [
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

        // 🛠 Tooltip crash fix
        builder: (context, child) {
          return TooltipTheme(
            data: const TooltipThemeData(
              waitDuration: Duration.zero,
              showDuration: Duration.zero,
              enableFeedback: false,
            ),
            child: child!,
          );
        },

        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.blueAccent,
          ),

          // 🚫 Disable default page transitions
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),

        // 🔑 SINGLE ENTRY POINT AFTER LOGIN
        initialRoute: isAuthenticated ? '/home' : '/login',

        routes: {
          '/login': (_) => const LoginPage(),
          '/home': (_) => const HomeShell(),
        },
      ),
    );
  }
}
