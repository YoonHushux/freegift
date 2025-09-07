import 'dart:io';
import '../models/free_gift.dart';
import '../services/free_gift_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';

class ManageFreeGiftsScreen extends StatefulWidget {
  const ManageFreeGiftsScreen({super.key});

  @override
  State<ManageFreeGiftsScreen> createState() => _ManageFreeGiftsScreenState();
}

class _ManageFreeGiftsScreenState extends State<ManageFreeGiftsScreen> {
  final FreeGiftService _freeGiftService = FreeGiftService();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  List<FreeGift> _freeGifts = [];

  @override
  void initState() {
    super.initState();
    _loadFreeGifts();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _loadFreeGifts() {
    _freeGiftService.getAllActiveFreeGifts().listen((gifts) {
      if (mounted) {
        setState(() {
          _freeGifts = gifts;
        });
      }
    });
  }

  Future<void> _addFreeGift() async {
    if (_itemNameController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกชื่อรายการ');
      return;
    }

    if (_quantityController.text.trim().isEmpty) {
      _showErrorSnackBar('กรุณากรอกจำนวน');
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showErrorSnackBar('กรุณากรอกจำนวนที่ถูกต้อง (มากกว่า 0)');
      return;
    }

    if (_selectedImage == null) {
      _showErrorSnackBar('กรุณาเลือกรูปภาพ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = _freeGiftService.generateId();
      String? imageUrl;

      // อัพโหลดรูปภาพถ้ามี
      if (_selectedImage != null) {
        setState(() => _isUploading = true);
        imageUrl = await _freeGiftService.uploadImage(_selectedImage!, id);
      }

      final freeGift = FreeGift(
        id: id,
        itemName: _itemNameController.text.trim(),
        description: '', // คำอธิบายว่าง สำหรับใช้ในอนาคต
        quantity: quantity,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ใช้ addOrUpdateFreeGift แทน addFreeGift เพื่อรวมจำนวนถ้ามีรายการซ้ำ
      await _freeGiftService.addOrUpdateFreeGift(freeGift);

      _clearForm();
      _showSuccessSnackBar('เพิ่มรายการสำเร็จ');
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  void _clearForm() {
    _itemNameController.clear();
    _quantityController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _takePicture() async {
    try {
      final photo = await _freeGiftService.takePhoto();
      if (photo != null) {
        setState(() {
          _selectedImage = photo;
        });
      }
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถถ่ายรูปได้: ${e.toString()}');
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _freeGiftService.pickImage();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถเลือกรูปภาพได้: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: Responsive.padding(
                  context,
                  mobile: const EdgeInsets.all(14),
                  tablet: const EdgeInsets.all(20),
                  desktop: const EdgeInsets.all(24),
                ),
                child: ResponsiveLayout(
                  maxWidth: 1200,
                  centerContent: true,
                  child: Column(
                    children: [
                      _buildAddForm(),
                      SizedBox(height: Responsive.spacing(context, mobile: 20, tablet: 24, desktop: 32)),
                      _buildFreeGiftsList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return GlassContainer(
      borderRadius: 17, // 20*0.85
      padding: const EdgeInsets.all(17), // 20*0.85
      backgroundColor: GlassTheme.glassBackground,
      borderColor: GlassTheme.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassContainer(
                width: 34, // 40*0.85
                height: 34, // 40*0.85
                padding: const EdgeInsets.all(7), // 8*0.85
                borderRadius: 10, // 12*0.85
                backgroundColor: GlassTheme.primary.withValues(alpha: 0.15),
                borderColor: GlassTheme.primary.withValues(alpha: 0.3),
                child: Icon(
                  Icons.add_box_rounded,
                  color: GlassTheme.primary,
                  size: 17, // 20*0.85
                ),
              ),
              const SizedBox(width: 10), // 12*0.85
              Text(
                'เพิ่มรายการใหม่',
                style: TextStyle(
                  fontSize: 15, // 18*0.85
                  fontWeight: FontWeight.w700,
                  color: GlassTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9), // 10*0.85

          // ชื่อรายการ
          const Text(
            'ชื่อรายการ',
            style: TextStyle(
              fontSize: 14, // 16*0.85
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7), // 8*0.85
          GlassContainer(
            borderRadius: 17, // 20*0.85
            backgroundColor: GlassTheme.glassBackground,
            borderColor: GlassTheme.glassBorder,
            child: TextField(
              controller: _itemNameController,
              textInputAction: TextInputAction.next,
              autocorrect: true,
              enableSuggestions: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: GlassTheme.textPrimary,
                fontSize: 14, // 16*0.85
                fontWeight: FontWeight.w500,
                height: 1.4, // เพิ่ม line height สำหรับภาษาไทย
              ),
              decoration: InputDecoration(
                hintText: 'กรอกชื่อรายการ',
                hintStyle: TextStyle(
                  color: GlassTheme.textSecondary,
                  fontSize: 13, // 15*0.85
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, // 16*0.85
                  vertical: 14, // 16*0.85
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 9), // 10*0.85

          // จำนวน
          const Text(
            'จำนวน',
            style: TextStyle(
              fontSize: 14, // 16*0.85
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7), // 8*0.85
          GlassContainer(
            borderRadius: 17, // 20*0.85
            backgroundColor: GlassTheme.glassBackground,
            borderColor: GlassTheme.glassBorder,
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                color: GlassTheme.textPrimary,
                fontSize: 14, // 16*0.85
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'กรอกจำนวน',
                hintStyle: TextStyle(
                  color: GlassTheme.textSecondary,
                  fontSize: 13, // 15*0.85
                  height: 1.4,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, // 16*0.85
                  vertical: 14, // 16*0.85
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 9), // 10*0.85

          // รูปภาพ
          const Text(
            'รูปภาพ',
            style: TextStyle(
              fontSize: 14, // 16*0.85
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7), // 8*0.85

          if (_selectedImage != null) ...[
            Center(
              child: GlassContainer(
                width: 170, // 200*0.85
                height: 170, // 200*0.85
                borderRadius: 14, // 16*0.85
                backgroundColor: GlassTheme.glassBackground,
                borderColor: GlassTheme.glassBorder,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14), // 16*0.85
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14), // 16*0.85
          ],

          Row(
            children: [
              Expanded(
                child: GlassButton(
                  onPressed: _takePicture,
                  text: 'ถ่ายรูป',
                  icon: Icons.camera_alt_rounded,
                  color: GlassTheme.secondary
                ),
              ),
              const SizedBox(width: 14), // 16*0.85
              Expanded(
                child: GlassButton(
                  onPressed: _pickImage,
                  text: 'เลือกรูป',
                  icon: Icons.photo_library_rounded,
                  color: GlassTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9), // 10*0.85

          // ปุ่มเพิ่ม
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? GlassContainer(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: GlassTheme.primary.withValues(alpha: 0.3),
                    borderColor: GlassTheme.primary.withValues(alpha: 0.5),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                GlassTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isUploading
                                ? 'กำลังอัพโหลด...'
                                : 'กำลังเพิ่มรายการ...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: GlassTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GlassButton(
                    onPressed: _addFreeGift,
                    text: 'เพิ่มรายการ',
                    icon: Icons.add_box_rounded,
                    color: GlassTheme.primary,
                    textColor: Colors.white,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeGiftsList() {
    if (_freeGifts.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(40),
        borderRadius: 20,
        backgroundColor: GlassTheme.glassBackground,
        borderColor: GlassTheme.glassBorder,
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 48,
              color: GlassTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีรายการในคลัง',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GlassTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เริ่มต้นเพิ่มรายการแรกของคุณ',
              style: TextStyle(fontSize: 14, color: GlassTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'รายการทั้งหมด (${_freeGifts.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlassTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ...List.generate(_freeGifts.length, (index) {
          final gift = _freeGifts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: GlassCard(
              child: ListTile(
                contentPadding: const EdgeInsets.all(0),
                leading: gift.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          gift.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: GlassTheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    GlassTheme.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Image loading error - could be logged in production
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: GlassTheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: GlassTheme.primary,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: GlassTheme.primary.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: GlassTheme.primary,
                        ),
                      ),
                title: Text(
                  gift.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GlassTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'จำนวนคงเหลือ: ${gift.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: gift.quantity > 0
                        ? GlassTheme.textSecondary
                        : Colors.red,
                    fontWeight: gift.quantity <= 5
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
