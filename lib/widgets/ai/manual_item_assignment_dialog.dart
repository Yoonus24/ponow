// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
// import 'package:purchaseorders2/services/ai/ai_invoice_service.dart';

// class ManualItemAssignmentDialog extends StatefulWidget {
//   final AIInvoiceResponse aiResponse;

//   const ManualItemAssignmentDialog({super.key, required this.aiResponse});

//   @override
//   State<ManualItemAssignmentDialog> createState() =>
//       _ManualItemAssignmentDialogState();
// }

// class _ManualItemAssignmentDialogState
//     extends State<ManualItemAssignmentDialog> {
//   final Map<int, String?> selectedItems = {};

//   final AIInvoiceService _service = AIInvoiceService();
//   bool _loading = false;

//   @override
//   Widget build(BuildContext context) {
//     final extraItems = widget.aiResponse.analysisData["extraItems"] ?? [];
//     final missingItems = widget.aiResponse.analysisData["missingItems"] ?? [];

//     return Dialog(
//       insetPadding: EdgeInsets.zero,
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.white,
//         child: Column(
//           children: [
//             // =================================================
//             // APP BAR
//             // =================================================
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.link_rounded,
//                     color: Colors.orange.shade600,
//                     size: 22,
//                   ),
//                   const SizedBox(width: 10),
//                   const Expanded(
//                     child: Text(
//                       "Resolve Item Mapping",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close, size: 20),
//                     color: Colors.grey.shade600,
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                 ],
//               ),
//             ),

//             // =================================================
//             // CONTENT
//             // =================================================
//             Expanded(
//               child: extraItems.isEmpty
//                   ? _buildEmptyState()
//                   : _buildContent(extraItems, missingItems),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // EMPTY STATE
//   // =========================================================
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.check_circle_outline_rounded,
//             size: 64,
//             color: Colors.green.shade300,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "No Extra Items Found",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "All items have been matched successfully",
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade700,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // MAIN CONTENT
//   // =========================================================
//   Widget _buildContent(List extraItems, List missingItems) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ============================================
//           // HEADER INFO
//           // ============================================
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.orange.shade200),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.info_outline_rounded,
//                   color: Colors.orange.shade700,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Extra Items Detected",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.orange.shade800,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         "These items were found in the invoice but not in the PO. "
//                         "Please assign them to existing PO items.",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.orange.shade700,
//                           height: 1.4,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade200,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     "${extraItems.length} items",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.orange.shade800,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 20),

//           // ============================================
//           // ITEMS LIST
//           // ============================================
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: extraItems.length,
//             itemBuilder: (_, index) {
//               final extra = extraItems[index];
//               return _buildItemCard(index, extra, missingItems);
//             },
//           ),

//           const SizedBox(height: 20),

//           // ============================================
//           // STATS
//           // ============================================
//           _buildStats(extraItems),

//           const SizedBox(height: 20),

//           // ============================================
//           // ACTIONS
//           // ============================================
//           _buildActionButtons(),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // ITEM CARD
//   // =========================================================
//   Widget _buildItemCard(int index, dynamic extra, List missingItems) {
//     final hasSelected = selectedItems[index] != null;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 14),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: hasSelected ? Colors.green.shade300 : Colors.grey.shade200,
//           width: 1.5,
//         ),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           color: hasSelected ? Colors.green.shade50 : Colors.white,
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 children: [
//                   Container(
//                     width: 28,
//                     height: 28,
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade100,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Center(
//                       child: Text(
//                         "${index + 1}",
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.orange.shade800,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // CHANGED: Use itemName from extra object
//                         Text(
//                           extra["itemName"]?.toString() ?? "Unknown Item",
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (hasSelected)
//                           Container(
//                             margin: const EdgeInsets.only(top: 4),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.green.shade100,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               "✓ Assigned",
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.green.shade700,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Icon(
//                     Icons.swap_horiz_rounded,
//                     size: 20,
//                     color: hasSelected
//                         ? Colors.green.shade600
//                         : Colors.grey.shade400,
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 14),

//               // Dropdown - Store poIndex as value
//               DropdownButtonFormField<String>(
//                 value: selectedItems[index],
//                 isExpanded: true,
//                 decoration: InputDecoration(
//                   labelText: "Assign to PO Item",
//                   labelStyle: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey.shade600,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(
//                       color: Colors.orange.shade600,
//                       width: 2,
//                     ),
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 12,
//                   ),
//                 ),
//                 style: const TextStyle(fontSize: 13, color: Colors.black87),
//                 items: [
//                   const DropdownMenuItem<String>(
//                     value: null,
//                     child: Text(
//                       "Select a PO item...",
//                       style: TextStyle(color: Colors.grey, fontSize: 13),
//                     ),
//                   ),
//                   // CHANGED: Use poIndex and itemName from missing items
//                   ...missingItems.map<DropdownMenuItem<String>>((e) {
//                     final itemId = e["poIndex"]?.toString() ?? '';
//                     final itemName = e["itemName"]?.toString() ?? e.toString();
//                     return DropdownMenuItem(
//                       value: itemId,
//                       child: Text(
//                         itemName,
//                         style: const TextStyle(fontSize: 13),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     );
//                   }).toList(),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     selectedItems[index] = value;
//                   });
//                 },
//                 icon: Icon(
//                   Icons.keyboard_arrow_down_rounded,
//                   color: Colors.grey.shade600,
//                 ),
//                 dropdownColor: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // STATS
//   // =========================================================
//   Widget _buildStats(List extraItems) {
//     final assignedCount = selectedItems.values.where((v) => v != null).length;
//     final totalCount = extraItems.length;
//     final isComplete = assignedCount == totalCount;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Assignment Progress",
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "$assignedCount / $totalCount",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: isComplete
//                         ? Colors.green.shade700
//                         : Colors.orange.shade700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             width: 80,
//             height: 80,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 SizedBox(
//                   width: 70,
//                   height: 70,
//                   child: CircularProgressIndicator(
//                     value: totalCount > 0 ? assignedCount / totalCount : 0,
//                     strokeWidth: 6,
//                     backgroundColor: Colors.grey.shade200,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       isComplete
//                           ? Colors.green.shade600
//                           : Colors.orange.shade600,
//                     ),
//                   ),
//                 ),
//                 Text(
//                   "${totalCount > 0 ? ((assignedCount / totalCount) * 100).round() : 0}%",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey.shade700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // ACTION BUTTONS
//   // =========================================================
//   Widget _buildActionButtons() {
//     final assignedCount = selectedItems.values.where((v) => v != null).length;
//     final totalCount =
//         (widget.aiResponse.analysisData["extraItems"] ?? []).length;
//     final isComplete = assignedCount == totalCount;

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton(
//           onPressed: () => Navigator.pop(context),
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//             side: BorderSide(color: Colors.grey.shade400),
//             foregroundColor: Colors.grey.shade700,
//             textStyle: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text("Cancel"),
//         ),
//         const SizedBox(width: 12),
//         ElevatedButton(
//           onPressed: isComplete
//               ? () async {
//                   try {
//                     setState(() {
//                       _loading = true;
//                     });

//                     // Build assignments list
//                     final assignments = <Map<String, dynamic>>[];
//                     final extraItems =
//                         widget.aiResponse.analysisData["extraItems"] ?? [];

//                     for (var entry in selectedItems.entries) {
//                       final extraIndex = entry.key;
//                       final poItemId = entry.value;

//                       if (poItemId != null && extraIndex < extraItems.length) {
//                         final extraItem = extraItems[extraIndex];

//                         // CHANGED: Use invoiceIndex from extra item
//                         assignments.add({
//                           "invoiceItemId": extraItem["invoiceIndex"],
//                           "poItemId": int.parse(poItemId),
//                         });
//                       }
//                     }

//                     // Build payload
//                     final payload = {
//                       'poId': widget.aiResponse.poId,
//                       'analysisData': widget.aiResponse.analysisData,
//                       'matchedItems':
//                           widget.aiResponse.analysisData['matchedItems'] ?? [],
//                       'extraItems':
//                           widget.aiResponse.analysisData['extraItems'] ?? [],
//                       'missingItems':
//                           widget.aiResponse.analysisData['missingItems'] ?? [],
//                       'assignments': assignments,
//                     };
//                     debugPrint(jsonEncode(payload));

//                     // Call API
//                     // final response = await _service.resolveItems(
//                     //   request: payload,
//                     // );

//                     setState(() {
//                       _loading = false;
//                     });

//                     if (mounted) {
//                       // Navigator.pop(context, response);
//                     }
//                   } catch (e) {
//                     setState(() {
//                       _loading = false;
//                     });
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Error: ${e.toString()}'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   }
//                 }
//               : null,
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
//             backgroundColor: isComplete
//                 ? Colors.blue.shade700
//                 : Colors.grey.shade400,
//             foregroundColor: Colors.white,
//             textStyle: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             elevation: 0,
//             disabledBackgroundColor: Colors.grey.shade300,
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (_loading) ...[
//                 const SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               ] else ...[
//                 Text(isComplete ? "Assign All" : "Assign All"),
//                 if (isComplete) ...[
//                   const SizedBox(width: 6),
//                   const Icon(Icons.check_circle_rounded, size: 16),
//                 ],
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
