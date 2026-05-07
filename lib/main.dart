// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/core/storage/secure_storage_service.dart';
import 'package:purchaseorders2/providers/import_provider.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/navigation_service.dart';
import 'package:purchaseorders2/AppInitializer.dart';
import 'package:purchaseorders2/home_shell.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/payment_dialog_provider.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:purchaseorders2/providers/connectivity_provider.dart';
import 'package:purchaseorders2/screens/login_screen.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = true;

  /// Server time init (optional)
  try {
    await ServerTimeService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize ServerTimeService: $e');
  }
  await dotenv.load(fileName: ".env");

  /// Init Dio
  await DioClient.init();

  ///Get stored token
  final token = await SecureStorageService.getToken();

  ///SIMPLE AUTH CHECK (NO validateToken)
  bool isAuthenticated = token != null;

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        ChangeNotifierProvider(create: (_) => ImportProvider()),
        ChangeNotifierProvider(
          create: (_) => PermissionProvider()..loadPermissions(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        debugShowCheckedModeBanner: false,

        ///Connectivity Banner Wrapper
        builder: (context, child) {
          final bottomInset = MediaQuery.of(context).padding.bottom;

          return AppInitializer(
            child: Consumer<ConnectivityProvider>(
              builder: (context, net, _) {
                final bool showOffline = !net.isConnected;
                final bool showOnline = net.showBackOnline;

                return Stack(
                  children: [
                    child!,

                    /// 🔴 Offline / 🟢 Online Banner
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 16,
                      right: 16,
                      bottom: (showOffline || showOnline)
                          ? kBottomNavigationBarHeight + bottomInset + 32.0
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
            ),
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

        ///ROUTES
        initialRoute: isAuthenticated ? '/home' : '/login',

        routes: {
          '/login': (_) => const LoginPage(),
          '/home': (_) => const HomeShell(),
        },
      ),
    );
  }
}
