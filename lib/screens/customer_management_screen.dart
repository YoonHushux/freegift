import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/excel_upload_widget.dart';
import '../services/customer_service.dart';
import '../models/customer.dart';
import '../utils/responsive.dart';

/// Screen for managing customer data and Excel imports
class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    _customerService.getAllCustomers().listen((customers) {
      if (mounted) {
        setState(() {
          _customers = customers;
        });
      }
    });
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             customer.id.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'จัดการข้อมูลลูกค้า',
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
            fontWeight: FontWeight.w700,
            color: GlassTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: GlassTheme.textPrimary),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Excel Upload Section
              ExcelUploadWidget(
                title: 'นำเข้าข้อมูลลูกค้าจาก Excel',
                onUploadComplete: () {
                  // Refresh customers list after upload
                  _loadCustomers();
                },
              ),

              SizedBox(height: Responsive.spacing(context, mobile: 24, tablet: 32, desktop: 40)),

              // Customer List Section
              GlassContainer(
                padding: Responsive.padding(
                  context,
                  mobile: const EdgeInsets.all(20),
                  tablet: const EdgeInsets.all(24),
                  desktop: const EdgeInsets.all(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header and Search
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'รายการลูกค้า (${_filteredCustomers.length} คน)',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, mobile: 18, tablet: 20, desktop: 22),
                              fontWeight: FontWeight.w700,
                              color: GlassTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadCustomers,
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: GlassTheme.primary,
                            size: Responsive.iconSize(context, mobile: 24, tablet: 26, desktop: 28),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),

                    // Search bar
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color: GlassTheme.textPrimary,
                        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                      ),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาลูกค้า (รหัสหรือชื่อ)',
                        hintStyle: TextStyle(
                          color: GlassTheme.textSecondary,
                          fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: GlassTheme.textSecondary,
                          size: Responsive.iconSize(context, mobile: 20, tablet: 22, desktop: 24),
                        ),
                        filled: true,
                        fillColor: GlassTheme.glassBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.borderRadius(context, mobile: 12, tablet: 16, desktop: 20),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: Responsive.padding(
                          context,
                          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),

                    // Customer List
                    if (_filteredCustomers.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(
                            Responsive.spacing(context, mobile: 32, tablet: 40, desktop: 48),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: Responsive.iconSize(context, mobile: 64, tablet: 72, desktop: 80),
                                color: GlassTheme.textSecondary,
                              ),
                              SizedBox(height: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),
                              Text(
                                _searchQuery.isEmpty 
                                    ? 'ยังไม่มีข้อมูลลูกค้า\nกรุณาอัพโหลดไฟล์ Excel'
                                    : 'ไม่พบลูกค้าที่ค้นหา',
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                  color: GlassTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredCustomers.length,
                        separatorBuilder: (context, index) => SizedBox(
                          height: Responsive.spacing(context, mobile: 8, tablet: 10, desktop: 12),
                        ),
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return _buildCustomerCard(customer);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      padding: Responsive.padding(
        context,
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      decoration: BoxDecoration(
        color: GlassTheme.glassBackground,
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 12, tablet: 16, desktop: 20),
        ),
        border: Border.all(
          color: GlassTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Customer icon
          Container(
            width: Responsive.width(context, mobile: 48, tablet: 56, desktop: 64),
            height: Responsive.height(context, mobile: 48, tablet: 56, desktop: 64),
            decoration: BoxDecoration(
              color: GlassTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(
                Responsive.borderRadius(context, mobile: 8, tablet: 10, desktop: 12),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: GlassTheme.primary,
              size: Responsive.iconSize(context, mobile: 24, tablet: 28, desktop: 32),
            ),
          ),

          SizedBox(width: Responsive.spacing(context, mobile: 16, tablet: 20, desktop: 24)),

          // Customer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.w600,
                    color: GlassTheme.textPrimary,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8)),
                Text(
                  'รหัส: ${customer.id}',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    color: GlassTheme.textSecondary,
                  ),
                ),
                if (customer.importedFrom != null) ...[
                  SizedBox(height: Responsive.spacing(context, mobile: 4, tablet: 6, desktop: 8)),
                  Text(
                    'นำเข้าจาก: ${customer.importedFrom}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 12, tablet: 14, desktop: 16),
                      color: GlassTheme.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status indicator
          Container(
            width: Responsive.width(context, mobile: 8, tablet: 10, desktop: 12),
            height: Responsive.height(context, mobile: 8, tablet: 10, desktop: 12),
            decoration: const BoxDecoration(
              color: GlassTheme.success,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
