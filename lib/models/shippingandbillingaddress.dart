class ShippingAddress {
  final String shippingId;
  final String address;

  ShippingAddress({
    required this.shippingId,
    required this.address,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      shippingId: json['shippingId'] ?? '', 
      address: json['address'] ?? '', 
    );
  }
}

class BillingAddress {
  final String businessId;
  final String address1;
  final String address2;
 

  BillingAddress({
    required this.businessId,
    required this.address1,
    required this.address2,
  });

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      businessId: json['businessId'] ?? '', 
     
      address1: json['address1']?? '',
      address2: json['address2'] ?? '',
  
    );
  }
}
