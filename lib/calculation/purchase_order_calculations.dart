// // ignore_for_file: avoid_print

// import '../models/po_item.dart';
// import '../notifier/purchasenotifier.dart';
// import '../models/discount_model.dart';

// class PurchaseOrderCalculations {
//   // ✅ EXISTING CALCULATION METHODS - COPIED AS IS

//   static double calculateItemTotal(
//     dynamic item,
//     DiscountMode itemWiseDiscountMode,
//   ) {
//     double quantity = getItemProperty(item, 'quantity') ?? 0.0;
//     double newPrice = getItemProperty(item, 'newPrice') ?? 0.0;
//     double befTaxDiscount = getItemProperty(item, 'befTaxDiscount') ?? 0.0;
//     double afTaxDiscount = getItemProperty(item, 'afTaxDiscount') ?? 0.0;
//     double taxPercentage = getItemProperty(item, 'taxPercentage') ?? 0.0;

//     bool isAmountMode = itemWiseDiscountMode == DiscountMode.fixedAmount;

//     double baseAmount = quantity * newPrice;

//     double befTaxDiscountAmount = 0.0;
//     double afterBefTaxDiscount = baseAmount;

//     if (isAmountMode) {
//       befTaxDiscountAmount = befTaxDiscount;
//       afterBefTaxDiscount = baseAmount - befTaxDiscountAmount;
//     } else {
//       befTaxDiscountAmount = baseAmount * (befTaxDiscount / 100);
//       afterBefTaxDiscount = baseAmount - befTaxDiscountAmount;
//     }

//     double taxAmount = afterBefTaxDiscount * (taxPercentage / 100);
//     double afterTaxAmount = afterBefTaxDiscount + taxAmount;

//     double afTaxDiscountAmount = 0.0;
//     double finalAmount = afterTaxAmount;

//     if (isAmountMode) {
//       afTaxDiscountAmount = afTaxDiscount;
//       finalAmount = afterTaxAmount - afTaxDiscountAmount;
//     } else {
//       afTaxDiscountAmount = afterTaxAmount * (afTaxDiscount / 100);
//       finalAmount = afterTaxAmount - afTaxDiscountAmount;
//     }

//     // ✅ FIX: Only set properties that exist, use safe property setting
//     _safeSetItemProperty(item, 'befTaxDiscountAmount', befTaxDiscountAmount);
//     _safeSetItemProperty(item, 'afTaxDiscountAmount', afTaxDiscountAmount);
//     _safeSetItemProperty(item, 'taxAmount', taxAmount);
//     _safeSetItemProperty(item, 'finalPrice', finalAmount);

//     String itemName = getItemProperty(item, 'itemName').toString() ?? "";

//     print('📊 Table Calculation - $itemName:');
//     print('   Base: $baseAmount, Final: $finalAmount');
//     print('   AfTax Discount: $afTaxDiscountAmount ($afTaxDiscount%)');

//     return finalAmount;
//   }

//   static double calculateItemTotalForAddition({
//     required double quantity,
//     required double price,
//     required double befTaxDiscount,
//     required double afTaxDiscount,
//     required double taxPercentage,
//     required DiscountMode itemWiseDiscountMode,
//   }) {
//     bool isAmountMode = itemWiseDiscountMode == DiscountMode.fixedAmount;

//     double baseAmount = quantity * price;

//     double befTaxDiscountAmount = 0.0;
//     double afterBefTaxDiscount = baseAmount;

//     if (isAmountMode) {
//       befTaxDiscountAmount = befTaxDiscount;
//       afterBefTaxDiscount = baseAmount - befTaxDiscountAmount;
//     } else {
//       befTaxDiscountAmount = baseAmount * (befTaxDiscount / 100);
//       afterBefTaxDiscount = baseAmount - befTaxDiscountAmount;
//     }

//     double taxAmount = afterBefTaxDiscount * (taxPercentage / 100);
//     double afterTaxAmount = afterBefTaxDiscount + taxAmount;

//     double afTaxDiscountAmount = 0.0;
//     double finalAmount = afterTaxAmount;

//     if (isAmountMode) {
//       afTaxDiscountAmount = afTaxDiscount;
//       finalAmount = afterTaxAmount - afTaxDiscountAmount;
//     } else {
//       afTaxDiscountAmount = afterTaxAmount * (afTaxDiscount / 100);
//       finalAmount = afterTaxAmount - afTaxDiscountAmount;
//     }

//     return finalAmount;
//   }

//   static void calculatePendingValues(dynamic item) {
//     try {
//       print(
//         '🔍 CALCULATING PENDING VALUES FOR: ${getItemProperty(item, 'itemName')}',
//       );

//       double count = getItemProperty(item, 'count') ?? 1.0;
//       double eachQuantity = getItemProperty(item, 'eachQuantity') ?? 0.0;
//       double totalQuantity = getItemProperty(item, 'quantity') ?? 0.0;
//       double newPrice = getItemProperty(item, 'newPrice') ?? 0.0;
//       double befTaxDiscount = getItemProperty(item, 'befTaxDiscount') ?? 0.0;
//       double afTaxDiscount = getItemProperty(item, 'afTaxDiscount') ?? 0.0;
//       double taxPercentage = getItemProperty(item, 'taxPercentage') ?? 0.0;

//       print(
//         '   Input values - count: $count, eachQty: $eachQuantity, totalQty: $totalQuantity',
//       );
//       print(
//         '   Input values - price: $newPrice, befTax: $befTaxDiscount, afTax: $afTaxDiscount, tax%: $taxPercentage',
//       );

//       // Calculate base amount
//       double baseAmount = totalQuantity * newPrice;

//       // Calculate discount amounts
//       double befTaxDiscountAmount = baseAmount * (befTaxDiscount / 100);
//       double afterBefTaxDiscount = baseAmount - befTaxDiscountAmount;

//       // Calculate tax
//       double taxAmount = afterBefTaxDiscount * (taxPercentage / 100);
//       double afterTaxAmount = afterBefTaxDiscount + taxAmount;

//       // Calculate after tax discount
//       double afTaxDiscountAmount = afterTaxAmount * (afTaxDiscount / 100);
//       double finalAmount = afterTaxAmount - afTaxDiscountAmount;

//       // Calculate total discount amount
//       double totalDiscountAmount = befTaxDiscountAmount + afTaxDiscountAmount;

//       print('   Calculated values:');
//       print('   - baseAmount: $baseAmount');
//       print('   - befTaxDiscountAmount: $befTaxDiscountAmount');
//       print('   - afTaxDiscountAmount: $afTaxDiscountAmount');
//       print('   - taxAmount: $taxAmount');
//       print('   - finalAmount: $finalAmount');
//       print('   - totalDiscountAmount: $totalDiscountAmount');

//       // Set pending values - CRITICAL: Set ALL pending properties
//       _setItemProperty(item, 'pendingCount', count);
//       _setItemProperty(item, 'pendingQuantity', eachQuantity);
//       _setItemProperty(item, 'pendingTotalQuantity', totalQuantity);
//       _setItemProperty(
//         item,
//         'pendingBefTaxDiscountAmount',
//         befTaxDiscountAmount,
//       );
//       _setItemProperty(item, 'pendingAfTaxDiscountAmount', afTaxDiscountAmount);
//       _setItemProperty(item, 'pendingTaxAmount', taxAmount);
//       _setItemProperty(item, 'pendingFinalPrice', finalAmount);
//       _setItemProperty(item, 'pendingTotalPrice', baseAmount);
//       _setItemProperty(item, 'pendingDiscountAmount', totalDiscountAmount);

//       // Also set the regular properties for consistency
//       _setItemProperty(item, 'befTaxDiscountAmount', befTaxDiscountAmount);
//       _setItemProperty(item, 'afTaxDiscountAmount', afTaxDiscountAmount);
//       _setItemProperty(item, 'taxAmount', taxAmount);
//       _setItemProperty(item, 'finalPrice', finalAmount);
//       _setItemProperty(item, 'totalPrice', baseAmount);

//       // Debug after setting
//       print('✅ SET PENDING VALUES:');
//       print('   pendingCount: ${getItemProperty(item, 'pendingCount')}');
//       print('   pendingQuantity: ${getItemProperty(item, 'pendingQuantity')}');
//       print(
//         '   pendingTotalQuantity: ${getItemProperty(item, 'pendingTotalQuantity')}',
//       );
//       print(
//         '   pendingFinalPrice: ${getItemProperty(item, 'pendingFinalPrice')}',
//       );
//       print(
//         '   pendingDiscountAmount: ${getItemProperty(item, 'pendingDiscountAmount')}',
//       );
//     } catch (e) {
//       print('❌ Error calculating pending values: $e');
//     }
//   }

//   static void recalculateAllTotals(PurchaseOrderNotifier notifier) {
//     // REMOVED: if (notifier.isDisposed) return; - notifier doesn't have this property

//     double totalPendingOrderAmount = 0.0;
//     double totalPendingDiscountAmount = 0.0;
//     double totalPendingTaxAmount = 0.0;

//     print('💰 RECALCULATING ALL TOTALS:');

//     for (int i = 0; i < notifier.poItems.length; i++) {
//       final item = notifier.poItems[i];

//       // Ensure pending values are calculated for each item
//       calculatePendingValues(item);

//       double pendingFinalPrice =
//           getItemProperty(item, 'pendingFinalPrice') ?? 0.0;
//       double pendingDiscountAmount =
//           getItemProperty(item, 'pendingDiscountAmount') ?? 0.0;
//       double pendingTaxAmount =
//           getItemProperty(item, 'pendingTaxAmount') ?? 0.0;

//       totalPendingOrderAmount += pendingFinalPrice;
//       totalPendingDiscountAmount += pendingDiscountAmount;
//       totalPendingTaxAmount += pendingTaxAmount;

//       print('   ${item.itemName}:');
//       print('     - Quantity: ${getItemProperty(item, 'quantity')}');
//       print('     - Price: ${getItemProperty(item, 'newPrice')}');
//       print('     - pendingFinalPrice: $pendingFinalPrice');
//       print('     - pendingDiscountAmount: $pendingDiscountAmount');
//       print('     - pendingTaxAmount: $pendingTaxAmount');
//     }

//     // Update notifier totals
//     notifier.calculatedFinalAmount = totalPendingOrderAmount;
//     notifier.totalOrderAmount = totalPendingOrderAmount;

//     print('💰 FINAL TOTALS:');
//     print('   Total pendingOrderAmount: $totalPendingOrderAmount');
//     print('   Total pendingDiscountAmount: $totalPendingDiscountAmount');
//     print('   Total pendingTaxAmount: $totalPendingTaxAmount');
//     print('   UI Total Order Amount: ${notifier.calculatedFinalAmount}');
//     print('   Number of items: ${notifier.poItems.length}');
//   }

//   static void verifyTotalsBeforeSubmission(PurchaseOrderNotifier notifier) {
//     print('💰 VERIFYING TOTALS BEFORE SUBMISSION:');

//     double totalPendingOrderAmount = 0.0;
//     double totalPendingDiscountAmount = 0.0;
//     double totalPendingTaxAmount = 0.0;

//     for (int i = 0; i < notifier.poItems.length; i++) {
//       final item = notifier.poItems[i];
//       double pendingFinalPrice =
//           getItemProperty(item, 'pendingFinalPrice') ?? 0.0;
//       double pendingDiscountAmount =
//           getItemProperty(item, 'pendingDiscountAmount') ?? 0.0;
//       double pendingTaxAmount =
//           getItemProperty(item, 'pendingTaxAmount') ?? 0.0;

//       totalPendingOrderAmount += pendingFinalPrice;
//       totalPendingDiscountAmount += pendingDiscountAmount;
//       totalPendingTaxAmount += pendingTaxAmount;

//       print('   ${item.itemName}:');
//       print('     pendingFinalPrice: $pendingFinalPrice');
//       print('     pendingDiscountAmount: $pendingDiscountAmount');
//       print('     pendingTaxAmount: $pendingTaxAmount');
//     }

//     print('💰 TOTALS:');
//     print('   Total pendingOrderAmount: $totalPendingOrderAmount');
//     print('   Total pendingDiscountAmount: $totalPendingDiscountAmount');
//     print('   Total pendingTaxAmount: $totalPendingTaxAmount');
//     print('   UI Total Order Amount: ${notifier.calculatedFinalAmount}');
//   }

//   // ✅ HELPER METHODS

//   static double getItemProperty(dynamic item, String propertyName) {
//     try {
//       if (item == null) return 0.0;

//       if (item is Map<String, dynamic>) {
//         return (item[propertyName] as num?)?.toDouble() ?? 0.0;
//       } else {
//         var value = _getProperty(item, propertyName);
//         return (value as num?)?.toDouble() ?? 0.0;
//       }
//     } catch (e) {
//       return 0.0;
//     }
//   }

//   static dynamic _getProperty(dynamic object, String propertyName) {
//     try {
//       if (object == null) return null;
//       return _getPropertyValue(object, propertyName);
//     } catch (e) {
//       return null;
//     }
//   }

//   static dynamic _getPropertyValue(dynamic object, String propertyName) {
//     try {
//       switch (propertyName) {
//         case 'afTaxDiscount':
//           double value = object.afTaxDiscount ?? 0.0;
//           String afTaxDiscountType = object.afTaxDiscountType ?? 'percentage';

//           // 🔥 CRITICAL FIX: Check if value > 100 (it's probably the AMOUNT, not PERCENTAGE)
//           if (value > 100) {
//             print(
//               '⚠️ WARNING: afTaxDiscount > 100% in PurchaseOrderCalculations!',
//             );
//             print('   Item: ${object.itemName}');
//             print('   Raw value: $value');
//             print('   This should be ~2.92, not 500!');

//             // Calculate correct percentage from amount
//             double base = (object.quantity ?? 1.0) * (object.newPrice ?? 1.0);
//             double afTaxDiscountAmount = object.afTaxDiscountAmount ?? 0.0;

//             if (base > 0 && afTaxDiscountAmount > 0) {
//               double correctPercentage = (afTaxDiscountAmount / base) * 100;
//               print('   Correcting $value to $correctPercentage%');
//               return correctPercentage;
//             }
//           }
//           return value;

//         // ... other cases remain the same
//       }
//     } catch (e) {
//       print('❌ Error getting property $propertyName: $e');
//       return null;
//     }
//   }

//   static void debugItemValues(Item item) {
//     print('🔍 DEBUG Item Values for: ${item.itemName}');
//     print('   afTaxDiscount (stored): ${item.afTaxDiscount}');
//     print('   afTaxDiscountType: ${item.afTaxDiscountType}');
//     print('   afTaxDiscountAmount: ${item.afTaxDiscountAmount}');
//     print('   Quantity: ${item.quantity}');
//     print('   New Price: ${item.newPrice}');
//     print('   Base: ${(item.quantity ?? 0) * (item.newPrice ?? 0)}');

//     // Check if afTaxDiscount is > 100
//     if ((item.afTaxDiscount ?? 0) > 100) {
//       print('❌ ERROR: afTaxDiscount is ${item.afTaxDiscount} > 100!');
//       print('   This should be the PERCENTAGE (~2.92), not the AMOUNT (500)');
//     }
//   }

//   static void _setItemProperty(
//     dynamic item,
//     String propertyName,
//     dynamic value,
//   ) {
//     try {
//       if (item == null) return;
//       if (item is Map<String, dynamic>) {
//         item[propertyName] = value;
//       } else {
//         setPropertyValue(item, propertyName, value);
//       }
//     } catch (e) {
//       // Handle error silently
//     }
//   }

//   static void setPropertyValue(
//     dynamic object,
//     String propertyName,
//     dynamic value,
//   ) {
//     try {
//       switch (propertyName) {
//         case 'count':
//           object.count = value;
//           break;
//         case 'eachQuantity':
//           object.eachQuantity = value;
//           break;
//         case 'quantity':
//           object.quantity = value;
//           break;
//         case 'newPrice':
//           object.newPrice = value;
//           break;
//         case 'taxType':
//           object.taxType = value;
//           break;
//         case 'totalPrice':
//           object.totalPrice = value;
//           break;
//         case 'afTaxDiscount':
//           object.afTaxDiscount = value;
//           break;
//         case 'pendingAfTaxDiscountAmount':
//           object.pendingAfTaxDiscountAmount = value;
//           break;
//         case 'afTaxDiscountAmount':
//           object.afTaxDiscountAmount = value;
//           break;
//         case 'pendingDiscountAmount':
//           object.pendingDiscountAmount = value;
//           break;
//         case 'itemOverallDiscountAmount':
//           object.itemOverallDiscountAmount = value;
//           break;
//         case 'pendingFinalPrice':
//           object.pendingFinalPrice = value;
//           break;
//         case 'pendingOrderAmount':
//           object.pendingOrderAmount = value;
//           break;
//         case 'totalPrice':
//           object.totalPrice = value;
//           break;
//         case 'befTaxDiscount':
//           object.befTaxDiscount = value;
//           break;
//         case 'pendingCount':
//           object.pendingCount = value;
//           break;
//         case 'pendingQuantity':
//           object.pendingQuantity = value;
//           break;
//         case 'pendingTotalQuantity':
//           object.pendingTotalQuantity = value;
//           break;
//         case 'pendingBefTaxDiscountAmount':
//           object.pendingBefTaxDiscountAmount = value;
//           break;
//         case 'pendingAfTaxDiscountAmount':
//           object.pendingAfTaxDiscountAmount = value;
//           break;
//         case 'pendingTaxAmount':
//           object.pendingTaxAmount = value;
//           break;
//         case 'pendingFinalPrice':
//           object.pendingFinalPrice = value;
//           break;
//         case 'pendingTotalPrice':
//           object.pendingTotalPrice = value;
//           break;
//         case 'pendingDiscountAmount':
//           object.pendingDiscountAmount = value;
//           break;
//         case 'befTaxDiscountType':
//           object.befTaxDiscountType = value;
//           break;
//         case 'afTaxDiscountType':
//           object.afTaxDiscountType = value;
//           break;
//         default:
//           print('⚠️ Unknown property: $propertyName');
//           break;
//       }
//     } catch (e) {
//       print('❌ Error setting property $propertyName: $e');
//     }
//   }

//   static void _safeSetItemProperty(
//     dynamic item,
//     String propertyName,
//     dynamic value,
//   ) {
//     try {
//       if (item == null) return;

//       // Check if property exists before setting
//       switch (propertyName) {
//         case 'befTaxDiscountAmount':
//           if (item is Map<String, dynamic>) {
//             item[propertyName] = value;
//           } else if (item is Item) {
//             item.befTaxDiscountAmount = value;
//           }
//           break;
//         case 'afTaxDiscountAmount':
//           if (item is Map<String, dynamic>) {
//             item[propertyName] = value;
//           } else if (item is Item) {
//             item.afTaxDiscountAmount = value;
//           }
//           break;
//         case 'taxAmount':
//           if (item is Map<String, dynamic>) {
//             item[propertyName] = value;
//           } else if (item is Item) {
//             item.taxAmount = value;
//           }
//           break;
//         case 'finalPrice':
//           if (item is Map<String, dynamic>) {
//             item[propertyName] = value;
//           } else if (item is Item) {
//             item.finalPrice = value;
//           }
//           break;
//         default:
//           print('⚠️ Unknown property in _safeSetItemProperty: $propertyName');
//           break;
//       }
//     } catch (e) {
//       print('❌ Error setting property $propertyName: $e');
//     }
//   }
// }
