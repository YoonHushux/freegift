import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer model for storing customer information
class Customer {
  final String id;
  final String name;
  final DateTime? updatedAt;
  final String? importedFrom;

  Customer({
    required this.id,
    required this.name,
    this.updatedAt,
    this.importedFrom,
  });

  /// Create Customer from Firestore document
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      importedFrom: map['importedFrom']?.toString(),
    );
  }

  /// Convert Customer to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : FieldValue.serverTimestamp(),
      if (importedFrom != null) 'importedFrom': importedFrom,
    };
  }

  /// Create a copy of Customer with updated fields
  Customer copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    String? importedFrom,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      importedFrom: importedFrom ?? this.importedFrom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, updatedAt: $updatedAt, importedFrom: $importedFrom)';
  }
}
