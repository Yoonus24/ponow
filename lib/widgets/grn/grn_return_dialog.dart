// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:purchaseorders2/models/grnitem.dart';
// import '../../models/grn.dart';
// import '../../providers/grn_provider.dart';
// import 'package:provider/provider.dart';
// import '../../utils/calculator_utils.dart';

// class GRNReturn extends StatefulWidget {
//   final GRN grn;

//   const GRNReturn({super.key, required this.grn});

//   @override
//   _GRNModalState createState() => _GRNModalState();
// }

// class _GRNModalState extends State<GRNReturn> {
//   late GRN grn;
//   late ValueNotifier<List<bool>> selectedRowsNotifier;
//   late ValueNotifier<bool> isReturnAllEnabledNotifier;
//   late ValueNotifier<bool> enableReturnSelectedFieldsNotifier;
//   late ValueNotifier<bool> isSpecificQuantityReturnNotifier;
//   late Map<ItemDetail, double?> originalQuantities;
//   late Map<ItemDetail, double?> originalEachQuantities;
//   late ValueNotifier<String?> scenarioNotifier;
//   late String grnId;
//   late ValueNotifier<DateTime?> returnDateNotifier;
//   late String returnedBy;
//   late ValueNotifier<Map<int, String>> itemReasonsNotifier;
//   late ValueNotifier<List<Map<String, dynamic>>?> itemsNotifier;
//   late ValueNotifier<String?> reasonErrorNotifier;
//   late ValueNotifier<Map<int, String?>> quantityErrorsNotifier;
//   late ValueNotifier<Map<int, String?>> reasonErrorsNotifier;
//   final TextEditingController _customReasonController = TextEditingController();
//   final FocusNode _customReasonFocusNode = FocusNode();
//   late ValueNotifier<bool> showCustomReasonFieldNotifier;

//   // Scroll controllers for synchronized scrolling
//   final ScrollController _verticalScrollController = ScrollController();
//   final ScrollController _headerHorizontalScrollController = ScrollController();
//   final ScrollController _bodyHorizontalScrollController = ScrollController();
//   final ScrollController _fixedColumnScrollController = ScrollController();

//   final ScrollController _rightHeaderHorizontal = ScrollController();
//   final ScrollController _rightBodyHorizontal = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     grn = widget.grn;
//     _syncHorizontalScroll();

//     selectedRowsNotifier = ValueNotifier<List<bool>>(
//       List<bool>.filled(grn.itemDetails?.length ?? 0, false),
//     );
//     isReturnAllEnabledNotifier = ValueNotifier<bool>(false);
//     enableReturnSelectedFieldsNotifier = ValueNotifier<bool>(false);
//     isSpecificQuantityReturnNotifier = ValueNotifier<bool>(false);
//     originalQuantities = {};
//     originalEachQuantities = {};
//     for (var item in grn.itemDetails ?? []) {
//       originalQuantities[item] = item.receivedQuantity ?? 0;
//       originalEachQuantities[item] = item.eachQuantity ?? 1;
//     }
//     scenarioNotifier = ValueNotifier<String?>(null);
//     grnId = grn.grnId ?? '';
//     returnedBy = 'user123';
//     returnDateNotifier = ValueNotifier<DateTime?>(DateTime.now());
//     itemReasonsNotifier = ValueNotifier<Map<int, String>>({});
//     itemsNotifier = ValueNotifier<List<Map<String, dynamic>>?>([]);
//     reasonErrorNotifier = ValueNotifier<String?>(null);
//     quantityErrorsNotifier = ValueNotifier<Map<int, String?>>({});
//     reasonErrorsNotifier = ValueNotifier<Map<int, String?>>({});
//     showCustomReasonFieldNotifier = ValueNotifier<bool>(false);

//     // Setup scroll synchronization
//     _verticalScrollController.addListener(_syncVerticalScroll);
//     _fixedColumnScrollController.addListener(_syncVerticalScroll);
//   }

//   void _syncVerticalScroll() {
//     if (_verticalScrollController.hasClients &&
//         _fixedColumnScrollController.hasClients) {
//       if (_verticalScrollController.position.activity?.isScrolling ?? false) {
//         _fixedColumnScrollController.jumpTo(_verticalScrollController.offset);
//       }
//     }
//   }

//   void _syncHorizontalScroll() {
//     _rightHeaderHorizontal.addListener(() {
//       if (_rightBodyHorizontal.offset != _rightHeaderHorizontal.offset) {
//         _rightBodyHorizontal.jumpTo(_rightHeaderHorizontal.offset);
//       }
//     });

//     _rightBodyHorizontal.addListener(() {
//       if (_rightHeaderHorizontal.offset != _rightBodyHorizontal.offset) {
//         _rightHeaderHorizontal.jumpTo(_rightBodyHorizontal.offset);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     selectedRowsNotifier.dispose();
//     isReturnAllEnabledNotifier.dispose();
//     enableReturnSelectedFieldsNotifier.dispose();
//     isSpecificQuantityReturnNotifier.dispose();
//     scenarioNotifier.dispose();
//     returnDateNotifier.dispose();
//     itemReasonsNotifier.dispose();
//     itemsNotifier.dispose();
//     reasonErrorNotifier.dispose();
//     quantityErrorsNotifier.dispose();
//     reasonErrorsNotifier.dispose();
//     showCustomReasonFieldNotifier.dispose();
//     originalQuantities.clear();
//     originalEachQuantities.clear();
//     _verticalScrollController.dispose();
//     _headerHorizontalScrollController.dispose();
//     _bodyHorizontalScrollController.dispose();
//     _fixedColumnScrollController.dispose();
//     _customReasonController.dispose();
//     _customReasonFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'GRN No: ${grn.randomId}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     SizedBox(
//                       width: 250,
//                       child: Text(
//                         'Vendor: ${grn.vendorName ?? 'N/A'}',
//                         style: const TextStyle(fontSize: 15),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         softWrap: true,
//                       ),
//                     ),
//                     Text('Date: ${formatDate(grn.grnDate)}'),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14.0),

//             // Return Options Section
//             ValueListenableBuilder<bool>(
//               valueListenable: isReturnAllEnabledNotifier,
//               builder: (context, isReturnAllEnabled, _) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Consumer<GRNProvider>(
//                             builder: (context, grnProvider, child) {
//                               if (grnProvider.isLoading) {
//                                 return const Center(
//                                   child: CircularProgressIndicator(),
//                                 );
//                               }
//                               if (grnProvider.error != null) {
//                                 return Text(
//                                   grnProvider.error!,
//                                   style: const TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 13.0,
//                                   ),
//                                 );
//                               }

//                               final reasons = List<String>.from(
//                                 grnProvider.returnReasons,
//                               )..add('Other');

//                               return ValueListenableBuilder<Map<int, String>>(
//                                 valueListenable: itemReasonsNotifier,
//                                 builder: (context, itemReasons, _) {
//                                   return ValueListenableBuilder<bool>(
//                                     valueListenable:
//                                         showCustomReasonFieldNotifier,
//                                     builder: (context, showCustomReasonField, _) {
//                                       return Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Autocomplete<String>(
//                                             optionsBuilder:
//                                                 (
//                                                   TextEditingValue
//                                                   textEditingValue,
//                                                 ) {
//                                                   return reasons
//                                                       .where(
//                                                         (reason) => reason
//                                                             .toLowerCase()
//                                                             .contains(
//                                                               textEditingValue
//                                                                   .text
//                                                                   .toLowerCase(),
//                                                             ),
//                                                       )
//                                                       .toList();
//                                                 },
//                                             onSelected: (String selection) {
//                                               if (isReturnAllEnabled) {
//                                                 if (selection == 'Other') {
//                                                   showCustomReasonFieldNotifier
//                                                           .value =
//                                                       true;
//                                                   _customReasonFocusNode
//                                                       .requestFocus();
//                                                   final updatedReasons =
//                                                       <int, String>{};
//                                                   for (
//                                                     int i = 0;
//                                                     i <
//                                                         (grn
//                                                                 .itemDetails
//                                                                 ?.length ??
//                                                             0);
//                                                     i++
//                                                   ) {
//                                                     updatedReasons[i] = '';
//                                                   }
//                                                   itemReasonsNotifier.value =
//                                                       updatedReasons;
//                                                   return;
//                                                 }

//                                                 showCustomReasonFieldNotifier
//                                                         .value =
//                                                     false;
//                                                 final updatedReasons =
//                                                     <int, String>{};
//                                                 for (
//                                                   int i = 0;
//                                                   i <
//                                                       (grn
//                                                               .itemDetails
//                                                               ?.length ??
//                                                           0);
//                                                   i++
//                                                 ) {
//                                                   updatedReasons[i] = selection;
//                                                 }
//                                                 itemReasonsNotifier.value =
//                                                     updatedReasons;
//                                                 _updateItems();
//                                               }
//                                             },
//                                             fieldViewBuilder:
//                                                 (
//                                                   BuildContext context,
//                                                   TextEditingController
//                                                   textEditingController,
//                                                   FocusNode focusNode,
//                                                   VoidCallback onFieldSubmitted,
//                                                 ) {
//                                                   return TextField(
//                                                     controller:
//                                                         textEditingController,
//                                                     focusNode: focusNode,
//                                                     onChanged: (value) {
//                                                       if (isReturnAllEnabled &&
//                                                           !showCustomReasonField) {
//                                                         final updatedReasons =
//                                                             <int, String>{};
//                                                         for (
//                                                           int i = 0;
//                                                           i <
//                                                               (grn
//                                                                       .itemDetails
//                                                                       ?.length ??
//                                                                   0);
//                                                           i++
//                                                         ) {
//                                                           updatedReasons[i] =
//                                                               value;
//                                                         }
//                                                         itemReasonsNotifier
//                                                                 .value =
//                                                             updatedReasons;
//                                                         _updateItems();
//                                                       }
//                                                     },
//                                                     decoration: InputDecoration(
//                                                       labelText:
//                                                           'Return Reason (for Return All)',
//                                                       hintText: 'Reason',
//                                                       border:
//                                                           const OutlineInputBorder(
//                                                             borderRadius:
//                                                                 BorderRadius.all(
//                                                                   Radius.circular(
//                                                                     8.0,
//                                                                   ),
//                                                                 ),
//                                                           ),
//                                                       disabledBorder:
//                                                           const OutlineInputBorder(
//                                                             borderRadius:
//                                                                 BorderRadius.all(
//                                                                   Radius.circular(
//                                                                     8.0,
//                                                                   ),
//                                                                 ),
//                                                           ),
//                                                       contentPadding:
//                                                           const EdgeInsets.symmetric(
//                                                             horizontal: 8.0,
//                                                             vertical: 6.0,
//                                                           ),
//                                                       isDense: true,
//                                                     ),
//                                                     style: TextStyle(
//                                                       fontSize: 13.0,
//                                                       color: isReturnAllEnabled
//                                                           ? Colors.black
//                                                           : Colors.grey,
//                                                     ),
//                                                     maxLines: 2,
//                                                     readOnly:
//                                                         !isReturnAllEnabled,
//                                                     enabled: isReturnAllEnabled,
//                                                   );
//                                                 },
//                                             optionsViewBuilder:
//                                                 (
//                                                   BuildContext context,
//                                                   AutocompleteOnSelected<String>
//                                                   onSelected,
//                                                   Iterable<String> options,
//                                                 ) {
//                                                   return Align(
//                                                     alignment:
//                                                         Alignment.topLeft,
//                                                     child: Material(
//                                                       color: Colors.white,
//                                                       elevation: 4.0,
//                                                       child: SizedBox(
//                                                         height: 200.0,
//                                                         child: options.isEmpty
//                                                             ? const ListTile(
//                                                                 title: Text(
//                                                                   'No reasons found',
//                                                                 ),
//                                                               )
//                                                             : ListView.builder(
//                                                                 padding:
//                                                                     EdgeInsets
//                                                                         .zero,
//                                                                 itemCount:
//                                                                     options
//                                                                         .length,
//                                                                 itemBuilder:
//                                                                     (
//                                                                       BuildContext
//                                                                       context,
//                                                                       int index,
//                                                                     ) {
//                                                                       final String
//                                                                       option = options
//                                                                           .elementAt(
//                                                                             index,
//                                                                           );
//                                                                       return GestureDetector(
//                                                                         onTap: () =>
//                                                                             onSelected(
//                                                                               option,
//                                                                             ),
//                                                                         child: ListTile(
//                                                                           title: Text(
//                                                                             option,
//                                                                             style: const TextStyle(
//                                                                               fontSize: 13,
//                                                                             ),
//                                                                           ),
//                                                                           dense:
//                                                                               true,
//                                                                         ),
//                                                                       );
//                                                                     },
//                                                               ),
//                                                       ),
//                                                     ),
//                                                   );
//                                                 },
//                                           ),
//                                           if (isReturnAllEnabled &&
//                                               showCustomReasonField) ...[
//                                             const SizedBox(height: 8),
//                                             TextField(
//                                               controller:
//                                                   _customReasonController,
//                                               focusNode: _customReasonFocusNode,
//                                               onChanged: (value) {
//                                                 final updatedReasons =
//                                                     <int, String>{};
//                                                 for (
//                                                   int i = 0;
//                                                   i <
//                                                       (grn
//                                                               .itemDetails
//                                                               ?.length ??
//                                                           0);
//                                                   i++
//                                                 ) {
//                                                   updatedReasons[i] = value;
//                                                 }
//                                                 itemReasonsNotifier.value =
//                                                     updatedReasons;
//                                                 _updateItems();
//                                               },
//                                               onSubmitted: (value) async {
//                                                 if (value.trim().isEmpty) {
//                                                   ScaffoldMessenger.of(
//                                                     context,
//                                                   ).showSnackBar(
//                                                     const SnackBar(
//                                                       content: Text(
//                                                         'Please enter a valid reason',
//                                                       ),
//                                                     ),
//                                                   );
//                                                   return;
//                                                 }

//                                                 try {
//                                                   final grnProvider =
//                                                       Provider.of<GRNProvider>(
//                                                         context,
//                                                         listen: false,
//                                                       );

//                                                   final message =
//                                                       await grnProvider
//                                                           .addReturnReason(
//                                                             value.trim(),
//                                                           );

//                                                   final updatedReasons =
//                                                       <int, String>{};
//                                                   for (
//                                                     int i = 0;
//                                                     i <
//                                                         (grn
//                                                                 .itemDetails
//                                                                 ?.length ??
//                                                             0);
//                                                     i++
//                                                   ) {
//                                                     updatedReasons[i] = value
//                                                         .trim();
//                                                   }
//                                                   itemReasonsNotifier.value =
//                                                       updatedReasons;

//                                                   ScaffoldMessenger.of(
//                                                     context,
//                                                   ).showSnackBar(
//                                                     SnackBar(
//                                                       content: Text(message),
//                                                     ),
//                                                   );
//                                                   _customReasonController
//                                                       .clear();
//                                                   showCustomReasonFieldNotifier
//                                                           .value =
//                                                       false;
//                                                 } catch (e) {
//                                                   ScaffoldMessenger.of(
//                                                     context,
//                                                   ).showSnackBar(
//                                                     SnackBar(
//                                                       content: Text(
//                                                         'Failed to add reason: $e',
//                                                       ),
//                                                     ),
//                                                   );
//                                                 }
//                                               },
//                                               decoration: const InputDecoration(
//                                                 labelText:
//                                                     'Enter Custom Reason',
//                                                 border: OutlineInputBorder(),
//                                                 contentPadding:
//                                                     EdgeInsets.symmetric(
//                                                       horizontal: 8.0,
//                                                       vertical: 6.0,
//                                                     ),
//                                                 isDense: true,
//                                               ),
//                                               style: const TextStyle(
//                                                 fontSize: 13.0,
//                                               ),
//                                               maxLines: 2,
//                                               enabled: isReturnAllEnabled,
//                                             ),
//                                           ],
//                                         ],
//                                       );
//                                     },
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Flexible(
//                           flex: 1,
//                           child: ValueListenableBuilder<bool>(
//                             valueListenable: enableReturnSelectedFieldsNotifier,
//                             builder: (context, enableReturnSelectedFields, _) {
//                               return ValueListenableBuilder<bool>(
//                                 valueListenable:
//                                     isSpecificQuantityReturnNotifier,
//                                 builder: (context, isSpecificQuantityReturn, _) {
//                                   return Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       ElevatedButton(
//                                         onPressed:
//                                             (enableReturnSelectedFields ||
//                                                 isSpecificQuantityReturn)
//                                             ? null
//                                             : () {
//                                                 print('Return All clicked');
//                                                 isReturnAllEnabledNotifier
//                                                         .value =
//                                                     true;
//                                                 enableReturnSelectedFieldsNotifier
//                                                         .value =
//                                                     false;
//                                                 isSpecificQuantityReturnNotifier
//                                                         .value =
//                                                     false;
//                                                 scenarioNotifier.value = 'full';
//                                                 itemsNotifier.value = null;
//                                               },
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: isReturnAllEnabled
//                                               ? Colors.blueAccent
//                                               : Colors.blueAccent,
//                                           foregroundColor: Colors.white,
//                                           minimumSize: const Size(120, 40),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 8,
//                                             horizontal: 12,
//                                           ),
//                                         ),
//                                         child: const Text(
//                                           'Return All',
//                                           style: TextStyle(fontSize: 14),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       ElevatedButton(
//                                         onPressed:
//                                             (isReturnAllEnabled ||
//                                                 enableReturnSelectedFields)
//                                             ? null
//                                             : () {
//                                                 print(
//                                                   'Return Specific clicked',
//                                                 );
//                                                 isSpecificQuantityReturnNotifier
//                                                         .value =
//                                                     true;
//                                                 isReturnAllEnabledNotifier
//                                                         .value =
//                                                     false;
//                                                 enableReturnSelectedFieldsNotifier
//                                                         .value =
//                                                     false;
//                                                 scenarioNotifier.value =
//                                                     'quantity_wise';
//                                                 _updateItems();
//                                               },
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor:
//                                               isSpecificQuantityReturn
//                                               ? Colors.blueAccent
//                                               : Colors.blueAccent,
//                                           foregroundColor: Colors.white,
//                                           minimumSize: const Size(120, 40),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 8,
//                                             horizontal: 12,
//                                           ),
//                                         ),
//                                         child: const Text(
//                                           'Return Specific',
//                                           style: TextStyle(fontSize: 14),
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16.0),
//                   ],
//                 );
//               },
//             ),

//             Expanded(
//               child: Card(
//                 elevation: 2,
//                 child: Column(
//                   children: [
//                     Container(
//                       height: 60,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         border: Border(
//                           bottom: BorderSide(color: Colors.grey.shade300),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 130,
//                             padding: const EdgeInsets.symmetric(horizontal: 8),
//                             child: const Text(
//                               'Item',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: SingleChildScrollView(
//                               scrollDirection: Axis.horizontal,
//                               controller: _rightHeaderHorizontal,
//                               physics: const ClampingScrollPhysics(),
//                               child: Container(
//                                 width: 1240,
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(left: 20),
//                                   child: const Row(
//                                     children: [
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Received Qty',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Returned Qty',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Returnable Qty',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Return Qty',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Nos',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Each Qty',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 180,
//                                         child: Text(
//                                           'Return Reason',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Unit Price',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 120,
//                                         child: Text(
//                                           'Total Price',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 80,
//                                         child: Text(
//                                           'Select',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     Expanded(
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: 130,
//                             child: ValueListenableBuilder<List<bool>>(
//                               valueListenable: selectedRowsNotifier,
//                               builder: (context, selectedRows, _) {
//                                 return ListView.builder(
//                                   controller: _fixedColumnScrollController,
//                                   padding: EdgeInsets.zero,
//                                   itemCount: grn.itemDetails?.length ?? 0,
//                                   itemBuilder: (context, index) {
//                                     final item = grn.itemDetails![index];
//                                     return Container(
//                                       height: 60,
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 8,
//                                         vertical: 8,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         border: Border(
//                                           bottom: BorderSide(
//                                             color: Colors.grey.shade300,
//                                           ),
//                                         ),
//                                         color: Colors.white,
//                                       ),
//                                       child: Align(
//                                         alignment: Alignment.centerLeft,
//                                         child: Text(
//                                           item.itemName ?? '',
//                                           style: const TextStyle(fontSize: 12),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                           ),

//                           Expanded(
//                             child: SingleChildScrollView(
//                               controller: _rightBodyHorizontal,
//                               scrollDirection: Axis.horizontal,
//                               physics: const ClampingScrollPhysics(),
//                               child: SizedBox(
//                                 width: 1360,
//                                 child: ValueListenableBuilder<List<bool>>(
//                                   valueListenable: selectedRowsNotifier,
//                                   builder: (context, selectedRows, _) {
//                                     return ValueListenableBuilder<bool>(
//                                       valueListenable:
//                                           enableReturnSelectedFieldsNotifier,
//                                       builder: (context, enableReturnSelectedFields, _) {
//                                         return ValueListenableBuilder<bool>(
//                                           valueListenable:
//                                               isSpecificQuantityReturnNotifier,
//                                           builder: (context, isSpecificQuantityReturn, _) {
//                                             return ValueListenableBuilder<
//                                               Map<int, String>
//                                             >(
//                                               valueListenable:
//                                                   itemReasonsNotifier,
//                                               builder: (context, itemReasons, _) {
//                                                 if (grn.itemDetails?.isEmpty ??
//                                                     true) {
//                                                   return const Center(
//                                                     child: Padding(
//                                                       padding: EdgeInsets.all(
//                                                         20.0,
//                                                       ),
//                                                       child: Text(
//                                                         'No items found',
//                                                       ),
//                                                     ),
//                                                   );
//                                                 }

//                                                 return ListView.builder(
//                                                   controller:
//                                                       _verticalScrollController,
//                                                   padding: EdgeInsets.zero,
//                                                   itemCount:
//                                                       grn.itemDetails!.length,
//                                                   itemBuilder: (context, index) {
//                                                     final item =
//                                                         grn.itemDetails![index];
//                                                     final returnableQuantity =
//                                                         (item.receivedQuantity ??
//                                                             0) -
//                                                         (item.returnedQuantity ??
//                                                             0);
//                                                     final returnQtyController =
//                                                         TextEditingController(
//                                                           text:
//                                                               item.returnedQuantity
//                                                                   ?.toStringAsFixed(
//                                                                     2,
//                                                                   ) ??
//                                                               '0.00',
//                                                         );

//                                                     return Container(
//                                                       height: 60,
//                                                       decoration: BoxDecoration(
//                                                         border: Border(
//                                                           bottom: BorderSide(
//                                                             color: Colors
//                                                                 .grey
//                                                                 .shade300,
//                                                           ),
//                                                         ),
//                                                         color: Colors.white,
//                                                       ),
//                                                       child: Row(
//                                                         children: [
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildCenteredText(
//                                                               item.receivedQuantity
//                                                                       ?.toStringAsFixed(
//                                                                         2,
//                                                                       ) ??
//                                                                   '0.00',
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildCenteredText(
//                                                               item.returnedQuantity
//                                                                       ?.toStringAsFixed(
//                                                                         2,
//                                                                       ) ??
//                                                                   '0.00',
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildCenteredText(
//                                                               returnableQuantity
//                                                                   .toStringAsFixed(
//                                                                     2,
//                                                                   ),
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildReturnQtyField(
//                                                               returnQtyController,
//                                                               item,
//                                                               index,
//                                                               selectedRows,
//                                                               isSpecificQuantityReturn,
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildReadOnlyField(
//                                                               item.nos?.toStringAsFixed(
//                                                                     2,
//                                                                   ) ??
//                                                                   '0.00',
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildReadOnlyField(
//                                                               item.eachQuantity
//                                                                       ?.toStringAsFixed(
//                                                                         2,
//                                                                       ) ??
//                                                                   '0.00',
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 180,
//                                                             child: _buildReasonField(
//                                                               item,
//                                                               index,
//                                                               selectedRows,
//                                                               enableReturnSelectedFields,
//                                                               isSpecificQuantityReturn,
//                                                               itemReasons,
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildCenteredText(
//                                                               item.unitPrice
//                                                                       ?.toStringAsFixed(
//                                                                         2,
//                                                                       ) ??
//                                                                   '0.00',
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 120,
//                                                             child: _buildCenteredText(
//                                                               (item.totalPrice ??
//                                                                       0)
//                                                                   .toStringAsFixed(
//                                                                     2,
//                                                                   ),
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                             width: 80,
//                                                             child: Center(
//                                                               child: Checkbox(
//                                                                 value:
//                                                                     selectedRows[index],
//                                                                 onChanged:
//                                                                     (enableReturnSelectedFields ||
//                                                                         isSpecificQuantityReturn)
//                                                                     ? (
//                                                                         bool?
//                                                                         value,
//                                                                       ) {
//                                                                         final updatedSelectedRows =
//                                                                             List<
//                                                                               bool
//                                                                             >.from(
//                                                                               selectedRows,
//                                                                             );
//                                                                         updatedSelectedRows[index] =
//                                                                             value ??
//                                                                             false;
//                                                                         selectedRowsNotifier.value =
//                                                                             updatedSelectedRows;
//                                                                         _updateItems();
//                                                                       }
//                                                                     : null,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     );
//                                                   },
//                                                 );
//                                               },
//                                             );
//                                           },
//                                         );
//                                       },
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   _buildSubmitButton(),
//                   const SizedBox(width: 12),
//                   _buildCancelButton(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCenteredText(String text) {
//     return Center(
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 12),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   Widget _buildReadOnlyField(String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: TextField(
//         controller: TextEditingController(text: text),
//         readOnly: true,
//         decoration: const InputDecoration(
//           isDense: true,
//           contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//           border: OutlineInputBorder(),
//         ),
//         style: const TextStyle(fontSize: 12),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   Widget _buildReturnQtyField(
//     TextEditingController controller,
//     ItemDetail item,
//     int index,
//     List<bool> selectedRows,
//     bool isSpecificQuantityReturn,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: TextField(
//         controller: controller,
//         readOnly: true,
//         enabled: isSpecificQuantityReturn && selectedRows[index],
//         onTap: isSpecificQuantityReturn && selectedRows[index]
//             ? () {
//                 showNumericCalculator(
//                   context: context,
//                   controller: controller,
//                   varianceName: 'Return Quantity',
//                   onValueSelected: () {
//                     double newReturnedQty =
//                         double.tryParse(controller.text) ?? 0;
//                     double originalQty =
//                         originalQuantities[item] ?? item.receivedQuantity ?? 0;
//                     if (newReturnedQty <= originalQty) {
//                       item.returnedQuantity = newReturnedQty;
//                       item.receivedQuantity =
//                           originalQty - item.returnedQuantity!;
//                       _updateItemQuantities(item);
//                       _recalculateItemTotals(item);
//                       _recalculateGRNTotal();
//                       _updateItems();
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'Returned quantity cannot exceed original received quantity',
//                           ),
//                         ),
//                       );
//                       controller.text =
//                           item.returnedQuantity?.toStringAsFixed(2) ?? '0.00';
//                     }
//                   },
//                   fieldType: '',
//                 );
//               }
//             : null,
//         decoration: const InputDecoration(
//           hintText: '0.00',
//           isDense: true,
//           contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//           border: OutlineInputBorder(),
//         ),
//         style: const TextStyle(fontSize: 12),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   Widget _buildReasonField(
//     ItemDetail item,
//     int index,
//     List<bool> selectedRows,
//     bool enableReturnSelectedFields,
//     bool isSpecificQuantityReturn,
//     Map<int, String> itemReasons,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: Consumer<GRNProvider>(
//         builder: (context, grnProvider, child) {
//           if (grnProvider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final returnReasons = List<String>.from(grnProvider.returnReasons)
//             ..add('Other');

//           return Autocomplete<String>(
//             optionsBuilder: (TextEditingValue textEditingValue) {
//               return returnReasons
//                   .where(
//                     (reason) => reason.toLowerCase().contains(
//                       textEditingValue.text.toLowerCase(),
//                     ),
//                   )
//                   .toList();
//             },
//             onSelected: (String selection) {
//               final updatedReasons = Map<int, String>.from(itemReasons);
//               updatedReasons[index] = selection;
//               itemReasonsNotifier.value = updatedReasons;
//               _updateItems();
//             },
//             fieldViewBuilder:
//                 (
//                   BuildContext context,
//                   TextEditingController textEditingController,
//                   FocusNode focusNode,
//                   VoidCallback onFieldSubmitted,
//                 ) {
//                   textEditingController.text = itemReasons[index] ?? '';
//                   return TextField(
//                     controller: textEditingController,
//                     focusNode: focusNode,
//                     onChanged: (value) {
//                       final updatedReasons = Map<int, String>.from(itemReasons);
//                       updatedReasons[index] = value;
//                       itemReasonsNotifier.value = updatedReasons;
//                       _updateItems();
//                     },
//                     decoration: const InputDecoration(
//                       hintText: 'Reason',
//                       isDense: true,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 4,
//                         vertical: 8,
//                       ),
//                       border: OutlineInputBorder(),
//                     ),
//                     enabled:
//                         (enableReturnSelectedFields ||
//                             isSpecificQuantityReturn) &&
//                         selectedRows[index],
//                     style: const TextStyle(fontSize: 12),
//                   );
//                 },
//             optionsViewBuilder:
//                 (
//                   BuildContext context,
//                   AutocompleteOnSelected<String> onSelected,
//                   Iterable<String> options,
//                 ) {
//                   return Align(
//                     alignment: Alignment.topLeft,
//                     child: Material(
//                       color: Colors.white,
//                       elevation: 4.0,
//                       child: ConstrainedBox(
//                         constraints: const BoxConstraints(maxHeight: 200),
//                         child: ListView.builder(
//                           padding: EdgeInsets.zero,
//                           shrinkWrap: true,
//                           itemCount: options.length,
//                           itemBuilder: (BuildContext context, int index) {
//                             final String option = options.elementAt(index);
//                             return ListTile(
//                               title: Text(
//                                 option,
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                               dense: true,
//                               onTap: () => onSelected(option),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSubmitButton() {
//     return ValueListenableBuilder<String?>(
//       valueListenable: scenarioNotifier,
//       builder: (context, scenario, _) {
//         return ValueListenableBuilder<DateTime?>(
//           valueListenable: returnDateNotifier,
//           builder: (context, returnDate, _) {
//             return ValueListenableBuilder<List<Map<String, dynamic>>?>(
//               valueListenable: itemsNotifier,
//               builder: (context, items, _) {
//                 return ValueListenableBuilder<Map<int, String>>(
//                   valueListenable: itemReasonsNotifier,
//                   builder: (context, itemReasons, _) {
//                     final isDisabled =
//                         scenario == null ||
//                         returnDate == null ||
//                         (scenario == 'partial' &&
//                             (items == null || items.isEmpty));

//                     return ElevatedButton(
//                       onPressed: isDisabled ? null : _submitReturn,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(120, 50),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 24,
//                           vertical: 12,
//                         ),
//                       ),
//                       child: const Text(
//                         'Submit Return',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildCancelButton() {
//     return ElevatedButton(
//       onPressed: () => Navigator.of(context).pop(),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.grey[300],
//         foregroundColor: Colors.black,
//         minimumSize: const Size(120, 50),
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       ),
//       child: const Text('Cancel', style: TextStyle(fontSize: 16)),
//     );
//   }

//   void _submitReturn() async {
//     if (scenarioNotifier.value == null || returnDateNotifier.value == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a return scenario and date'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     bool isValid = true;
//     String? errorMessage;

//     if (scenarioNotifier.value == 'full') {
//       if (itemReasonsNotifier.value.isEmpty ||
//           itemReasonsNotifier.value.values.every(
//             (reason) => reason.trim().isEmpty,
//           )) {
//         isValid = false;
//         errorMessage = 'Please enter a reason for full return.';
//       }
//     } else {
//       for (int i = 0; i < grn.itemDetails!.length; i++) {
//         if (!selectedRowsNotifier.value[i]) continue;
//         final item = grn.itemDetails![i];
//         final reason = itemReasonsNotifier.value[i] ?? '';
//         final returnQty = item.returnedQuantity ?? 0;
//         final originalQty =
//             originalQuantities[item] ?? item.receivedQuantity ?? 0;

//         if (reason.trim().isEmpty) {
//           isValid = false;
//           errorMessage = 'Please enter a reason for selected items.';
//           break;
//         }
//         if (returnQty > originalQty) {
//           isValid = false;
//           errorMessage = 'Returned quantity cannot exceed received quantity.';
//           break;
//         }
//       }
//     }

//     if (!isValid) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage ?? 'Validation failed'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: const Text('Confirm GRN Return'),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('GRN No: ${grn.randomId}'),
//             const SizedBox(height: 8),
//             Text(
//               'Return Date: ${DateFormat('dd MMM yyyy').format(returnDateNotifier.value!)}',
//             ),
//             const SizedBox(height: 16),
//             if (scenarioNotifier.value == 'full') ...[
//               const Text(
//                 'Returning ALL items',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Reason: ${itemReasonsNotifier.value.isNotEmpty ? itemReasonsNotifier.value.values.first : "Not specified"}',
//               ),
//             ] else ...[
//               const Text(
//                 'Returning Selected Items:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               DataTable(
//                 columnSpacing: 16,
//                 headingRowColor: WidgetStateColor.resolveWith(
//                   (_) => Colors.grey[200]!,
//                 ),
//                 columns: const [
//                   DataColumn(label: Text('Item')),
//                   DataColumn(label: Text('Qty')),
//                   DataColumn(label: Text('Unit')),
//                   DataColumn(label: Text('Reason')),
//                 ],
//                 rows: grn.itemDetails!
//                     .asMap()
//                     .entries
//                     .where((e) => selectedRowsNotifier.value[e.key])
//                     .map((e) {
//                       final index = e.key;
//                       final item = e.value;
//                       return DataRow(
//                         cells: [
//                           DataCell(Text(item.itemName ?? '')),
//                           DataCell(
//                             Text(
//                               item.returnedQuantity?.toStringAsFixed(2) ??
//                                   '0.00',
//                             ),
//                           ),
//                           DataCell(
//                             Text(item.unitPrice?.toStringAsFixed(2) ?? '0.00'),
//                           ),
//                           DataCell(
//                             Text(
//                               itemReasonsNotifier.value[index] ??
//                                   'Not specified',
//                             ),
//                           ),
//                         ],
//                       );
//                     })
//                     .toList(),
//               ),
//             ],
//             const SizedBox(height: 16),
//             Text(
//               'Total Items: ${scenarioNotifier.value == 'full' ? grn.itemDetails?.length ?? 0 : itemsNotifier.value?.length ?? 0}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Confirm Return'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     final convertedItems = scenarioNotifier.value == 'full'
//         ? _buildFullReturnItems()
//         : itemsNotifier.value
//               ?.where(
//                 (item) =>
//                     item['itemId'] != null &&
//                     item['itemId'].toString().isNotEmpty,
//               )
//               .map((item) => ReturnItem.fromMap(item))
//               .toList();

//     final grnProvider = Provider.of<GRNProvider>(context, listen: false);
//     try {
//       print(
//         'Submitting GRN return: scenario=${scenarioNotifier.value}, items=$convertedItems',
//       );

//       await grnProvider.returnGrn(
//         grnId,
//         ReturnGRNRequest(
//           scenario: mapScenario(scenarioNotifier.value!),
//           returnedDate: returnDateNotifier.value!,
//           returnedBy: returnedBy,
//           comments: scenarioNotifier.value == 'full'
//               ? (itemReasonsNotifier.value.isNotEmpty
//                     ? itemReasonsNotifier.value.values.first
//                     : null)
//               : null,
//           items: convertedItems,
//         ),
//       );

//       print('GRN return processed successfully');

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Return processed successfully'),
//             duration: Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }

//       await Future.delayed(const Duration(milliseconds: 1500));

//       if (mounted) {
//         Navigator.of(context).pop();
//       }
//     } catch (e) {
//       print('Error processing GRN return: $e');

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to process return: $e'),
//             duration: const Duration(seconds: 3),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   String mapScenario(String scenario) {
//     if (scenario == "full") return "full";
//     return "partial";
//   }

//   List<ReturnItem> _buildFullReturnItems() {
//     final items = <ReturnItem>[];

//     for (int i = 0; i < (grn.itemDetails?.length ?? 0); i++) {
//       final item = grn.itemDetails![i];

//       if (item.itemId != null &&
//           item.itemId!.isNotEmpty &&
//           _isValidObjectId(item.itemId!)) {
//         final returnItem = ReturnItem(
//           itemId: item.itemId!,
//           nos: item.nos,
//           eachQuantity: item.eachQuantity,
//           returnReason: itemReasonsNotifier.value[i] ?? 'Full return',
//           returnedQuantity: item.receivedQuantity,
//         );

//         items.add(returnItem);
//       } else {
//         print(
//           'Skipping item without valid ObjectId: ${item.itemName} (ID: ${item.itemId})',
//         );
//       }
//     }

//     if (items.isEmpty) {
//       print('WARNING: No items with valid ObjectIds found for full return');
//     }

//     return items;
//   }

//   bool _isValidObjectId(String id) {
//     if (id.length != 24) return false;
//     final hexRegex = RegExp(r'^[0-9a-fA-F]{24}$');
//     return hexRegex.hasMatch(id);
//   }

//   void _updateItems() {
//     if (scenarioNotifier.value == 'item_wise' ||
//         scenarioNotifier.value == 'quantity_wise') {
//       final updatedItems = grn.itemDetails
//           ?.asMap()
//           .entries
//           .where((entry) => selectedRowsNotifier.value[entry.key])
//           .map((entry) {
//             final index = entry.key;
//             final item = entry.value;

//             String itemId;
//             if (item.itemId != null && item.itemId!.isNotEmpty) {
//               itemId = item.itemId!;
//             } else {
//               itemId = 'temp_${item.itemName?.hashCode ?? index}';
//             }

//             return {
//               'itemId': itemId,
//               'nos': item.nos,
//               'eachQuantity': item.eachQuantity,
//               'returnReason': itemReasonsNotifier.value[index] ?? '',
//               if (scenarioNotifier.value == 'quantity_wise')
//                 'returnedQuantity': item.returnedQuantity,
//             };
//           })
//           .toList();
//       itemsNotifier.value = updatedItems;
//       print('Updated items: $updatedItems');
//     }
//   }

//   void _updateItemQuantities(ItemDetail item) {
//     double? originalEachQty =
//         originalEachQuantities[item] ?? item.eachQuantity ?? 1;
//     double? originalNos = item.nos ?? 1;

//     if (item.returnedQuantity != null && item.returnedQuantity! > 0) {
//       if (originalNos > 0) {
//         item.eachQuantity = (item.returnedQuantity! / originalNos);
//         item.nos = originalNos;
//       } else if (originalEachQty > 0) {
//         item.nos = (item.returnedQuantity! / originalEachQty);
//         item.eachQuantity = originalEachQty;
//       } else {
//         item.nos = item.returnedQuantity!;
//         item.eachQuantity = 1;
//       }
//     } else {
//       item.nos = 0;
//       item.eachQuantity = 0;
//     }
//     print(
//       'Updated quantities for item ${item.itemName}: nos=${item.nos}, eachQuantity=${item.eachQuantity}',
//     );
//   }

//   void _recalculateItemTotals(ItemDetail item) {
//     item.discountAmount =
//         ((item.receivedQuantity ?? 0) * (item.unitPrice ?? 0)) *
//         (grn.discountPrice ?? 0) /
//         100;
//     double discountedPrice =
//         ((item.receivedQuantity ?? 0) * (item.unitPrice ?? 0)) -
//         (item.discountAmount ?? 0);
//     item.taxAmount = discountedPrice * (item.purchasetaxName ?? 0) / 100;
//     print(
//       'Recalculated totals for item ${item.itemName}: discount=${item.discountAmount}, tax=${item.taxAmount}',
//     );
//   }

//   void _recalculateGRNTotal() {
//     grn.totalReceivedAmount =
//         grn.itemDetails?.fold(
//           0.0,
//           (total, item) => total! + (item.finalPrice ?? 0),
//         ) ??
//         0.0;
//     print('Recalculated GRN total: ${grn.totalReceivedAmount}');
//   }

//   String formatDate(String? date) {
//     if (date == null || date.isEmpty) return 'No Date';
//     try {
//       final DateTime parsedDate = DateTime.parse(date);
//       return DateFormat('dd MMM yyyy').format(parsedDate);
//     } catch (e) {
//       print('Error formatting date $date: $e');
//       return date ?? 'No Date';
//     }
//   }
// }

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grnitem.dart';
import '../../models/grn.dart';
import '../../providers/grn_provider.dart';
import 'package:provider/provider.dart';
import '../../utils/calculator_utils.dart';

class GRNReturn extends StatefulWidget {
  final GRN grn;

  const GRNReturn({super.key, required this.grn});

  @override
  _GRNModalState createState() => _GRNModalState();
}

class _GRNModalState extends State<GRNReturn> {
  late GRN grn;
  late ValueNotifier<List<bool>> selectedRowsNotifier;
  late ValueNotifier<bool> isReturnAllEnabledNotifier;
  late ValueNotifier<bool> enableReturnSelectedFieldsNotifier;
  late ValueNotifier<bool> isSpecificQuantityReturnNotifier;
  late Map<ItemDetail, double?> originalQuantities;
  late Map<ItemDetail, double?> originalEachQuantities;
  late ValueNotifier<String?> scenarioNotifier;
  late String grnId;
  late ValueNotifier<DateTime?> returnDateNotifier;
  late String returnedBy;
  late ValueNotifier<Map<int, String>> itemReasonsNotifier;
  late ValueNotifier<List<Map<String, dynamic>>?> itemsNotifier;
  late ValueNotifier<String?> reasonErrorNotifier;
  late ValueNotifier<Map<int, String?>> quantityErrorsNotifier;
  late ValueNotifier<Map<int, String?>> reasonErrorsNotifier;

  // Scroll controllers for synchronized scrolling
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _headerHorizontalScrollController = ScrollController();
  final ScrollController _bodyHorizontalScrollController = ScrollController();
  final ScrollController _fixedColumnScrollController = ScrollController();

  final ScrollController _rightHeaderHorizontal = ScrollController();
  final ScrollController _rightBodyHorizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    grn = widget.grn;
    _syncHorizontalScroll();

    selectedRowsNotifier = ValueNotifier<List<bool>>(
      List<bool>.filled(grn.itemDetails?.length ?? 0, false),
    );
    isReturnAllEnabledNotifier = ValueNotifier<bool>(false);
    enableReturnSelectedFieldsNotifier = ValueNotifier<bool>(false);
    isSpecificQuantityReturnNotifier = ValueNotifier<bool>(false);
    originalQuantities = {};
    originalEachQuantities = {};
    for (var item in grn.itemDetails ?? []) {
      originalQuantities[item] = item.receivedQuantity ?? 0;
      originalEachQuantities[item] = item.eachQuantity ?? 1;
    }
    scenarioNotifier = ValueNotifier<String?>(null);
    grnId = grn.grnId ?? '';
    returnedBy = 'user123';
    returnDateNotifier = ValueNotifier<DateTime?>(DateTime.now());
    itemReasonsNotifier = ValueNotifier<Map<int, String>>({});
    itemsNotifier = ValueNotifier<List<Map<String, dynamic>>?>([]);
    reasonErrorNotifier = ValueNotifier<String?>(null);
    quantityErrorsNotifier = ValueNotifier<Map<int, String?>>({});
    reasonErrorsNotifier = ValueNotifier<Map<int, String?>>({});

    // Setup scroll synchronization
    _verticalScrollController.addListener(_syncVerticalScroll);
    _fixedColumnScrollController.addListener(_syncVerticalScroll);
  }

  void _syncVerticalScroll() {
    if (_verticalScrollController.hasClients &&
        _fixedColumnScrollController.hasClients) {
      if (_verticalScrollController.position.activity?.isScrolling ?? false) {
        _fixedColumnScrollController.jumpTo(_verticalScrollController.offset);
      }
    }
  }

  void _syncHorizontalScroll() {
    _rightHeaderHorizontal.addListener(() {
      if (_rightBodyHorizontal.offset != _rightHeaderHorizontal.offset) {
        _rightBodyHorizontal.jumpTo(_rightHeaderHorizontal.offset);
      }
    });

    _rightBodyHorizontal.addListener(() {
      if (_rightHeaderHorizontal.offset != _rightBodyHorizontal.offset) {
        _rightHeaderHorizontal.jumpTo(_rightBodyHorizontal.offset);
      }
    });
  }

  @override
  void dispose() {
    selectedRowsNotifier.dispose();
    isReturnAllEnabledNotifier.dispose();
    enableReturnSelectedFieldsNotifier.dispose();
    isSpecificQuantityReturnNotifier.dispose();
    scenarioNotifier.dispose();
    returnDateNotifier.dispose();
    itemReasonsNotifier.dispose();
    itemsNotifier.dispose();
    reasonErrorNotifier.dispose();
    quantityErrorsNotifier.dispose();
    reasonErrorsNotifier.dispose();
    originalQuantities.clear();
    originalEachQuantities.clear();
    _verticalScrollController.dispose();
    _headerHorizontalScrollController.dispose();
    _bodyHorizontalScrollController.dispose();
    _fixedColumnScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRN No: ${grn.randomId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: Text(
                        'Vendor: ${grn.vendorName ?? 'N/A'}',
                        style: const TextStyle(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                    Text('Date: ${formatDate(grn.grnDate)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // Return Options Section
            ValueListenableBuilder<bool>(
              valueListenable: isReturnAllEnabledNotifier,
              builder: (context, isReturnAllEnabled, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Consumer<GRNProvider>(
                            builder: (context, grnProvider, child) {
                              if (grnProvider.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (grnProvider.error != null) {
                                return Text(
                                  grnProvider.error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13.0,
                                  ),
                                );
                              }

                              final reasons = List<String>.from(
                                grnProvider.returnReasons,
                              );

                              return ValueListenableBuilder<Map<int, String>>(
                                valueListenable: itemReasonsNotifier,
                                builder: (context, itemReasons, _) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Autocomplete<String>(
                                        optionsBuilder:
                                            (
                                              TextEditingValue textEditingValue,
                                            ) {
                                              return reasons
                                                  .where(
                                                    (reason) => reason
                                                        .toLowerCase()
                                                        .contains(
                                                          textEditingValue.text
                                                              .toLowerCase(),
                                                        ),
                                                  )
                                                  .toList();
                                            },
                                        onSelected: (String selection) {
                                          if (isReturnAllEnabled) {
                                            final updatedReasons =
                                                <int, String>{};
                                            for (
                                              int i = 0;
                                              i <
                                                  (grn.itemDetails?.length ??
                                                      0);
                                              i++
                                            ) {
                                              updatedReasons[i] = selection;
                                            }
                                            itemReasonsNotifier.value =
                                                updatedReasons;
                                            _updateItems();
                                          }
                                        },
                                        fieldViewBuilder:
                                            (
                                              BuildContext context,
                                              TextEditingController
                                              textEditingController,
                                              FocusNode focusNode,
                                              VoidCallback onFieldSubmitted,
                                            ) {
                                              return TextField(
                                                controller:
                                                    textEditingController,
                                                focusNode: focusNode,
                                                onChanged: (value) {
                                                  if (isReturnAllEnabled) {
                                                    final updatedReasons =
                                                        <int, String>{};
                                                    for (
                                                      int i = 0;
                                                      i <
                                                          (grn
                                                                  .itemDetails
                                                                  ?.length ??
                                                              0);
                                                      i++
                                                    ) {
                                                      updatedReasons[i] = value;
                                                    }
                                                    itemReasonsNotifier.value =
                                                        updatedReasons;
                                                    _updateItems();
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Return Reason (for Return All)',
                                                  hintText: 'Reason',
                                                  border:
                                                      const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8.0,
                                                              ),
                                                            ),
                                                      ),
                                                  disabledBorder:
                                                      const OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                8.0,
                                                              ),
                                                            ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 6.0,
                                                      ),
                                                  isDense: true,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13.0,
                                                  color: isReturnAllEnabled
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                                maxLines: 2,
                                                readOnly: !isReturnAllEnabled,
                                                enabled: isReturnAllEnabled,
                                              );
                                            },
                                        optionsViewBuilder:
                                            (
                                              BuildContext context,
                                              AutocompleteOnSelected<String>
                                              onSelected,
                                              Iterable<String> options,
                                            ) {
                                              return Align(
                                                alignment: Alignment.topLeft,
                                                child: Material(
                                                  color: Colors.white,
                                                  elevation: 4.0,
                                                  child: SizedBox(
                                                    height: 200.0,
                                                    child: options.isEmpty
                                                        ? const ListTile(
                                                            title: Text(
                                                              'No reasons found',
                                                            ),
                                                          )
                                                        : ListView.builder(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            itemCount:
                                                                options.length,
                                                            itemBuilder:
                                                                (
                                                                  BuildContext
                                                                  context,
                                                                  int index,
                                                                ) {
                                                                  final String
                                                                  option = options
                                                                      .elementAt(
                                                                        index,
                                                                      );
                                                                  return GestureDetector(
                                                                    onTap: () =>
                                                                        onSelected(
                                                                          option,
                                                                        ),
                                                                    child: ListTile(
                                                                      title: Text(
                                                                        option,
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                        ),
                                                                      ),
                                                                      dense:
                                                                          true,
                                                                    ),
                                                                  );
                                                                },
                                                          ),
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 1,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: enableReturnSelectedFieldsNotifier,
                            builder: (context, enableReturnSelectedFields, _) {
                              return ValueListenableBuilder<bool>(
                                valueListenable:
                                    isSpecificQuantityReturnNotifier,
                                builder: (context, isSpecificQuantityReturn, _) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed:
                                            (enableReturnSelectedFields ||
                                                isSpecificQuantityReturn)
                                            ? null
                                            : () {
                                                print('Return All clicked');
                                                isReturnAllEnabledNotifier
                                                        .value =
                                                    true;
                                                enableReturnSelectedFieldsNotifier
                                                        .value =
                                                    false;
                                                isSpecificQuantityReturnNotifier
                                                        .value =
                                                    false;
                                                scenarioNotifier.value = 'full';
                                                itemsNotifier.value = null;
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isReturnAllEnabled
                                              ? Colors.blueAccent
                                              : Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(120, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Return All',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed:
                                            (isReturnAllEnabled ||
                                                enableReturnSelectedFields)
                                            ? null
                                            : () {
                                                print(
                                                  'Return Specific clicked',
                                                );
                                                isSpecificQuantityReturnNotifier
                                                        .value =
                                                    true;
                                                isReturnAllEnabledNotifier
                                                        .value =
                                                    false;
                                                enableReturnSelectedFieldsNotifier
                                                        .value =
                                                    false;
                                                scenarioNotifier.value =
                                                    'quantity_wise';
                                                _updateItems();
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isSpecificQuantityReturn
                                              ? Colors.blueAccent
                                              : Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(120, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Return Specific',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                  ],
                );
              },
            ),

            Expanded(
              child: Card(
                elevation: 2,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 130,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Text(
                              'Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _rightHeaderHorizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Container(
                                width: 1240,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Received Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Returned Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Returnable Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Return Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Nos',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Each Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          'Return Reason',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Unit Price',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Total Price',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Select',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: ValueListenableBuilder<List<bool>>(
                              valueListenable: selectedRowsNotifier,
                              builder: (context, selectedRows, _) {
                                return ListView.builder(
                                  controller: _fixedColumnScrollController,
                                  padding: EdgeInsets.zero,
                                  itemCount: grn.itemDetails?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final item = grn.itemDetails![index];
                                    return Container(
                                      height: 60,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item.itemName ?? '',
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              controller: _rightBodyHorizontal,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                width: 1360,
                                child: ValueListenableBuilder<List<bool>>(
                                  valueListenable: selectedRowsNotifier,
                                  builder: (context, selectedRows, _) {
                                    return ValueListenableBuilder<bool>(
                                      valueListenable:
                                          enableReturnSelectedFieldsNotifier,
                                      builder: (context, enableReturnSelectedFields, _) {
                                        return ValueListenableBuilder<bool>(
                                          valueListenable:
                                              isSpecificQuantityReturnNotifier,
                                          builder: (context, isSpecificQuantityReturn, _) {
                                            return ValueListenableBuilder<
                                              Map<int, String>
                                            >(
                                              valueListenable:
                                                  itemReasonsNotifier,
                                              builder: (context, itemReasons, _) {
                                                if (grn.itemDetails?.isEmpty ??
                                                    true) {
                                                  return const Center(
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        20.0,
                                                      ),
                                                      child: Text(
                                                        'No items found',
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return ListView.builder(
                                                  controller:
                                                      _verticalScrollController,
                                                  padding: EdgeInsets.zero,
                                                  itemCount:
                                                      grn.itemDetails!.length,
                                                  itemBuilder: (context, index) {
                                                    final item =
                                                        grn.itemDetails![index];
                                                    final returnableQuantity =
                                                        (item.receivedQuantity ??
                                                            0) -
                                                        (item.returnedQuantity ??
                                                            0);
                                                    final returnQtyController =
                                                        TextEditingController(
                                                          text:
                                                              item.returnedQuantity
                                                                  ?.toStringAsFixed(
                                                                    2,
                                                                  ) ??
                                                              '0.00',
                                                        );

                                                    return Container(
                                                      height: 60,
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors
                                                                .grey
                                                                .shade300,
                                                          ),
                                                        ),
                                                        color: Colors.white,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildCenteredText(
                                                              item.receivedQuantity
                                                                      ?.toStringAsFixed(
                                                                        2,
                                                                      ) ??
                                                                  '0.00',
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildCenteredText(
                                                              item.returnedQuantity
                                                                      ?.toStringAsFixed(
                                                                        2,
                                                                      ) ??
                                                                  '0.00',
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildCenteredText(
                                                              returnableQuantity
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildReturnQtyField(
                                                              returnQtyController,
                                                              item,
                                                              index,
                                                              selectedRows,
                                                              isSpecificQuantityReturn,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildReadOnlyField(
                                                              item.nos?.toStringAsFixed(
                                                                    2,
                                                                  ) ??
                                                                  '0.00',
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildReadOnlyField(
                                                              item.eachQuantity
                                                                      ?.toStringAsFixed(
                                                                        2,
                                                                      ) ??
                                                                  '0.00',
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 180,
                                                            child: _buildReasonField(
                                                              item,
                                                              index,
                                                              selectedRows,
                                                              enableReturnSelectedFields,
                                                              isSpecificQuantityReturn,
                                                              itemReasons,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildCenteredText(
                                                              item.unitPrice
                                                                      ?.toStringAsFixed(
                                                                        2,
                                                                      ) ??
                                                                  '0.00',
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            child: _buildCenteredText(
                                                              (item.totalPrice ??
                                                                      0)
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 80,
                                                            child: Center(
                                                              child: Checkbox(
                                                                value:
                                                                    selectedRows[index],
                                                                onChanged:
                                                                    (enableReturnSelectedFields ||
                                                                        isSpecificQuantityReturn)
                                                                    ? (
                                                                        bool?
                                                                        value,
                                                                      ) {
                                                                        final updatedSelectedRows =
                                                                            List<
                                                                              bool
                                                                            >.from(
                                                                              selectedRows,
                                                                            );
                                                                        updatedSelectedRows[index] =
                                                                            value ??
                                                                            false;
                                                                        selectedRowsNotifier.value =
                                                                            updatedSelectedRows;
                                                                        _updateItems();
                                                                      }
                                                                    : null,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSubmitButton(),
                  const SizedBox(width: 12),
                  _buildCancelButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredText(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: TextEditingController(text: text),
        readOnly: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReturnQtyField(
    TextEditingController controller,
    ItemDetail item,
    int index,
    List<bool> selectedRows,
    bool isSpecificQuantityReturn,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        readOnly: true,
        enabled: isSpecificQuantityReturn && selectedRows[index],
        onTap: isSpecificQuantityReturn && selectedRows[index]
            ? () {
                showNumericCalculator(
                  context: context,
                  controller: controller,
                  varianceName: 'Return Quantity',
                  onValueSelected: () {
                    double newReturnedQty =
                        double.tryParse(controller.text) ?? 0;
                    double originalQty =
                        originalQuantities[item] ?? item.receivedQuantity ?? 0;
                    if (newReturnedQty <= originalQty) {
                      item.returnedQuantity = newReturnedQty;
                      item.receivedQuantity =
                          originalQty - item.returnedQuantity!;
                      _updateItemQuantities(item);
                      _recalculateItemTotals(item);
                      _recalculateGRNTotal();
                      _updateItems();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Returned quantity cannot exceed original received quantity',
                          ),
                        ),
                      );
                      controller.text =
                          item.returnedQuantity?.toStringAsFixed(2) ?? '0.00';
                    }
                  },
                  fieldType: '',
                );
              }
            : null,
        decoration: const InputDecoration(
          hintText: '0.00',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReasonField(
    ItemDetail item,
    int index,
    List<bool> selectedRows,
    bool enableReturnSelectedFields,
    bool isSpecificQuantityReturn,
    Map<int, String> itemReasons,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Consumer<GRNProvider>(
        builder: (context, grnProvider, child) {
          if (grnProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final returnReasons = List<String>.from(grnProvider.returnReasons);

          return Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return returnReasons
                  .where(
                    (reason) => reason.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  )
                  .toList();
            },
            onSelected: (String selection) {
              final updatedReasons = Map<int, String>.from(itemReasons);
              updatedReasons[index] = selection;
              itemReasonsNotifier.value = updatedReasons;
              _updateItems();
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  textEditingController.text = itemReasons[index] ?? '';
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onChanged: (value) {
                      final updatedReasons = Map<int, String>.from(itemReasons);
                      updatedReasons[index] = value;
                      itemReasonsNotifier.value = updatedReasons;
                      _updateItems();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Reason',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    enabled:
                        (enableReturnSelectedFields ||
                            isSpecificQuantityReturn) &&
                        selectedRows[index],
                    style: const TextStyle(fontSize: 12),
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: Colors.white,
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option,
                                style: const TextStyle(fontSize: 12),
                              ),
                              dense: true,
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ValueListenableBuilder<String?>(
      valueListenable: scenarioNotifier,
      builder: (context, scenario, _) {
        return ValueListenableBuilder<DateTime?>(
          valueListenable: returnDateNotifier,
          builder: (context, returnDate, _) {
            return ValueListenableBuilder<List<Map<String, dynamic>>?>(
              valueListenable: itemsNotifier,
              builder: (context, items, _) {
                return ValueListenableBuilder<Map<int, String>>(
                  valueListenable: itemReasonsNotifier,
                  builder: (context, itemReasons, _) {
                    final isDisabled =
                        scenario == null ||
                        returnDate == null ||
                        (scenario == 'partial' &&
                            (items == null || items.isEmpty));

                    return ElevatedButton(
                      onPressed: isDisabled ? null : _submitReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Submit Return',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        minimumSize: const Size(120, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
    );
  }

  void _submitReturn() async {
    if (scenarioNotifier.value == null || returnDateNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a return scenario and date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isValid = true;
    String? errorMessage;

    if (scenarioNotifier.value == 'full') {
      if (itemReasonsNotifier.value.isEmpty ||
          itemReasonsNotifier.value.values.every(
            (reason) => reason.trim().isEmpty,
          )) {
        isValid = false;
        errorMessage = 'Please enter a reason for full return.';
      }
    } else {
      for (int i = 0; i < grn.itemDetails!.length; i++) {
        if (!selectedRowsNotifier.value[i]) continue;
        final item = grn.itemDetails![i];
        final reason = itemReasonsNotifier.value[i] ?? '';
        final returnQty = item.returnedQuantity ?? 0;
        final originalQty =
            originalQuantities[item] ?? item.receivedQuantity ?? 0;

        if (reason.trim().isEmpty) {
          isValid = false;
          errorMessage = 'Please enter a reason for selected items.';
          break;
        }
        if (returnQty > originalQty) {
          isValid = false;
          errorMessage = 'Returned quantity cannot exceed received quantity.';
          break;
        }
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Validation failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Builder(
              builder: (innerContext) {
                // Calculate selected items
                final selectedItems =
                    grn.itemDetails != null && grn.itemDetails!.isNotEmpty
                    ? grn.itemDetails!
                          .asMap()
                          .entries
                          .where((e) => selectedRowsNotifier.value[e.key])
                          .toList()
                    : <MapEntry<int, ItemDetail>>[];

                // Calculate table height for selected items
                final tableHeight = selectedItems.isNotEmpty
                    ? (selectedItems.length * 60.0) +
                          40.0 // 60 per row (for wrapped text) + header
                    : 0.0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Confirm GRN Return',
                        style: Theme.of(innerContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),

                    // GRN Details
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text(
                            'GRN No:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            grn.randomId ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Return Date:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            returnDateNotifier.value != null
                                ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(returnDateNotifier.value!)
                                : 'Not set',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Return Details
                    if (scenarioNotifier.value == 'full') ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Returning ALL Items',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reason:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    itemReasonsNotifier.value.isNotEmpty
                                        ? itemReasonsNotifier.value.values.first
                                        : 'Not specified',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: const Text(
                          'Returning Selected Items',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Items Table - Compact version with horizontal scrolling (scrollbar hidden)
                      if (selectedItems.isNotEmpty) ...[
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: tableHeight.clamp(
                              100.0,
                              400.0,
                            ), // Min 100, Max 400
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 400, // Compact width - reduced from 600
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2.0), // Item - flexible
                                  1: FixedColumnWidth(
                                    70,
                                  ), // Qty - fixed compact
                                  2: FixedColumnWidth(
                                    90,
                                  ), // Unit Price - fixed compact
                                  3: FlexColumnWidth(
                                    2.5,
                                  ), // Reason - flexible for wrapping
                                },
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                border: TableBorder.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                children: [
                                  // Header
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                    ),
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          'Item',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          'Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          'Unit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          'Reason',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Data Rows Only
                                  ...selectedItems.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: index.isEven
                                            ? Colors.white
                                            : Colors.grey[50],
                                      ),
                                      children: [
                                        // Item Name
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            item.itemName ?? 'No Name',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Quantity
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            item.returnedQuantity
                                                    ?.toStringAsFixed(2) ??
                                                '0.00',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                        // Unit Price
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            item.unitPrice?.toStringAsFixed(
                                                  2,
                                                ) ??
                                                '0.00',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                        // Reason - This will wrap to next line
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 8,
                                          ),
                                          child: SizedBox(
                                            width:
                                                180, // Fixed width for reason column
                                            child: Text(
                                              itemReasonsNotifier
                                                      .value[index] ??
                                                  'Not specified',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 2, // Allow 2 lines
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No items selected',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ],

                    // Total Items - Only show if not full return
                    if (scenarioNotifier.value != 'full') ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 20),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Total Items: ${itemsNotifier.value?.length ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Buttons - Fixed Row with proper spacing
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(innerContext, false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(innerContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Confirm Return',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final convertedItems = scenarioNotifier.value == 'full'
        ? _buildFullReturnItems()
        : itemsNotifier.value
              ?.where(
                (item) =>
                    item['itemId'] != null &&
                    item['itemId'].toString().isNotEmpty,
              )
              .map((item) => ReturnItem.fromMap(item))
              .toList();

    final grnProvider = Provider.of<GRNProvider>(context, listen: false);
    try {
      print(
        'Submitting GRN return: scenario=${scenarioNotifier.value}, items=$convertedItems',
      );

      await grnProvider.returnGrn(
        grnId,
        ReturnGRNRequest(
          scenario: mapScenario(scenarioNotifier.value!),
          returnedDate: returnDateNotifier.value!,
          returnedBy: returnedBy,
          comments: scenarioNotifier.value == 'full'
              ? (itemReasonsNotifier.value.isNotEmpty
                    ? itemReasonsNotifier.value.values.first
                    : null)
              : null,
          items: convertedItems,
        ),
      );

      print('GRN return processed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return processed successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error processing GRN return: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process return: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String mapScenario(String scenario) {
    if (scenario == "full") return "full";
    return "partial";
  }

  List<ReturnItem> _buildFullReturnItems() {
    final items = <ReturnItem>[];

    for (int i = 0; i < (grn.itemDetails?.length ?? 0); i++) {
      final item = grn.itemDetails![i];

      if (item.itemId != null &&
          item.itemId!.isNotEmpty &&
          _isValidObjectId(item.itemId!)) {
        final returnItem = ReturnItem(
          itemId: item.itemId!,
          nos: item.nos,
          eachQuantity: item.eachQuantity,
          returnReason: itemReasonsNotifier.value[i] ?? 'Full return',
          returnedQuantity: item.receivedQuantity,
        );

        items.add(returnItem);
      } else {
        print(
          'Skipping item without valid ObjectId: ${item.itemName} (ID: ${item.itemId})',
        );
      }
    }

    if (items.isEmpty) {
      print('WARNING: No items with valid ObjectIds found for full return');
    }

    return items;
  }

  bool _isValidObjectId(String id) {
    if (id.length != 24) return false;
    final hexRegex = RegExp(r'^[0-9a-fA-F]{24}$');
    return hexRegex.hasMatch(id);
  }

  void _updateItems() {
    if (scenarioNotifier.value == 'item_wise' ||
        scenarioNotifier.value == 'quantity_wise') {
      final updatedItems = grn.itemDetails
          ?.asMap()
          .entries
          .where((entry) => selectedRowsNotifier.value[entry.key])
          .map((entry) {
            final index = entry.key;
            final item = entry.value;

            String itemId;
            if (item.itemId != null && item.itemId!.isNotEmpty) {
              itemId = item.itemId!;
            } else {
              itemId = 'temp_${item.itemName?.hashCode ?? index}';
            }

            return {
              'itemId': itemId,
              'nos': item.nos,
              'eachQuantity': item.eachQuantity,
              'returnReason': itemReasonsNotifier.value[index] ?? '',
              if (scenarioNotifier.value == 'quantity_wise')
                'returnedQuantity': item.returnedQuantity,
            };
          })
          .toList();
      itemsNotifier.value = updatedItems;
      print('Updated items: $updatedItems');
    }
  }

  void _updateItemQuantities(ItemDetail item) {
    double? originalEachQty =
        originalEachQuantities[item] ?? item.eachQuantity ?? 1;
    double? originalNos = item.nos ?? 1;

    if (item.returnedQuantity != null && item.returnedQuantity! > 0) {
      if (originalNos > 0) {
        item.eachQuantity = (item.returnedQuantity! / originalNos);
        item.nos = originalNos;
      } else if (originalEachQty > 0) {
        item.nos = (item.returnedQuantity! / originalEachQty);
        item.eachQuantity = originalEachQty;
      } else {
        item.nos = item.returnedQuantity!;
        item.eachQuantity = 1;
      }
    } else {
      item.nos = 0;
      item.eachQuantity = 0;
    }
    print(
      'Updated quantities for item ${item.itemName}: nos=${item.nos}, eachQuantity=${item.eachQuantity}',
    );
  }

  void _recalculateItemTotals(ItemDetail item) {
    item.discountAmount =
        ((item.receivedQuantity ?? 0) * (item.unitPrice ?? 0)) *
        (grn.discountPrice ?? 0) /
        100;
    double discountedPrice =
        ((item.receivedQuantity ?? 0) * (item.unitPrice ?? 0)) -
        (item.discountAmount ?? 0);
    item.taxAmount = discountedPrice * (item.purchasetaxName ?? 0) / 100;
    print(
      'Recalculated totals for item ${item.itemName}: discount=${item.discountAmount}, tax=${item.taxAmount}',
    );
  }

  void _recalculateGRNTotal() {
    grn.totalReceivedAmount =
        grn.itemDetails?.fold(
          0.0,
          (total, item) => total! + (item.finalPrice ?? 0),
        ) ??
        0.0;
    print('Recalculated GRN total: ${grn.totalReceivedAmount}');
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'No Date';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      print('Error formatting date $date: $e');
      return date ?? 'No Date';
    }
  }
}
