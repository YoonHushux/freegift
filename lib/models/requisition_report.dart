import 'package:cloud_firestore/cloud_firestore.dart';
import 'requisition.dart';

class RequisitionReport {
  final String id;
  final String customerId;
  final String customerName;
  final String itemName;
  final int quantity;
  final String? imageUrl;
  final DateTime createdAt;
  final String requisitionId;
  final String itemId;

  RequisitionReport({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.itemName,
    required this.quantity,
    this.imageUrl,
    required this.createdAt,
    required this.requisitionId,
    required this.itemId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'itemName': itemName,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'requisitionId': requisitionId,
      'itemId': itemId,
    };
  }

  factory RequisitionReport.fromMap(Map<String, dynamic> map) {
    return RequisitionReport(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      requisitionId: map['requisitionId'] ?? '',
      itemId: map['itemId'] ?? '',
    );
  }

  factory RequisitionReport.fromRequisitionItem({
    required Requisition requisition,
    required RequisitionItem item,
  }) {
    return RequisitionReport(
      id: '${requisition.id}_${item.id}',
      customerId: requisition.customerId,
      customerName: requisition.customerName,
      itemName: item.itemName,
      quantity: item.quantity,
      imageUrl: item.imageUrl,
      createdAt: item.createdAt,
      requisitionId: requisition.id,
      itemId: item.id,
    );
  }
}

class RequisitionSummary {
  final String itemName;
  final int totalQuantity;
  final int requestCount;
  final DateTime? lastRequestDate;
  final List<String> customerIds;

  RequisitionSummary({
    required this.itemName,
    required this.totalQuantity,
    required this.requestCount,
    this.lastRequestDate,
    required this.customerIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'totalQuantity': totalQuantity,
      'requestCount': requestCount,
      'lastRequestDate': lastRequestDate != null 
          ? Timestamp.fromDate(lastRequestDate!) 
          : null,
      'customerIds': customerIds,
    };
  }

  factory RequisitionSummary.fromMap(Map<String, dynamic> map) {
    return RequisitionSummary(
      itemName: map['itemName'] ?? '',
      totalQuantity: map['totalQuantity'] ?? 0,
      requestCount: map['requestCount'] ?? 0,
      lastRequestDate: map['lastRequestDate'] != null 
          ? (map['lastRequestDate'] as Timestamp).toDate() 
          : null,
      customerIds: List<String>.from(map['customerIds'] ?? []),
    );
  }
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  bool contains(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }
}

enum ReportType {
  daily,
  weekly,
  monthly,
  custom,
}

enum SortBy {
  date,
  customer,
  item,
  quantity,
}

enum SortOrder {
  ascending,
  descending,
}
