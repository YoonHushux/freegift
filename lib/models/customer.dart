class Customer {
  final String customerId;
  final String customerName;
  final String? address;
  final String? phoneNumber;
  final String? email;

  Customer({
    required this.customerId,
    required this.customerName,
    this.address,
    this.phoneNumber,
    this.email,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      address: map['address']?.toString(),
      phoneNumber: map['phoneNumber']?.toString(),
      email: map['email']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  @override
  String toString() {
    return 'Customer(customerId: $customerId, customerName: $customerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.customerId == customerId;
  }

  @override
  int get hashCode => customerId.hashCode;
}
