import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import '../models/customer.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Enhanced Smart Cache สำหรับเก็บข้อมูลลูกค้า + File Version Tracking
  static Map<String, Customer>? _customerMap;
  static Map<String, String>? _customerNamesMap; // เก็บเฉพาะชื่อ (รวดเร็วกว่า)
  static Set<String>? _availableCustomerIds; // เก็บรายการ ID ที่มี (ultra light)
  static String? _lastFileVersion; // Track version ของไฟล์ Excel
  static String? _currentFileVersion; // Version ปัจจุบันของไฟล์
  static DateTime? _lastLoadTime;
  static DateTime? _lastNamesLoadTime;
  static DateTime? _lastIdsLoadTime;
  static DateTime? _lastVersionCheck;
  static const Duration _cacheValidDuration = Duration(hours: 6);
  static const Duration _namesCacheValidDuration = Duration(hours: 12); // ชื่อเก็บนานกว่า
  static const Duration _idsCacheValidDuration = Duration(hours: 24); // ID เก็บนานที่สุด
  static const Duration _versionCheckInterval = Duration(minutes: 5); // เช็ค version ทุก 5 นาที
  static bool _isLoading = false;
  static bool _isLoadingNames = false;
  static bool _isLoadingIds = false;
  static bool _isCheckingVersion = false;

  /// ตรวจสอบ version ของไฟล์ Excel (ใช้ metadata) 🔍
  Future<String> _getFileVersion() async {
    try {
      final ref = _storage.ref().child('Customer.xlsx');
      final metadata = await ref.getMetadata();
      
      // ใช้ combination ของ updated time + size เป็น version identifier
      final updated = metadata.updated?.millisecondsSinceEpoch ?? 0;
      final size = metadata.size ?? 0;
      final version = '$updated-$size';
      
      print('📊 Current file version: $version');
      return version;
    } catch (e) {
      print('⚠️ Failed to get file version: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// ตรวจสอบว่าไฟล์มีการอัพเดทหรือไม่ 🔄
  Future<bool> _checkFileUpdated() async {
    // ถ้าไม่เคยเช็คมาก่อน หรือเช็คนานแล้ว
    if (_lastVersionCheck == null || 
        DateTime.now().difference(_lastVersionCheck!) > _versionCheckInterval) {
      
      if (_isCheckingVersion) {
        print('⏳ Already checking file version...');
        return false;
      }
      
      _isCheckingVersion = true;
      
      try {
        print('🔍 Checking if Excel file has been updated...');
        _currentFileVersion = await _getFileVersion();
        _lastVersionCheck = DateTime.now();
        
        // ถ้าไม่เคยมี version เก่า หรือ version เปลี่ยน
        if (_lastFileVersion == null || _lastFileVersion != _currentFileVersion) {
          print('🆕 File has been updated! Old: $_lastFileVersion, New: $_currentFileVersion');
          _lastFileVersion = _currentFileVersion;
          return true;
        } else {
          print('✅ File version unchanged: $_currentFileVersion');
          return false;
        }
      } finally {
        _isCheckingVersion = false;
      }
    }
    
    return false; // ไม่ต้องเช็ค version บ่อยเกินไป
  }

  /// ล้าง cache ภายในทั้งหมด (ไม่รวม remote cache)
  void _clearAllCaches() {
    _customerMap = null;
    _customerNamesMap = null;
    _availableCustomerIds = null;
    _lastLoadTime = null;
    _lastNamesLoadTime = null;
    _lastIdsLoadTime = null;
    print('🧹 Internal caches cleared due to file update');
  }

  /// โหลดข้อมูลเฉพาะเมื่อจำเป็น (Single Load + Smart Update) 🧠
  /// โหลดข้อมูลเฉพาะเมื่อจำเป็น (Single Load + Smart Update) 🧠
  Future<void> _loadCustomerIdsIfNeeded() async {
    // ตรวจสอบว่าไฟล์มีการอัพเดทหรือไม่
    final fileUpdated = await _checkFileUpdated();
    
    // ถ้าไฟล์อัพเดท ให้ล้าง cache ทั้งหมด
    if (fileUpdated) {
      print('🔄 File updated - clearing all caches...');
      _clearAllCaches();
    }
    
    // ตรวจสอบ IDs cache
    if (_availableCustomerIds != null && 
        _lastIdsLoadTime != null && 
        DateTime.now().difference(_lastIdsLoadTime!) < _idsCacheValidDuration && 
        !fileUpdated) {
      print('🔑 Using cached customer IDs: ${_availableCustomerIds!.length} IDs');
      return;
    }

    // ป้องกันการโหลดซ้อน
    if (_isLoadingIds) {
      print('⏳ Already loading customer IDs, waiting...');
      while (_isLoadingIds) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isLoadingIds = true;
    print('🔄 Loading customer IDs (single load strategy)...');
    
    try {
      // ลองใช้ JSON cache ก่อน (ถ้าไฟล์ไม่ได้อัพเดท)
      if (!fileUpdated && await _loadIdsFromJsonCache()) {
        _lastIdsLoadTime = DateTime.now();
        print('⚡ Loaded ${_availableCustomerIds!.length} customer IDs from JSON cache');
        return;
      }

      // โหลดจาก Excel และสร้าง cache ใหม่
      await _loadIdsFromExcel();
      
      // บันทึกเป็น JSON cache สำหรับครั้งต่อไป
      await _saveIdsToJsonCache();
      
      _lastIdsLoadTime = DateTime.now();
      print('✅ Single load completed: ${_availableCustomerIds!.length} customer IDs');
      
    } catch (e) {
      print('❌ Error in single load IDs: $e');
      _availableCustomerIds = <String>{};
    } finally {
      _isLoadingIds = false;
    }
  }

  /// โหลด IDs จาก JSON Cache (ultra fast)
  Future<bool> _loadIdsFromJsonCache() async {
    try {
      final ref = _storage.ref().child('cache/customer_ids.json');
      final downloadUrl = await ref.getDownloadURL();
      
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        _availableCustomerIds = Set<String>.from(jsonData);
        print('📦 IDs JSON cache loaded: ${_availableCustomerIds!.length} IDs');
        return true;
      }
    } catch (e) {
      print('⚠️ IDs JSON cache not found: $e');
    }
    return false;
  }

  /// บันทึก IDs เป็น JSON Cache
  Future<void> _saveIdsToJsonCache() async {
    if (_availableCustomerIds == null || _availableCustomerIds!.isEmpty) return;
    
    try {
      final jsonData = json.encode(_availableCustomerIds!.toList());
      final bytes = utf8.encode(jsonData);
      
      final ref = _storage.ref().child('cache/customer_ids.json');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/json'),
      );
      
      print('💾 Customer IDs saved to JSON cache');
    } catch (e) {
      print('⚠️ Failed to save IDs JSON cache: $e');
    }
  }

  /// โหลด IDs จาก Excel แบบ ultra selective (เฉพาะคอลัมน์แรก)
  Future<void> _loadIdsFromExcel() async {
    final ref = _storage.ref().child('Customer.xlsx');
    final downloadUrl = await ref.getDownloadURL();
    
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download Excel file: ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final excel = Excel.decodeBytes(bytes);
    
    _availableCustomerIds = <String>{};
    
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) {
      throw Exception('No sheet found in Excel file');
    }

    // อ่านเฉพาะคอลัมน์แรก (ID only) เพื่อประสิทธิภาพสูงสุด
    for (int rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      
      if (row.isNotEmpty && row[0]?.value != null) {
        final customerId = row[0]?.value?.toString().trim() ?? '';
        
        if (customerId.isNotEmpty) {
          _availableCustomerIds!.add(customerId);
        }
      }
    }
  }

  /// โหลดเฉพาะ Customer Names สำหรับ UI (Single Load + Smart Update) ⚡
  Future<void> _loadCustomerNamesIfNeeded() async {
    // ตรวจสอบว่าไฟล์มีการอัพเดทหรือไม่
    final fileUpdated = await _checkFileUpdated();
    
    // ถ้าไฟล์อัพเดท ให้ล้าง cache ทั้งหมด
    if (fileUpdated) {
      print('🔄 File updated - clearing names cache...');
      _clearAllCaches();
    }
    
    // ตรวจสอบ names cache
    if (_customerNamesMap != null && 
        _lastNamesLoadTime != null && 
        DateTime.now().difference(_lastNamesLoadTime!) < _namesCacheValidDuration && 
        !fileUpdated) {
      print('🏷️ Using cached customer names: ${_customerNamesMap!.length} names');
      return;
    }

    // ป้องกันการโหลดซ้อน
    if (_isLoadingNames) {
      print('⏳ Already loading customer names, waiting...');
      while (_isLoadingNames) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isLoadingNames = true;
    print('🔄 Single load: customer names from Firebase Storage...');
    
    try {
      // ลองใช้ JSON cache ก่อน (ถ้ามี)
      if (await _loadNamesFromJsonCache()) {
        _lastNamesLoadTime = DateTime.now();
        print('⚡ Loaded ${_customerNamesMap!.length} customer names from JSON cache');
        return;
      }

      // ถ้าไม่มี JSON cache ให้โหลดจาก Excel แบบ selective
      await _loadNamesFromExcel();
      
      // บันทึกเป็น JSON cache สำหรับครั้งต่อไป
      await _saveNamesToJsonCache();
      
      _lastNamesLoadTime = DateTime.now();
      print('✅ Loaded ${_customerNamesMap!.length} customer names from Excel and cached');
      
    } catch (e) {
      print('❌ Error loading customer names: $e');
      _customerNamesMap = <String, String>{};
    } finally {
      _isLoadingNames = false;
    }
  }

  /// โหลด Names จาก JSON Cache (รวดเร็ว)
  Future<bool> _loadNamesFromJsonCache() async {
    try {
      final ref = _storage.ref().child('cache/customer_names.json');
      final downloadUrl = await ref.getDownloadURL();
      
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        _customerNamesMap = Map<String, String>.from(jsonData);
        print('📦 JSON cache loaded: ${_customerNamesMap!.length} names');
        return true;
      }
    } catch (e) {
      print('⚠️ JSON cache not found or invalid: $e');
    }
    return false;
  }

  /// บันทึก Names เป็น JSON Cache
  Future<void> _saveNamesToJsonCache() async {
    if (_customerNamesMap == null || _customerNamesMap!.isEmpty) return;
    
    try {
      final jsonData = json.encode(_customerNamesMap);
      final bytes = utf8.encode(jsonData);
      
      final ref = _storage.ref().child('cache/customer_names.json');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/json'),
      );
      
      print('💾 Customer names saved to JSON cache');
    } catch (e) {
      print('⚠️ Failed to save JSON cache: $e');
    }
  }

  /// โหลด Names จาก Excel แบบเฉพาะคอลัมน์ที่จำเป็น
  Future<void> _loadNamesFromExcel() async {
    final ref = _storage.ref().child('Customer.xlsx');
    final downloadUrl = await ref.getDownloadURL();
    
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download Excel file: ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final excel = Excel.decodeBytes(bytes);
    
    _customerNamesMap = <String, String>{};
    
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) {
      throw Exception('No sheet found in Excel file');
    }

    // อ่านเฉพาะ 2 คอลัมน์แรก (ID + Name) เพื่อประสิทธิภาพ
    for (int rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      
      if (row.isNotEmpty && row[0]?.value != null) {
        final customerId = row[0]?.value?.toString().trim() ?? '';
        final customerName = row.length > 1 ? (row[1]?.value?.toString().trim() ?? '') : '';
        
        if (customerId.isNotEmpty && customerName.isNotEmpty) {
          _customerNamesMap![customerId] = customerName;
        }
      }
    }
  }

  /// โหลดข้อมูลลูกค้าจาก Excel และเก็บใน Map (Single Load + Smart Update)
  Future<void> _loadCustomerMapIfNeeded() async {
    // ตรวจสอบว่าไฟล์มีการอัพเดทหรือไม่
    final fileUpdated = await _checkFileUpdated();
    
    // ถ้าไฟล์อัพเดท ให้ล้าง cache ทั้งหมด
    if (fileUpdated) {
      print('🔄 File updated - clearing full data cache...');
      _clearAllCaches();
    }
    
    // ตรวจสอบ cache
    if (_customerMap != null && 
        _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration && 
        !fileUpdated) {
      print('📦 Using cached customer map: ${_customerMap!.length} customers');
      return;
    }

    // ป้องกันการโหลดซ้อน
    if (_isLoading) {
      print('⏳ Already loading customer data, waiting...');
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isLoading = true;
    print('🔄 Loading customer data from Firebase Storage...');
    
    try {
      // ดาวน์โหลดไฟล์ Excel จาก Firebase Storage
      final ref = _storage.ref().child('Customer.xlsx');
      final downloadUrl = await ref.getDownloadURL();
      print('📥 Download URL obtained');
      
      // ดาวน์โหลดไฟล์
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download Excel file: ${response.statusCode}');
      }
      print('✅ Excel file downloaded successfully, size: ${response.bodyBytes.length} bytes');

      // อ่านไฟล์ Excel และแปลงเป็น Map
      final bytes = response.bodyBytes;
      final excel = Excel.decodeBytes(bytes);
      print('📊 Excel file decoded, sheets: ${excel.tables.keys.toList()}');
      
      _customerMap = <String, Customer>{};
      
      // อ่านข้อมูลจาก sheet แรก
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('No sheet found in Excel file');
      }
      
      print('📖 Reading from sheet: ${excel.tables.keys.first}, rows: ${sheet.maxRows}');

      // อ่านข้อมูลจากทุก row และสร้าง Map
      for (int rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        
        // ตรวจสอบว่ามีข้อมูลใน cell แรก (Customer ID)
        if (row.isNotEmpty && row[0]?.value != null) {
          final customerId = row[0]?.value?.toString().trim() ?? '';
          final customerName = row.length > 1 ? (row[1]?.value?.toString().trim() ?? '') : '';
          final address = row.length > 2 ? row[2]?.value?.toString().trim() : null;
          final phoneNumber = row.length > 3 ? row[3]?.value?.toString().trim() : null;
          final email = row.length > 4 ? row[4]?.value?.toString().trim() : null;
          
          if (customerId.isNotEmpty && customerName.isNotEmpty) {
            _customerMap![customerId] = Customer(
              customerId: customerId,
              customerName: customerName,
              address: address,
              phoneNumber: phoneNumber,
              email: email,
            );
          }
        }
      }

      // อัพเดต cache timestamp
      _lastLoadTime = DateTime.now();
      
      print('✅ Loaded ${_customerMap!.length} customers into memory map');
      
    } catch (e) {
      print('❌ Error loading customers from Excel: $e');
      _customerMap = <String, Customer>{};
    } finally {
      _isLoading = false;
    }
  }

  /// เริ่มต้นระบบ - โหลดครั้งเดียวตอน app start 🚀
  static Future<void> initialize() async {
    print('🚀 Initializing CustomerService with single load strategy...');
    final instance = CustomerService();
    
    try {
      // โหลดข้อมูลพื้นฐานครั้งเดียว
      await instance._loadCustomerNamesIfNeeded();
      print('✅ CustomerService initialized successfully');
    } catch (e) {
      print('❌ CustomerService initialization failed: $e');
    }
  }

  /// ตรวจสอบและรีเฟรช cache เมื่อจำเป็น 🔄
  Future<bool> refreshIfNeeded() async {
    print('🔍 Checking if refresh is needed...');
    
    final fileUpdated = await _checkFileUpdated();
    if (fileUpdated) {
      print('🔄 File updated - performing smart refresh...');
      _clearAllCaches();
      
      // โหลดข้อมูลใหม่แบบ progressive
      await _loadCustomerNamesIfNeeded();
      print('✅ Smart refresh completed');
      return true;
    }
    
    print('✅ No refresh needed - data is up to date');
    return false;
  }

  /// ตรวจสอบว่า Customer ID มีอยู่หรือไม่ (ultra fast validation) ⚡⚡⚡
  Future<bool> isCustomerIdExists(String customerId) async {
    if (customerId.trim().isEmpty) return false;
    
    // Level 1: ตรวจสอบจาก IDs cache ก่อน (ultra light)
    await _loadCustomerIdsIfNeeded();
    if (_availableCustomerIds?.contains(customerId) == true) {
      print('⚡ Customer ID $customerId validated from IDs cache');
      return true;
    }
    
    // Level 2: ตรวจสอบจาก Names cache (light)
    if (_customerNamesMap?.containsKey(customerId) == true) {
      print('⚡ Customer ID $customerId validated from names cache');
      return true;
    }
    
    // Level 3: ตรวจสอบจาก Full cache (heavy)
    if (_customerMap?.containsKey(customerId) == true) {
      print('⚡ Customer ID $customerId validated from full cache');
      return true;
    }
    
    print('❌ Customer ID $customerId not found');
    return false;
  }

  /// ดึงรายการ Customer IDs ที่มีทั้งหมด (สำหรับ autocomplete)
  Future<Set<String>> getAvailableCustomerIds() async {
    await _loadCustomerIdsIfNeeded();
    return _availableCustomerIds ?? <String>{};
  }

  /// ดึงข้อมูลลูกค้าเฉพาะรายที่ต้องการ (O(1) lookup)
  Future<Customer?> getCustomerById(String customerId) async {
    await _loadCustomerMapIfNeeded();
    
    final customer = _customerMap?[customerId];
    if (customer != null) {
      print('👤 Found customer: ${customer.customerName} (${customer.customerId})');
    } else {
      print('❌ Customer $customerId not found in map');
    }
    
    return customer;
  }

  /// ดึงข้อมูลลูกค้าหลายรายพร้อมกัน (สำหรับ Reports)
  Future<Map<String, Customer>> getCustomersByIds(List<String> customerIds) async {
    await _loadCustomerMapIfNeeded();
    
    final result = <String, Customer>{};
    final foundIds = <String>[];
    final notFoundIds = <String>[];
    
    for (final id in customerIds) {
      final customer = _customerMap?[id];
      if (customer != null) {
        result[id] = customer;
        foundIds.add(id);
      } else {
        notFoundIds.add(id);
      }
    }
    
    print('✅ Found ${foundIds.length} customers: ${foundIds.take(5).join(", ")}${foundIds.length > 5 ? "..." : ""}');
    if (notFoundIds.isNotEmpty) {
      print('❌ Not found ${notFoundIds.length} customers: ${notFoundIds.take(3).join(", ")}${notFoundIds.length > 3 ? "..." : ""}');
    }
    
    return result;
  }

  /// ดึงชื่อลูกค้าเฉพาะที่ต้องการ (สำหรับ UI) ⚡ PROGRESSIVE ENHANCED
  Future<Map<String, String>> getCustomerNamesByIds(List<String> customerIds) async {
    if (customerIds.isEmpty) return {};
    
    print('🔄 Loading customer names for ${customerIds.length} unique customers...');
    
    final result = <String, String>{};
    final remainingIds = <String>[];
    
    // Level 1: ตรวจสอบ Names Cache ก่อน (fastest)
    await _loadCustomerNamesIfNeeded();
    
    for (final id in customerIds) {
      final name = _customerNamesMap?[id];
      if (name != null) {
        result[id] = name;
      } else {
        remainingIds.add(id);
      }
    }
    
    print('⚡ Level 1: Found ${result.length}/${customerIds.length} from names cache');
    
    // Level 2: หากยังขาดบางรายการ ให้ดึงจาก Full Cache
    if (remainingIds.isNotEmpty) {
      await _loadCustomerMapIfNeeded();
      
      final stillMissingIds = <String>[];
      
      for (final id in remainingIds) {
        final customer = _customerMap?[id];
        if (customer != null) {
          result[id] = customer.customerName;
        } else {
          stillMissingIds.add(id);
        }
      }
      
      print('⚡ Level 2: Found ${remainingIds.length - stillMissingIds.length}/${remainingIds.length} from full cache');
      
      // Level 3: หากยังขาดอยู่ ให้ใช้ Customer ID เป็น fallback
      for (final id in stillMissingIds) {
        result[id] = id; // แสดง ID เป็นชื่อ
      }
      
      if (stillMissingIds.isNotEmpty) {
        print('⚠️ Level 3: ${stillMissingIds.length} customers using ID as fallback');
      }
    }
    
    print('✅ Progressive lookup completed: ${result.length} customer names');
    return result;
  }

  /// ค้นหาลูกค้าด้วยชื่อ (Progressive Search) 🔍
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    
    // Level 1: ค้นหาใน Names Cache ก่อน (รวดเร็ว)
    await _loadCustomerNamesIfNeeded();
    final matchingIds = <String>[];
    
    _customerNamesMap?.forEach((id, name) {
      if (name.toLowerCase().contains(queryLower) || 
          id.toLowerCase().contains(queryLower)) {
        matchingIds.add(id);
      }
    });
    
    if (matchingIds.isEmpty) {
      print('🔍 No matches found in names cache for "$query"');
      return [];
    }
    
    print('🔍 Found ${matchingIds.length} potential matches in names cache');
    
    // Level 2: โหลดข้อมูลเต็มเฉพาะรายที่พบ
    final customers = await getCustomersByIds(matchingIds);
    final results = customers.values.toList();
    
    print('🔍 Progressive search "$query" found ${results.length} customers');
    return results;
  }

  /// ค้นหาลูกค้าแบบ Auto-complete (ultra fast)
  Future<List<String>> searchCustomerNames(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];
    
    await _loadCustomerNamesIfNeeded();
    
    final queryLower = query.toLowerCase();
    final results = <String>[];
    
    _customerNamesMap?.forEach((id, name) {
      if (results.length >= limit) return;
      
      if (name.toLowerCase().contains(queryLower) || 
          id.toLowerCase().contains(queryLower)) {
        results.add('$name ($id)');
      }
    });
    
    print('🔍 Auto-complete for "$query" found ${results.length} suggestions');
    return results;
  }

  /// ดึงลูกค้าทั้งหมด (สำหรับ Dropdown) - ใช้เฉพาะเมื่อจำเป็น
  Future<Map<String, Customer>> getAllCustomers() async {
    await _loadCustomerMapIfNeeded();
    return _customerMap ?? {};
  }

  /// ตรวจสอบว่ามีข้อมูลลูกค้าหรือไม่
  Future<bool> hasCustomerData() async {
    await _loadCustomerMapIfNeeded();
    return _customerMap?.isNotEmpty == true;
  }

  /// ล้าง cache ทั้งหมด + รีเซ็ต version tracking
  void clearCache() {
    _customerMap = null;
    _customerNamesMap = null;
    _availableCustomerIds = null;
    _lastLoadTime = null;
    _lastNamesLoadTime = null;
    _lastIdsLoadTime = null;
    _lastFileVersion = null;
    _currentFileVersion = null;
    _lastVersionCheck = null;
    print('🗑️ All customer caches + version tracking cleared');
  }

  /// ล้างเฉพาะ JSON cache ใน Firebase (ทั้ง 3 ระดับ)
  Future<void> clearRemoteCache() async {
    final List<Future<void>> deleteTasks = [];
    
    // ลบ names cache
    deleteTasks.add(_deleteRemoteFile('cache/customer_names.json', 'names'));
    
    // ลบ IDs cache
    deleteTasks.add(_deleteRemoteFile('cache/customer_ids.json', 'IDs'));
    
    await Future.wait(deleteTasks);
    print('🗑️ All remote JSON caches cleared');
  }

  /// Helper function สำหรับลบไฟล์ remote
  Future<void> _deleteRemoteFile(String path, String type) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      print('🗑️ Remote $type cache deleted');
    } catch (e) {
      print('⚠️ Failed to delete remote $type cache: $e');
    }
  }

  /// ตรวจสอบว่าไฟล์ Excel มีอยู่ใน Firebase Storage หรือไม่
  Future<bool> checkExcelFileExists() async {
    try {
      final ref = _storage.ref().child('Customer.xlsx');
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      print('📄 Excel file not found: $e');
      return false;
    }
  }

  /// อัพโหลดไฟล์ Excel ไปยัง Firebase Storage และสร้าง cache ใหม่ (สำหรับ admin)
  Future<bool> uploadExcelFile(Uint8List fileBytes) async {
    try {
      final ref = _storage.ref().child('Customer.xlsx');
      await ref.putData(
        fileBytes,
        SettableMetadata(
          contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
      
      // ล้าง cache ทั้งหมด
      clearCache();
      await clearRemoteCache();
      
      // สร้าง cache ใหม่ทันทีแบบ Progressive (เพื่อประสิทธิภาพสูงสุด)
      print('🔄 Building progressive cache after upload...');
      await _loadCustomerIdsIfNeeded();    // Level 1: IDs (ultra light)
      await _loadCustomerNamesIfNeeded();  // Level 2: Names (light)
      // Level 3: Full data จะโหลดเมื่อจำเป็นเท่านั้น
      
      print('📤 Excel file uploaded and 3-level progressive cache built');
      return true;
    } catch (e) {
      print('❌ Error uploading Excel file: $e');
      return false;
    }
  }

  /// ดึงสถิติการใช้งาน Single Load + Smart Update System
  Map<String, dynamic> getCacheStats() {
    return {
      // File Version Tracking
      'fileVersion': _currentFileVersion ?? 'Unknown',
      'lastVersionCheck': _lastVersionCheck?.toIso8601String(),
      'versionCheckAge': _lastVersionCheck != null 
          ? DateTime.now().difference(_lastVersionCheck!).inMinutes 
          : null,
      
      // Level 1: IDs Cache (Ultra Light)
      'hasIdsCache': _availableCustomerIds != null,
      'idsCount': _availableCustomerIds?.length ?? 0,
      'lastIdsLoad': _lastIdsLoadTime?.toIso8601String(),
      'idsCacheAge': _lastIdsLoadTime != null 
          ? DateTime.now().difference(_lastIdsLoadTime!).inMinutes 
          : null,
      'idsCacheExpired': _lastIdsLoadTime != null 
          ? DateTime.now().difference(_lastIdsLoadTime!) > _idsCacheValidDuration
          : true,
      
      // Level 2: Names Cache (Light)
      'hasNamesCache': _customerNamesMap != null,
      'namesCount': _customerNamesMap?.length ?? 0,
      'lastNamesLoad': _lastNamesLoadTime?.toIso8601String(),
      'namesCacheAge': _lastNamesLoadTime != null 
          ? DateTime.now().difference(_lastNamesLoadTime!).inMinutes 
          : null,
      'namesCacheExpired': _lastNamesLoadTime != null 
          ? DateTime.now().difference(_lastNamesLoadTime!) > _namesCacheValidDuration
          : true,
      
      // Level 3: Full Cache (Heavy)
      'hasFullCache': _customerMap != null,
      'fullDataCount': _customerMap?.length ?? 0,
      'lastFullLoad': _lastLoadTime?.toIso8601String(),
      'fullCacheAge': _lastLoadTime != null 
          ? DateTime.now().difference(_lastLoadTime!).inMinutes 
          : null,
      'fullCacheExpired': _lastLoadTime != null 
          ? DateTime.now().difference(_lastLoadTime!) > _cacheValidDuration
          : true,
      
      // Summary
      'cacheLevel': _availableCustomerIds != null ? (_customerNamesMap != null ? (_customerMap != null ? 3 : 2) : 1) : 0,
      'totalMemoryUsed': '${(_availableCustomerIds?.length ?? 0) + (_customerNamesMap?.length ?? 0) + (_customerMap?.length ?? 0)} objects',
    };
  }
}
