import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/customer_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  bool _fileExists = false;
  Map<String, String> _customerData = {};

  @override
  void initState() {
    super.initState();
    _checkExistingFile();
  }

  Future<void> _checkExistingFile() async {
    setState(() => _isLoading = true);
    
    try {
      final exists = await _customerService.checkExcelFileExists();
      print('📄 File exists: $exists');
      
      if (exists) {
        final hasData = await _customerService.hasCustomerData();
        final cacheStats = _customerService.getCacheStats();
        
        print('📊 Has customer data: $hasData');
        print('📈 Cache stats: $cacheStats');
        
        if (hasData) {
          // ดึงข้อมูลลูกค้าทั้งหมดเพื่อแสดงในหน้า Management
          final customers = await _customerService.getAllCustomers();
          final customerNames = <String, String>{};
          customers.forEach((id, customer) {
            customerNames[id] = customer.customerName;
          });
          
          setState(() {
            _fileExists = exists;
            _customerData = customerNames;
          });
        } else {
          setState(() {
            _fileExists = exists;
            _customerData = {};
          });
        }
      } else {
        setState(() {
          _fileExists = false;
          _customerData = {};
        });
        print('❌ No Excel file found in Firebase Storage');
      }
    } catch (e) {
      print('❌ Error in _checkExistingFile: $e');
      setState(() {
        _fileExists = false;
        _customerData = {};
      });
      _showErrorSnackBar('เกิดข้อผิดพลาดในการตรวจสอบไฟล์: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadExcelFile() async {
    try {
      // เลือกไฟล์ Excel
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        
        final fileBytes = result.files.single.bytes!;
        final success = await _customerService.uploadExcelFile(fileBytes);
        
        if (success) {
          _showSuccessSnackBar('อัพโหลดไฟล์ Excel สำเร็จ');
          await _checkExistingFile(); // รีเฟรชข้อมูล
        } else {
          _showErrorSnackBar('เกิดข้อผิดพลาดในการอัพโหลดไฟล์');
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCache() async {
    setState(() => _isLoading = true);
    
    try {
      // ล้าง cache และโหลดข้อมูลใหม่
      _customerService.clearCache();
      await _checkExistingFile();
      _showSuccessSnackBar('รีเฟรชข้อมูลเสร็จสิ้น');
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการรีเฟรชข้อมูล: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GlassTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GlassTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('จัดการข้อมูลลูกค้า'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.padding(
            context,
            mobile: const EdgeInsets.all(16),
            tablet: const EdgeInsets.all(20),
            desktop: const EdgeInsets.all(24),
          ),
          child: Column(
            children: [
              _buildUploadSection(),
              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32, desktop: 40)),
              if (_fileExists) _buildCustomerDataSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return GlassContainer(
      padding: Responsive.padding(
        context,
        mobile: const EdgeInsets.all(20),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      GlassTheme.primary.withValues(alpha: 0.3),
                      GlassTheme.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: GlassTheme.textPrimary,
                  size: Responsive.iconSize(context, mobile: 24, tablet: 28, desktop: 32),
                ),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อัพโหลดไฟล์ข้อมูลลูกค้า',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
                        fontWeight: FontWeight.w700,
                        color: GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ไฟล์ Excel (.xlsx) ที่มีข้อมูลลูกค้า',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                        color: GlassTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GlassTheme.glassBorder.withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              color: GlassTheme.glassBackground.withValues(alpha: 0.1),
            ),
            child: Column(
              children: [
                Icon(
                  _fileExists ? Icons.check_circle : Icons.cloud_upload,
                  size: 48,
                  color: _fileExists ? GlassTheme.success : GlassTheme.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  _fileExists 
                    ? 'ไฟล์ Customer.xlsx พร้อมใช้งาน'
                    : 'ไม่พบไฟล์ Customer.xlsx',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _fileExists ? GlassTheme.success : GlassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'รูปแบบไฟล์: Column A = รหัสลูกค้า, Column B = ชื่อลูกค้า',
                  style: TextStyle(
                    fontSize: 13,
                    color: GlassTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              onPressed: _isLoading ? null : _pickAndUploadExcelFile,
              text: _isLoading 
                ? 'กำลังอัพโหลด...' 
                : (_fileExists ? 'อัพเดตไฟล์' : 'อัพโหลดไฟล์'),
              icon: _isLoading 
                ? Icons.hourglass_empty 
                : Icons.upload_file,
              color: _fileExists ? GlassTheme.accent : GlassTheme.primary,
            ),
          ),
          if (_fileExists) ...[
            SizedBox(height: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20)),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                onPressed: _isLoading ? null : _refreshCache,
                text: 'รีเฟรชข้อมูล',
                icon: Icons.refresh,
                color: GlassTheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerDataSection() {
    return GlassContainer(
      padding: Responsive.padding(
        context,
        mobile: const EdgeInsets.all(20),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      GlassTheme.success.withValues(alpha: 0.3),
                      GlassTheme.accent.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.people_rounded,
                  color: GlassTheme.textPrimary,
                  size: Responsive.iconSize(context, mobile: 24, tablet: 28, desktop: 32),
                ),
              ),
              SizedBox(width: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลลูกค้าปัจจุบัน',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
                        fontWeight: FontWeight.w700,
                        color: GlassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'พบข้อมูลลูกค้า ${_customerData.length} รายการ (Smart Cache)',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                        color: GlassTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 28)),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              itemCount: _customerData.length,
              itemBuilder: (context, index) {
                final entry = _customerData.entries.elementAt(index);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: GlassTheme.glassBackground.withValues(alpha: 0.1),
                    border: Border.all(
                      color: GlassTheme.glassBorder.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: GlassTheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: GlassTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GlassTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
