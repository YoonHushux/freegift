import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/requisition_report.dart';
import '../services/requisition_report_service.dart';
import '../services/customer_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';

class RequisitionReportsScreen extends StatefulWidget {
  const RequisitionReportsScreen({super.key});

  @override
  State<RequisitionReportsScreen> createState() =>
      _RequisitionReportsScreenState();
}

class _RequisitionReportsScreenState extends State<RequisitionReportsScreen> {
  final RequisitionReportService _reportService = RequisitionReportService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  List<RequisitionReport> _allReports = [];
  List<RequisitionReport> _filteredReports = [];
  List<String> _customerIds = [];
  List<String> _itemNames = [];
  final Set<int> _expandedItems = {}; // เพิ่มการจัดการการขยาย
  Map<String, String> _customerNames = {}; // เก็บชื่อลูกค้า

  String? _selectedCustomer;
  String? _selectedItem;
  DateRange? _selectedDateRange;
  SortBy _sortBy = SortBy.date;
  SortOrder _sortOrder = SortOrder.descending;
  bool _isLoading = true;
  final bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load customer IDs and item names
      final customerIds = await _reportService.getAllCustomerIds();
      final itemNames = await _reportService.getAllItemNames();

      print(
        '🔄 Loading customer names for ${customerIds.length} unique customers...',
      );

      // Load customer names เฉพาะที่ต้องการ (ไม่ใช่ทั้งหมด)
      final customerNames = await _customerService.getCustomerNamesByIds(
        customerIds,
      );

      // Debug: ตรวจสอบข้อมูลลูกค้า
      print('📊 Customer IDs needed: ${customerIds.length}');
      print('📋 Customer Names loaded: ${customerNames.length} items');
      print('📈 Cache stats: ${_customerService.getCacheStats()}');

      // ตรวจสอบว่ามีข้อมูลลูกค้าหรือไม่
      final hasCustomerData = await _customerService.hasCustomerData();
      if (!hasCustomerData && customerIds.isNotEmpty) {
        _showErrorSnackBar(
          'ไม่พบข้อมูลลูกค้า กรุณาอัพโหลดไฟล์ Customer.xlsx ในหน้า Settings',
        );
      }

      setState(() {
        _customerIds = customerIds;
        _itemNames = itemNames;
        _customerNames = customerNames;
      });

      // Listen to reports stream
      _reportService.getAllRequisitionReports().listen((reports) {
        if (mounted) {
          setState(() {
            _allReports = reports;
            _applyFiltersAndSort();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}');
      }
    }
  }

  void _applyFiltersAndSort() {
    List<RequisitionReport> filtered = _reportService.filterReports(
      _allReports,
      searchText: _searchController.text,
      customerId: _selectedCustomer,
      itemName: _selectedItem,
      dateRange: _selectedDateRange,
    );

    filtered = _reportService.sortReports(filtered, _sortBy, _sortOrder);

    setState(() {
      _filteredReports = filtered;
    });
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCustomer = null;
      _selectedItem = null;
      _selectedDateRange = null;
    });
    _applyFiltersAndSort();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange != null
          ? DateTimeRange(
              start: _selectedDateRange!.startDate,
              end: _selectedDateRange!.endDate,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: GlassTheme.primary,
              onPrimary: GlassTheme.textPrimary,
              surface: GlassTheme.textPrimary,
              onSurface: GlassTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = DateRange(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
      _applyFiltersAndSort();
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: 17, // 20*0.85
            padding: const EdgeInsets.all(14), // 16*0.85
            backgroundColor: GlassTheme.glassBackground,
            borderColor: GlassTheme.glassBorder,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 340, // 400*0.85
                    maxWidth: 298, // 350*0.85
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10), // 12*0.85
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10), // 12*0.85
                    child: _buildNetworkImage(imageUrl),
                  ),
                ),
                const SizedBox(height: 14), // 16*0.85
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, // 24*0.85
                      vertical: 10, // 12*0.85
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // 12*0.85
                      gradient: const LinearGradient(
                        colors: GlassTheme.accentGradient,
                      ),
                    ),
                    child: const Text(
                      'ปิด',
                      style: TextStyle(
                        color: GlassTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: GlassTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildReportsList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.all(14), // 16*0.85
      child: Column(
        children: [
          GlassContainer(
            borderRadius: 14, // 16*0.85
            padding: const EdgeInsets.all(14), // 16*0.85
            child: Column(
              children: [
                _buildSearchBar(),
                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  _buildFiltersSection(),
                ],
              ],
            ),
          ),
          if (_filteredReports.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildResultsInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GlassContainer(
      borderRadius: 20,
      backgroundColor: GlassTheme.glassBackground,
      borderColor: GlassTheme.glassBorder,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _onSearchChanged(),
        textInputAction: TextInputAction.search,
        autocorrect: true,
        enableSuggestions: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          color: GlassTheme.textPrimary,
          fontSize: 16,
          height: 1.4, // เพิ่ม line height สำหรับภาษาไทย
        ),
        decoration: InputDecoration(
          hintText: 'ค้นหาด้วยชื่อลูกค้า รายการสินค้า หรือคำอธิบาย...',
          hintStyle: TextStyle(
            color: GlassTheme.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
          prefixIcon: Icon(Icons.search, color: GlassTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: GlassTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCustomerDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildItemDropdown()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDateRangeButton()),
            const SizedBox(width: 12),
            Expanded(child: _buildSortButton()),
          ],
        ),
        if (_hasActiveFilters()) ...[
          const SizedBox(height: 12),
          _buildClearFiltersButton(),
        ],
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    return GlassContainer(
      borderRadius: 12,
      backgroundColor: GlassTheme.glassBackground,
      borderColor: GlassTheme.glassBorder,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCustomer, // เปลี่ยนจาก value เป็น initialValue
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: GlassTheme.textPrimary,
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text(
              'ทุกลูกค้า',
              style: TextStyle(color: GlassTheme.textSecondary),
            ),
          ),
          ..._customerIds.map((customerId) {
            final customerName = _customerNames[customerId] ?? customerId;
            return DropdownMenuItem(
              value: customerId,
              child: Text(
                '$customerName ($customerId)', // แสดงทั้งชื่อและรหัส
                style: const TextStyle(color: GlassTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCustomer = value;
          });
          _applyFiltersAndSort();
        },
        hint: Text(
          'เลือกลูกค้า',
          style: TextStyle(color: GlassTheme.textSecondary, fontSize: 15),
        ),
        icon: Icon(Icons.arrow_drop_down, color: GlassTheme.textSecondary),
      ),
    );
  }

  Widget _buildItemDropdown() {
    return GlassContainer(
      borderRadius: 12,
      backgroundColor: GlassTheme.glassBackground,
      borderColor: GlassTheme.glassBorder,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedItem, // เปลี่ยนจาก value เป็น initialValue
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: GlassTheme.textPrimary,
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text(
              'ทุกสินค้า',
              style: TextStyle(color: GlassTheme.textSecondary),
            ),
          ),
          ..._itemNames.map((itemName) {
            return DropdownMenuItem(
              value: itemName,
              child: Text(
                itemName,
                style: const TextStyle(color: GlassTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedItem = value;
          });
          _applyFiltersAndSort();
        },
        hint: Text(
          'เลือกสินค้า',
          style: TextStyle(color: GlassTheme.textSecondary, fontSize: 15),
        ),
        icon: Icon(Icons.arrow_drop_down, color: GlassTheme.textSecondary),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              GlassTheme.accent.withValues(alpha: 0.3),
              GlassTheme.primary.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: GlassTheme.textPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${_dateFormat.format(_selectedDateRange!.startDate)} - ${_dateFormat.format(_selectedDateRange!.endDate)}'
                    : 'เลือกช่วงวันที่',
                style: TextStyle(
                  color: _selectedDateRange != null
                      ? GlassTheme.textPrimary
                      : GlassTheme.textSecondary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      color: GlassTheme.textPrimary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              GlassTheme.accent.withValues(alpha: 0.3),
              GlassTheme.primary.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.sort, color: GlassTheme.textPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getSortLabel(),
                style: const TextStyle(
                  color: GlassTheme.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: GlassTheme.textSecondary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'date_desc',
          child: Text(
            'วันที่ (ใหม่ → เก่า)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'date_asc',
          child: Text(
            'วันที่ (เก่า → ใหม่)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'customer_asc',
          child: Text(
            'ลูกค้า (A → Z)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'customer_desc',
          child: Text(
            'ลูกค้า (Z → A)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'item_asc',
          child: Text(
            'สินค้า (A → Z)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'item_desc',
          child: Text(
            'สินค้า (Z → A)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'quantity_desc',
          child: Text(
            'จำนวน (มาก → น้อย)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
        PopupMenuItem(
          value: 'quantity_asc',
          child: Text(
            'จำนวน (น้อย → มาก)',
            style: TextStyle(color: GlassTheme.textPrimary),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'date_desc':
            _sortBy = SortBy.date;
            _sortOrder = SortOrder.descending;
            break;
          case 'date_asc':
            _sortBy = SortBy.date;
            _sortOrder = SortOrder.ascending;
            break;
          case 'customer_asc':
            _sortBy = SortBy.customer;
            _sortOrder = SortOrder.ascending;
            break;
          case 'customer_desc':
            _sortBy = SortBy.customer;
            _sortOrder = SortOrder.descending;
            break;
          case 'item_asc':
            _sortBy = SortBy.item;
            _sortOrder = SortOrder.ascending;
            break;
          case 'item_desc':
            _sortBy = SortBy.item;
            _sortOrder = SortOrder.descending;
            break;
          case 'quantity_desc':
            _sortBy = SortBy.quantity;
            _sortOrder = SortOrder.descending;
            break;
          case 'quantity_asc':
            _sortBy = SortBy.quantity;
            _sortOrder = SortOrder.ascending;
            break;
        }
        _applyFiltersAndSort();
      },
    );
  }

  String _getSortLabel() {
    String sortByText = '';
    String orderText = '';

    switch (_sortBy) {
      case SortBy.date:
        sortByText = 'วันที่';
        break;
      case SortBy.customer:
        sortByText = 'ลูกค้า';
        break;
      case SortBy.item:
        sortByText = 'สินค้า';
        break;
      case SortBy.quantity:
        sortByText = 'จำนวน';
        break;
    }

    orderText = _sortOrder == SortOrder.ascending ? '↑' : '↓';

    return '$sortByText $orderText';
  }

  Widget _buildClearFiltersButton() {
    return GestureDetector(
      onTap: _clearFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              GlassTheme.error.withValues(alpha: 0.3),
              GlassTheme.error.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: GlassTheme.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.clear_all, color: GlassTheme.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'ล้างตัวกรอง',
              style: TextStyle(
                color: GlassTheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: GlassTheme.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: GlassTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: GlassTheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            'พบ ${_filteredReports.length} รายการ',
            style: TextStyle(
              color: GlassTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(width: 8),
            Text(
              '(กรองแล้ว)',
              style: TextStyle(
                color: GlassTheme.primary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedCustomer != null ||
        _selectedItem != null ||
        _selectedDateRange != null;
  }

  Widget _buildReportsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GlassTheme.accent),
      );
    }

    if (_filteredReports.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      GlassTheme.accent.withValues(alpha: 0.3),
                      GlassTheme.primary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 40,
                  color: GlassTheme.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _hasActiveFilters()
                    ? 'ไม่พบรายการที่ตรงกับการค้นหา'
                    : 'ยังไม่มีรายการเบิกของ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GlassTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _hasActiveFilters()
                    ? 'ลองปรับเปลี่ยนเงื่อนไขการค้นหาหรือล้างตัวกรอง'
                    : 'เริ่มต้นการเพิ่มรายการเบิกของจากหน้าหลัก',
                style: TextStyle(
                  fontSize: 13,
                  color: GlassTheme.textSecondary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredReports.length,
                itemBuilder: (context, index) {
                  return _buildReportRow(_filteredReports[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(RequisitionReport report, int index) {
    final isExpanded = _expandedItems.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // แถวหลัก (ลำดับ วันที่ ลูกค้า ปุ่มดู)
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(index);
                } else {
                  _expandedItems.add(index);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ลำดับ
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [GlassTheme.secondary, GlassTheme.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GlassTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GlassTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // วันที่และเวลา
                  SizedBox(
                    width: 85,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: GlassTheme.accent.withValues(alpha: 0.2),
                          ),
                          child: Text(
                            _dateFormat.format(report.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: GlassTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _timeFormat.format(report.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: GlassTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ข้อมูลลูกค้า
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'ลูกค้า',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: GlassTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _customerNames[report.customerId] ?? 'ไม่พบข้อมูล',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GlassTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_customerNames[report.customerId] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '(${report.customerId})',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: GlassTheme.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ปุ่มขยาย/ย่อ
                ],
              ),
            ),
          ),
          // รายละเอียดเพิ่มเติม (แสดงเมื่อขยาย)
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: _buildExpandedDetails(report),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(RequisitionReport report) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ข้อมูลลูกค้า (เพิ่มใหม่)
          _buildDetailRow(
            icon: Icons.person_rounded,
            label: 'ลูกค้า',
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    GlassTheme.primary.withValues(alpha: 0.2),
                    GlassTheme.primary.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: GlassTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customerNames[report.customerId] ?? 'ไม่พบข้อมูลลูกค้า',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: GlassTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'รหัส: ${report.customerId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: GlassTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ข้อมูลสินค้า
          _buildDetailRow(
            icon: Icons.inventory_2_rounded,
            label: 'สินค้า',
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    GlassTheme.accent.withValues(alpha: 0.2),
                    GlassTheme.accent.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: GlassTheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                report.itemName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: GlassTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // จำนวน
          _buildDetailRow(
            icon: Icons.confirmation_number_rounded,
            label: 'จำนวน',
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    GlassTheme.secondary.withValues(alpha: 0.3),
                    GlassTheme.primary.withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: GlassTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${report.quantity} หน่วย',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GlassTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // รูปภาพ
          _buildDetailRow(
            icon: Icons.photo_camera_rounded,
            label: 'รูปภาพ',
            content: report.imageUrl != null
                ? GestureDetector(
                    onTap: () => _showImageDialog(report.imageUrl!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            GlassTheme.success.withValues(alpha: 0.8),
                            GlassTheme.success.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.success.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 18,
                            color: GlassTheme.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ดูรูปภาพ',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GlassTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: GlassTheme.textSecondary.withValues(alpha: 0.2),
                      border: Border.all(
                        color: GlassTheme.textSecondary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: GlassTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ไม่มีรูปภาพ',
                          style: TextStyle(
                            fontSize: 12,
                            color: GlassTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                GlassTheme.primary.withValues(alpha: 0.2),
                GlassTheme.primary.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Icon(icon, color: GlassTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GlassTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: GlassTheme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: GlassTheme.error, size: 48),
                const SizedBox(height: 8),
                Text(
                  'ไม่สามารถโหลดรูปภาพได้',
                  style: TextStyle(
                    color: GlassTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
