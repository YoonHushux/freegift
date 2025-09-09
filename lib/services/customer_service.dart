import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';

/// Customer Service for managing customer data
class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'customers';

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(customerId).get();
      
      if (doc.exists && doc.data() != null) {
        return Customer.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting customer: $e');
      return null;
    }
  }

  /// Get customer name by ID (convenience method)
  Future<String> getCustomerName(String customerId) async {
    try {
      // First try to find by cleaned ID
      var customer = await getCustomerById(customerId);
      if (customer != null) {
        return customer.name;
      }
      
      // If not found, try to search by originalId
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('originalId', isEqualTo: customerId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        customer = Customer.fromMap(data);
        return customer.name;
      }
      
      return 'ลูกค้า #$customerId';
    } catch (e) {
      debugPrint('Error getting customer name: $e');
      return 'ลูกค้า #$customerId';
    }
  }

  /// Get all customers
  Stream<List<Customer>> getAllCustomers() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.data());
      }).toList();
    });
  }

  /// Search customers by name or ID
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      if (query.isEmpty) return [];

      final results = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return results.docs.map((doc) {
        return Customer.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error searching customers: $e');
      return [];
    }
  }

  /// Add or update customer
  Future<void> addOrUpdateCustomer(Customer customer) async {
    try {
      await _firestore.collection(_collection).doc(customer.id).set(
        customer.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error adding/updating customer: $e');
      rethrow;
    }
  }

  /// Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection(_collection).doc(customerId).delete();
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      rethrow;
    }
  }

  /// Check if customer exists
  Future<bool> customerExists(String customerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(customerId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking customer existence: $e');
      return false;
    }
  }

  /// Get customers count
  Future<int> getCustomersCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting customers count: $e');
      return 0;
    }
  }
}
