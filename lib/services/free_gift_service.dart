import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/free_gift.dart';

class FreeGiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final String _collection = 'Free gift';

  // เพิ่มรายการ Free Gift ใหม่หรือเพิ่มจำนวนถ้ามีอยู่แล้ว
  Future<void> addOrUpdateFreeGift(FreeGift freeGift) async {
    try {
      // ตรวจสอบว่ามีรายการชื่อเดียวกันอยู่แล้วหรือไม่
      final existingItems = await _firestore
          .collection(_collection)
          .where('itemName', isEqualTo: freeGift.itemName)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingItems.docs.isNotEmpty) {
        // ถ้ามีอยู่แล้ว ให้เพิ่มจำนวน
        final existingItem = FreeGift.fromMap(existingItems.docs.first.data());
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + freeGift.quantity,
          updatedAt: DateTime.now(),
        );
        
        await _firestore
            .collection(_collection)
            .doc(existingItem.id)
            .update(updatedItem.toMap());
      } else {
        // ถ้าไม่มี ให้เพิ่มใหม่
        await _firestore
            .collection(_collection)
            .doc(freeGift.id)
            .set(freeGift.toMap());
      }
    } catch (e) {
      throw Exception('Failed to add or update free gift: $e');
    }
  }

  // ลดจำนวนเมื่อมีการเบิก
  Future<bool> reduceQuantity(String itemName, int quantity) async {
    try {
      final items = await _firestore
          .collection(_collection)
          .where('itemName', isEqualTo: itemName)
          .where('isActive', isEqualTo: true)
          .get();

      if (items.docs.isEmpty) {
        throw Exception('ไม่พบรายการที่ต้องการเบิก');
      }

      final item = FreeGift.fromMap(items.docs.first.data());
      
      if (item.quantity < quantity) {
        throw Exception('จำนวนคงเหลือไม่เพียงพอ (คงเหลือ: ${item.quantity})');
      }

      final updatedQuantity = item.quantity - quantity;
      final updatedItem = item.copyWith(
        quantity: updatedQuantity,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(updatedItem.toMap());

      return true;
    } catch (e) {
      throw Exception('Failed to reduce quantity: $e');
    }
  }

  // เพิ่มรายการ Free Gift ใหม่
  Future<void> addFreeGift(FreeGift freeGift) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(freeGift.id)
          .set(freeGift.toMap());
    } catch (e) {
      throw Exception('Failed to add free gift: $e');
    }
  }

  // อัพเดท Free Gift
  Future<void> updateFreeGift(FreeGift freeGift) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(freeGift.id)
          .update(freeGift.toMap());
    } catch (e) {
      throw Exception('Failed to update free gift: $e');
    }
  }

  // ลบ Free Gift (soft delete)
  Future<void> deleteFreeGift(String id) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to delete free gift: $e');
    }
  }

  // ดึงรายการ Free Gift ทั้งหมด (เฉพาะที่ active) - ใช้ simple query เพื่อหลีกเลี่ยง Index 
  Stream<List<FreeGift>> getAllActiveFreeGifts() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final gifts = snapshot.docs
          .map((doc) => FreeGift.fromMap(doc.data()))
          .toList();
      
      // เรียงข้อมูลใน memory แทนการใช้ orderBy ใน Firebase
      gifts.sort((a, b) => a.itemName.compareTo(b.itemName));
      return gifts;
    });
  }

  // ดึงรายการ Free Gift ทั้งหมด (รวมที่ไม่ active) - ไม่ใช้ orderBy
  Stream<List<FreeGift>> getAllFreeGifts() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      final gifts = snapshot.docs
          .map((doc) => FreeGift.fromMap(doc.data()))
          .toList();
      
      // เรียงข้อมูลใน memory
      gifts.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // ใหม่ไปเก่า
      return gifts;
    });
  }

  // ดึง Free Gift ตาม ID
  Future<FreeGift?> getFreeGiftById(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        return FreeGift.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get free gift: $e');
    }
  }

  // อัพโหลดรูปภาพ
  Future<String?> uploadImage(File imageFile, String freeGiftId) async {
    try {
      final ref = _storage.ref().child('free_gifts').child('$freeGiftId.jpg');
      
      final uploadTask = ref.putFile(imageFile);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        // Upload progress tracking could be implemented here if needed
      });
      
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ทดสอบการเชื่อมต่อ Firebase Storage
  Future<bool> testStorageConnection() async {
    try {
      final ref = _storage.ref().child('test').child('connection_test.txt');
      
      // สร้างไฟล์ทดสอบ
      final testData = 'Connection test at ${DateTime.now().toIso8601String()}';
      await ref.putString(testData);
      
      // อ่านไฟล์กลับมาเพื่อทดสอบ
      await ref.getDownloadURL();
      
      // ลบไฟล์ทดสอบ
      await ref.delete();
      
      return true;
    } catch (e) {
      // Storage connection test failed
      return false;
    }
  }

  // ถ่ายรูป
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // เลือกรูปภาพจากแกลเลอรี่
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // สร้าง ID ใหม่
  String generateId() {
    return _firestore.collection(_collection).doc().id;
  }

  // ค้นหา Free Gift ตามชื่อ
  Future<List<FreeGift>> searchFreeGiftsByName(String searchText) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final results = querySnapshot.docs
          .map((doc) => FreeGift.fromMap(doc.data()))
          .where((gift) => gift.itemName.toLowerCase().contains(searchText.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      throw Exception('Failed to search free gifts: $e');
    }
  }
}
