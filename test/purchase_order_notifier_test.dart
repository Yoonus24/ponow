import 'package:flutter_test/flutter_test.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/models/po/po_item.dart';

void main() {
  late PurchaseOrderNotifier notifier;

  setUp(() {
    notifier = PurchaseOrderNotifier(
      POProvider(),
    );
  });

  test(
    'calculateTotals should calculate subtotal correctly',
    () {
      notifier.poItems = [
        Item(
          expiryDate: '2026-12-31',

          totalPrice: 100,
          finalPrice: 90,

          taxAmount: 10,

          befTaxDiscountAmount: 5,
          afTaxDiscountAmount: 5,
        ),

        Item(
          expiryDate: '2026-12-31',

          totalPrice: 200,
          finalPrice: 180,

          taxAmount: 20,

          befTaxDiscountAmount: 10,
          afTaxDiscountAmount: 10,
        ),
      ];

      notifier.calculateTotals();

      expect(notifier.subTotal, 300);

      expect(notifier.pendingTaxAmount, 30);

      expect(notifier.calculatedFinalAmount, 270);
    },
  );

  test(
    'calculateTotals should handle empty items',
    () {
      notifier.poItems = [];

      notifier.calculateTotals();

      expect(notifier.subTotal, 0);

      expect(notifier.pendingTaxAmount, 0);

      expect(notifier.calculatedFinalAmount, 0);
    },
  );

  test(
    'calculateTotals should include freight amount',
    () {
      notifier.poItems = [
        Item(
          expiryDate: '2026-12-31',

          totalPrice: 100,
          finalPrice: 100,

          taxAmount: 10,
        ),
      ];

      notifier.totalFreightAmount = 50;

      notifier.totalFreightTaxAmount = 10;

      notifier.calculateTotals();

      expect(
        notifier.calculatedFinalAmount,
        160,
      );
    },
  );

  tearDown(() {
    notifier.dispose();
  });
}