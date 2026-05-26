// import 'package:flutter_test/flutter_test.dart';
// import 'package:purchaseorders2/models/po/po_item.dart';
// import 'package:purchaseorders2/providers/po_provider.dart';

// void main() {
//   late POProvider provider;

//   setUp(() {
//     provider = POProvider();
//   });

//   group('POProvider Logic Tests', () {
//     test('setFilterStatus updates current filter', () async {
//       await provider.setFilterStatus('Pending');

//       expect(
//         provider.currentFilterStatus,
//         'Pending',
//       );
//     });

//     test('setSearchQuery updates search query', () {
//       provider.setSearchQuery('APPLE');

//       expect(
//         provider.searchQuery,
//         'APPLE',
//       );
//     });

//     test('setVendorFilter updates vendor filter', () {
//       provider.setVendorFilter('ABC Traders');

//       expect(
//         provider.selectedVendorFilter,
//         'ABC Traders',
//       );
//     });

//     test('clearFilters resets all filters', () {
//       provider.setSearchQuery('TEST');
//       provider.setVendorFilter('Vendor');

//       provider.clearFilters();

//       expect(provider.searchQuery, '');

//       expect(provider.selectedVendorFilter, null);

//       expect(provider.currentFilterStatus, 'All');
//     });

//     test('getFilterCounts returns correct counts', () {
//       final counts = provider.getFilterCounts();

//       expect(counts.containsKey('All'), true);

//       expect(counts.containsKey('Pending'), true);

//       expect(counts.containsKey('Approved'), true);
//     });

//     test('addItem adds item correctly', () {
//       final initialLength = provider.items.length;

//       provider.addItem(
//         Item(
//           expiryDate: '2026-12-31',
//           itemName: 'APPLE',
//         ),
//       );

//       expect(
//         provider.items.length,
//         initialLength + 1,
//       );
//     });

//     test('setIncludeInactive updates value', () {
//       provider.setIncludeInactive(true);

//       expect(
//         provider.includeInactive,
//         true,
//       );
//     });
//   });

//   tearDown(() {
//     provider.dispose();
//   });
// }