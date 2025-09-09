import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:io';
import '../models/requisition.dart';
import '../services/requisition_service.dart';
import '../services/free_gift_service.dart';
import '../services/customer_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';

class RequisitionScreen extends StatefulWidget {
  const RequisitionScreen({super.key});

  @override
  State<RequisitionScreen> createState() => _RequisitionScreenState();
}

class _RequisitionScreenState extends State<RequisitionScreen> {
  final RequisitionService _requisitionService = RequisitionService();
  final FreeGiftService _freeGiftService = FreeGiftService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedItem;
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _customerIdController.addListener(_onCustomerIdChanged);
  }

  @override
  void dispose() {
    _customerIdController.removeListener(_onCustomerIdChanged);
    _customerIdController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onCustomerIdChanged() async {
    final customerId = _customerIdController.text.trim();
    if (customerId.isNotEmpty) {
      try {
        final name = await _customerService.getCustomerName(customerId);
        if (mounted) {
          setState(() {
            _customerName = name;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _customerName = null;
          });
        }
      }
    } else {
      setState(() {
        _customerName = null;
      });
    }
  }

  Future<void> _addRequisitionItem() async {
    // ตรวจสอบข้อมูลให้ครบถ้วน - ต้องมีทุกฟิลด์
    if (_selectedItem == null ||
        _customerIdController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _selectedImage == null) {
      _showErrorSnackBar(
        'กรุณากรอกข้อมูลให้ครบถ้วน (รายการ, รหัสลูกค้า, จำนวน และรูปภาพ)',
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showErrorSnackBar('กรุณากรอกจำนวนที่ถูกต้อง');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // อัปโหลดรูปภาพไปยัง Firebase Storage ก่อน
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _requisitionService.uploadImage(_selectedImage!);
      }

      final item = RequisitionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: _selectedItem!,
        quantity: quantity,
        imageUrl: imageUrl, // ใช้ URL จาก Firebase Storage
        createdAt: DateTime.now(),
      );

      await _requisitionService.addItemToRequisition(
        _customerIdController.text.trim(),
        'Customer', // ใช้ค่าเริ่มต้น
        item,
      );

      _clearForm();
      _showSuccessSnackBar('สร้างรายการเบิกของสำเร็จ');
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    // เคลียข้อมูลทั้งหมด
    _quantityController.clear();
    _customerIdController.clear();
    setState(() {
      _selectedItem = null;
      _selectedImage = null;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _requisitionService.takePhoto();
      if (photo != null) {
        setState(() => _selectedImage = photo);
      }
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถถ่ายรูปได้: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _requisitionService.pickImage();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถเลือกรูปได้: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: GlassTheme.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: GlassTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(child: _buildAddItemForm()),
    );
  }

  Widget _buildAddItemForm() {
    return Container(
      margin: Responsive.padding(
        context,
        mobile: const EdgeInsets.all(14),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      child: GlassContainer(
        borderRadius: Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
        padding: Responsive.padding(
          context,
          mobile: const EdgeInsets.all(17),
          tablet: const EdgeInsets.all(20),
          desktop: const EdgeInsets.all(24),
        ),
        backgroundColor: GlassTheme.glassBackground,
        borderColor: GlassTheme.glassBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // 12*0.85
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10), // 12*0.85
                    gradient: LinearGradient(
                      colors: [
                        GlassTheme.secondary.withValues(alpha: 0.3),
                        GlassTheme.primary.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: GlassTheme.textPrimary,
                    size: 20, // 24*0.85
                  ),
                ),
                const SizedBox(width: 14), // 16*0.85
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สร้างรายการเบิกของ',
                        style: const TextStyle(
                          fontSize: 17, // 20*0.85
                          fontWeight: FontWeight.w700,
                          color: GlassTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3), // 4*0.85
                      Text(
                        'กรอกข้อมูลสินค้าที่ต้องการเบิกจากคลัง',
                        style: TextStyle(
                          fontSize: 12, // 14*0.85
                          color: GlassTheme.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // 24*0.85
            _buildTextField(
              controller: _customerIdController,
              label: 'รหัสลูกค้า',
              hint: 'กรอกรหัสลูกค้า',
              keyboardType: TextInputType.number,
            ),
            if (_customerName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: Responsive.padding(
                  context,
                  mobile: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.green,
                      size: Responsive.iconSize(
                        context,
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                    ),
                    SizedBox(
                      width: Responsive.spacing(
                        context,
                        mobile: 8,
                        tablet: 10,
                        desktop: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'ชื่อลูกค้า: $_customerName',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(
                            context,
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10), // 12*0.85
            Row(
              children: [
                Expanded(flex: 2, child: _buildItemDropdown()),
                const SizedBox(width: 10), // 12*0.85
                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'จำนวน',
                    hint: 'จำนวน',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildImageSection(),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GlassTheme.secondary,
                    GlassTheme.primary,
                    GlassTheme.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: GlassTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _addRequisitionItem,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: GlassTheme.textPrimary,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'กำลังสร้างรายการ...',
                                style: TextStyle(
                                  color: GlassTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: GlassTheme.textPrimary,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'สร้างรายการ',
                                style: TextStyle(
                                  color: GlassTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
        GlassContainer(
          borderRadius: 20,
          backgroundColor: GlassTheme.glassBackground,
          borderColor: GlassTheme.glassBorder,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            autocorrect: true,
            enableSuggestions: true,
            textCapitalization: keyboardType == TextInputType.number
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            style: const TextStyle(
              color: GlassTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4, // เพิ่ม line height สำหรับภาษาไทย
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: GlassTheme.textSecondary,
                fontSize: 15,
                height: 1.4, // เพิ่ม line height สำหรับภาษาไทย
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              // เพิ่มการจัดการสำหรับ input method
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'รายการที่เบิก',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
        GlassContainer(
          borderRadius: 20,
          backgroundColor: Colors.white.withValues(alpha: 0.05), // เพิ่มความโปร่งใสให้ชัดเจนขึ้น
          borderColor: GlassTheme.glassBorder.withValues(alpha: 0.8), // เพิ่มความชัดของกรอบ
          child: StreamBuilder<List<String>>(
            stream: _freeGiftService.getAllActiveFreeGifts().map(
              (gifts) => gifts.map((gift) => gift.itemName).toList(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: const Text(
                    'กำลังโหลดรายการ...',
                    style: TextStyle(
                      color: GlassTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: const TextStyle(
                      color: GlassTheme.error,
                      fontSize: 15,
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              // ถ้าไม่มีรายการใน Free gift ให้แสดงข้อความแนะนำ
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: const Text(
                    'ไม่มีรายการ กดปุ่ม + เพื่อเพิ่มรายการ',
                    style: TextStyle(
                      color: GlassTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue:
                    _selectedItem, // เปลี่ยนจาก value เป็น initialValue
                style: const TextStyle(
                  color: GlassTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                dropdownColor: const Color(0xFF2A2D3A), // เปลี่ยนเป็นสีเข้มที่ชัดเจนขึ้น
                borderRadius: BorderRadius.circular(12), // เพิ่ม border radius
                elevation: 8, // เพิ่มเงาให้ชัดเจน
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white, // ใช้สีขาวเพื่อให้ชัดเจน
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedItem = value);
                },
                hint: Text(
                  'เลือกรายการ',
                  style: TextStyle(
                    color: GlassTheme.textSecondary.withValues(alpha: 0.8), // เพิ่มความชัดเจน
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: GlassTheme.textPrimary, // เปลี่ยนเป็นสีหลักให้ชัดเจน
                  size: 28,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'หมายเหตุ (รูปภาพ)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildImageButton(
                onTap: _takePhoto,
                icon: Icons.camera_alt,
                label: 'ถ่ายรูป',
                color: GlassTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                onTap: _pickImage,
                icon: Icons.photo_library,
                label: 'เลือกรูป',
                color: GlassTheme.accent,
              ),
            ),
          ],
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: GlassTheme.textPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: GlassTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
