import 'package:purchaseorders2/notifier/po_notifier_calculation_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_controller_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_discount_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_dispose_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_freight_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_helper_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_item_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_state.dart';
import 'package:purchaseorders2/notifier/po_notifier_submit_mixin.dart';
import 'package:purchaseorders2/notifier/po_notifier_vendor_mixin.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';


class PurchaseOrderNotifier extends PurchaseOrderNotifierState
    with
        PONotifierHelperMixin,
        PONotifierCalculationMixin,
        PONotifierControllerMixin,
        PONotifierDiscountMixin,
        PONotifierVendorMixin,
        PONotifierItemMixin,
        PONotifierFreightMixin,
        PONotifierSubmitMixin,
        PONotifierDisposeMixin {
        
  PurchaseOrderNotifier(POProvider provider) {
    poProvider = provider;
    newPriceController.removeListener(updateVariance);
    newPriceController.addListener(updateVariance);
    overallDiscountController.text = '0';
    roundOffController.text = '0';
    countController.text = '1';

    isHoldOrder = false;
  }
}