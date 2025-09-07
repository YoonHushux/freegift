import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/requisition.dart';
import '../models/requisition_report.dart';

class RequisitionReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'Requisition';

  // ดึงรายการเบิกของทั้งหมดแบบ Stream
  Stream<List<RequisitionReport>> getAllRequisitionReports() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<RequisitionReport> reports = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final requisition = Requisition.fromMap({
              'id': doc.id,
              ...data,
            });
            
            for (var item in requisition.items) {
              reports.add(RequisitionReport.fromRequisitionItem(
                requisition: requisition,
                item: item,
              ));
            }
          }
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return reports;
    });
  }

  // ดึงรายการเบิกของตามช่วงวันที่
  Stream<List<RequisitionReport>> getRequisitionReportsByDateRange(
    DateRange dateRange
  ) {
    return _firestore
        .collection(_collection)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.endDate))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<RequisitionReport> reports = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final requisition = Requisition.fromMap({
              'id': doc.id,
              ...data,
            });
            
            for (var item in requisition.items) {
              if (dateRange.contains(item.createdAt)) {
                reports.add(RequisitionReport.fromRequisitionItem(
                  requisition: requisition,
                  item: item,
                ));
              }
            }
          }
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return reports;
    });
  }

  // ดึงรายการเบิกของตามลูกค้า
  Stream<List<RequisitionReport>> getRequisitionReportsByCustomer(
    String customerId
  ) {
    return _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<RequisitionReport> reports = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final requisition = Requisition.fromMap({
              'id': doc.id,
              ...data,
            });
            
            for (var item in requisition.items) {
              reports.add(RequisitionReport.fromRequisitionItem(
                requisition: requisition,
                item: item,
              ));
            }
          }
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return reports;
    });
  }

  // ดึงรายการเบิกของตามสินค้า
  Stream<List<RequisitionReport>> getRequisitionReportsByItem(
    String itemName
  ) {
    return getAllRequisitionReports().map((reports) {
      return reports.where((report) => 
        report.itemName.toLowerCase().contains(itemName.toLowerCase())
      ).toList();
    });
  }

  // สร้างสรุปรายการเบิกของ
  Future<List<RequisitionSummary>> getRequisitionSummary({
    DateRange? dateRange,
  }) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (dateRange != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.startDate))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.endDate));
      }
      
      final snapshot = await query.get();
      Map<String, RequisitionSummary> summaryMap = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final requisition = Requisition.fromMap({
              'id': doc.id,
              ...data,
            });
            
            for (var item in requisition.items) {
              if (dateRange == null || dateRange.contains(item.createdAt)) {
                final itemName = item.itemName;
                
                if (summaryMap.containsKey(itemName)) {
                  final existing = summaryMap[itemName]!;
                  summaryMap[itemName] = RequisitionSummary(
                    itemName: itemName,
                    totalQuantity: existing.totalQuantity + item.quantity,
                    requestCount: existing.requestCount + 1,
                    lastRequestDate: item.createdAt.isAfter(existing.lastRequestDate ?? DateTime(1900))
                        ? item.createdAt
                        : existing.lastRequestDate,
                    customerIds: {...existing.customerIds, requisition.customerId}.toList(),
                  );
                } else {
                  summaryMap[itemName] = RequisitionSummary(
                    itemName: itemName,
                    totalQuantity: item.quantity,
                    requestCount: 1,
                    lastRequestDate: item.createdAt,
                    customerIds: [requisition.customerId],
                  );
                }
              }
            }
          }
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return summaryMap.values.toList()
        ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    } catch (e) {
      return [];
    }
  }

  // ดึงรายชื่อลูกค้าทั้งหมด
  Future<List<String>> getAllCustomerIds() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      Set<String> customerIds = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['customerId'] != null) {
            customerIds.add(data['customerId']);
          }
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return customerIds.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // ดึงรายชื่อสินค้าทั้งหมด
  Future<List<String>> getAllItemNames() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      Set<String> itemNames = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final requisition = Requisition.fromMap({
              'id': doc.id,
              ...data,
            });
            
            for (var item in requisition.items) {
              itemNames.add(item.itemName);
            }
          }
        } catch (e) {
          // Skip invalid documents
        }
      }
      
      return itemNames.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // จัดเรียงรายการ report
  List<RequisitionReport> sortReports(
    List<RequisitionReport> reports,
    SortBy sortBy,
    SortOrder sortOrder,
  ) {
    reports.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case SortBy.date:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortBy.customer:
          comparison = a.customerId.compareTo(b.customerId);
          break;
        case SortBy.item:
          comparison = a.itemName.compareTo(b.itemName);
          break;
        case SortBy.quantity:
          comparison = a.quantity.compareTo(b.quantity);
          break;
      }
      
      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
    return reports;
  }

  // กรองรายการ report
  List<RequisitionReport> filterReports(
    List<RequisitionReport> reports, {
    String? searchText,
    String? customerId,
    String? itemName,
    DateRange? dateRange,
  }) {
    return reports.where((report) {
      if (searchText != null && searchText.isNotEmpty) {
        final search = searchText.toLowerCase();
        if (!report.customerId.toLowerCase().contains(search) &&
            !report.customerName.toLowerCase().contains(search) &&
            !report.itemName.toLowerCase().contains(search)) {
          return false;
        }
      }
      
      if (customerId != null && customerId.isNotEmpty) {
        if (report.customerId != customerId) {
          return false;
        }
      }
      
      if (itemName != null && itemName.isNotEmpty) {
        if (!report.itemName.toLowerCase().contains(itemName.toLowerCase())) {
          return false;
        }
      }
      
      if (dateRange != null) {
        if (!dateRange.contains(report.createdAt)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
}
