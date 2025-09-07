import 'package:cloud_firestore/cloud_firestore.dart';

class FreeGift {
  final String id;
  final String itemName;
  final String description;
  final int quantity;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FreeGift({
    required this.id,
    required this.itemName,
    required this.description,
    required this.quantity,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'description': description,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FreeGift.fromMap(Map<String, dynamic> map) {
    return FreeGift(
      id: map['id'] ?? '',
      itemName: map['itemName'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? int.tryParse(map['description'] ?? '0') ?? 0, // Backward compatibility
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  FreeGift copyWith({
    String? id,
    String? itemName,
    String? description,
    int? quantity,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FreeGift(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
