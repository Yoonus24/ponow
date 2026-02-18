// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/po_provider.dart';

// class POSummaryDialog extends StatelessWidget {
//   const POSummaryDialog({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Consumer<POProvider>(
//           builder: (context, poProvider, child) {
//             Map<String, int> consolidatedItems = {}; // Keep as int

//             // Check if pos is not null
//             for (var po in poProvider.pos) {
//               // Check if items is not null
//               for (var item in po.items) {
//                 int quantity =
//                     item.quantity!.round(); // Round to nearest integer
//                 if (consolidatedItems.containsKey(item.itemName)) {
//                   consolidatedItems[item.itemName ?? 'no item'] =
//                       consolidatedItems[item.itemName]! + quantity;
//                 } else {
//                   consolidatedItems[item.itemName ?? 'no item'] = quantity;
//                 }
//               }
//                         }

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Consolidated PO Items',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 16.0),
//                 ...consolidatedItems.entries.map((entry) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4.0),
//                     child: Text('${entry.key} x ${entry.value}'),
//                   );
//                 }),
//                 SizedBox(height: 16.0),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     child: Text('Close'),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
