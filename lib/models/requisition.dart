import 'package:cloud_firestore/cloud_firestore.dart';

class RequisitionItem {
  final String id;
  final String itemName;
  final int quantity;
  final String? imageUrl;
  final DateTime createdAt;

  RequisitionItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RequisitionItem.fromMap(Map<String, dynamic> map) {
    return RequisitionItem(
      id: map['id'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class Requisition {
  final String id;
  final String customerId;
  final String customerName;
  final List<RequisitionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Requisition({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Requisition.fromMap(Map<String, dynamic> map) {
    return Requisition(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      items: List<RequisitionItem>.from(
        map['items']?.map((item) => RequisitionItem.fromMap(item)) ?? [],
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Requisition copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<RequisitionItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Requisition(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
