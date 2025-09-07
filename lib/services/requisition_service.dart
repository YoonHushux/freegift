import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/requisition.dart';
import '../models/free_gift.dart';
import 'free_gift_service.dart';

class RequisitionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final FreeGiftService _freeGiftService = FreeGiftService();

  // Stream สำหรับฟังการเปลี่ยนแปลงของรายการสินค้า
  Stream<List<String>> getAvailableItemsStream() {
    return _firestore
        .collection('Free gift')
        .where('isActive', isEqualTo: true)
        .orderBy('itemName')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FreeGift.fromMap(doc.data()).itemName)
              .toList();
        });
  }

  // สร้าง Requisition ใหม่
  Future<void> createRequisition(Requisition requisition) async {
    try {
      await _firestore
          .collection('Requisition')
          .doc(requisition.customerId)
          .set(requisition.toMap());
    } catch (e) {
      throw Exception('Failed to create requisition: $e');
    }
  }

  // เพิ่มรายการใหม่ใน Requisition
  Future<void> addItemToRequisition(
    String customerId,
    String customerName,
    RequisitionItem item,
  ) async {
    try {
      // ตรวจสอบและลดจำนวนในคลังก่อน
      await _freeGiftService.reduceQuantity(item.itemName, item.quantity);
      
      final docRef = _firestore.collection('Requisition').doc(customerId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // มี Requisition อยู่แล้ว - เพิ่มรายการใหม่
        final existingData = docSnapshot.data()!;
        final existingRequisition = Requisition.fromMap(existingData);

        final updatedItems = [...existingRequisition.items, item];
        final updatedRequisition = existingRequisition.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );

        await docRef.update(updatedRequisition.toMap());
      } else {
        // ยังไม่มี Requisition - สร้างใหม่
        final newRequisition = Requisition(
          id: customerId,
          customerId: customerId,
          customerName: customerName,
          items: [item],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await docRef.set(newRequisition.toMap());
      }
    } catch (e) {
      throw Exception('Failed to add item to requisition: $e');
    }
  }

  // ดึงข้อมูล Requisition ทั้งหมด
  Stream<List<Requisition>> getAllRequisitions() {
    return _firestore
        .collection('Requisition')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Requisition.fromMap(doc.data()))
              .toList();
        });
  }

  // ดึงข้อมูล Requisition ของลูกค้าคนหนึ่ง
  Future<Requisition?> getRequisitionByCustomerId(String customerId) async {
    try {
      final docSnapshot = await _firestore
          .collection('Requisition')
          .doc(customerId)
          .get();

      if (docSnapshot.exists) {
        return Requisition.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get requisition: $e');
    }
  }

  // ถ่ายรูปจากกล้อง
  Future<XFile?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );
      return photo;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // เลือกรูปจาก Gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // อัปโหลดรูปภาพไปยัง Firebase Storage
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      // สร้าง unique ID สำหรับรูปภาพ
      final requisitionImageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // แปลง XFile เป็น File
      final file = File(imageFile.path);
      
      // ใช้ FreeGiftService เพื่ออัปโหลดรูปภาพ
      return await _freeGiftService.uploadImage(file, 'requisition_$requisitionImageId');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ลบรายการจาก Requisition
  Future<void> removeItemFromRequisition(
    String customerId,
    String itemId,
  ) async {
    try {
      final docRef = _firestore.collection('Requisition').doc(customerId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final existingData = docSnapshot.data()!;
        final existingRequisition = Requisition.fromMap(existingData);

        final updatedItems = existingRequisition.items
            .where((item) => item.id != itemId)
            .toList();

        final updatedRequisition = existingRequisition.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );

        await docRef.update(updatedRequisition.toMap());
      }
    } catch (e) {
      throw Exception('Failed to remove item from requisition: $e');
    }
  }

  // ลบ Requisition ทั้งหมดของลูกค้า
  Future<void> deleteRequisition(String customerId) async {
    try {
      await _firestore.collection('Requisition').doc(customerId).delete();
    } catch (e) {
      throw Exception('Failed to delete requisition: $e');
    }
  }
}
