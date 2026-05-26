import 'package:flutter_test/flutter_test.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/models/po/po_item.dart';

void main() {
  late POProvider provider;

  setUp(() {
    provider = POProvider();
  });

  group('POProvider Logic Tests', () {
    test('setIncludeInactive updates value', () {
      provider.setIncludeInactive(true);

      expect(
        provider.includeInactive,
        true,
      );
    });

    test('getFilterCounts returns map', () {
      final counts = provider.getFilterCounts();

      expect(
        counts.containsKey('All'),
        true,
      );

      expect(
        counts.containsKey('Pending'),
        true,
      );

      expect(
        counts.containsKey('Approved'),
        true,
      );
    });

    test('addItem adds item correctly', () {
      final initialLength = provider.items.length;

      provider.addItem(
        Item(
          expiryDate: '2026-12-31',
          itemName: 'APPLE',
        ),
      );

      expect(
        provider.items.length,
        initialLength + 1,
      );
    });
  });

  tearDown(() {
    provider.dispose();
  });
}