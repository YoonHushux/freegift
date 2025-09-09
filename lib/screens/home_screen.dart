import '../theme/glass_theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';
import 'requisition_screen.dart';
import 'requisition_reports_screen.dart' show RequisitionReportsScreen;
import 'manage_free_gifts_screen.dart';
import 'customer_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            GlassContainer(
              width: Responsive.width(
                context,
                mobile: 43,
                tablet: 50,
                desktop: 60,
              ),
              height: Responsive.height(
                context,
                mobile: 43,
                tablet: 50,
                desktop: 60,
              ),
              padding: EdgeInsets.all(
                Responsive.spacing(context, mobile: 9, tablet: 10, desktop: 12),
              ),
              borderRadius: Responsive.borderRadius(
                context,
                mobile: 13,
                tablet: 15,
                desktop: 18,
              ),
              backgroundColor: GlassTheme.glassBackground,
              borderColor: GlassTheme.glassBorder,
              child: Icon(
                Icons.business_center_rounded,
                color: GlassTheme.textPrimary,
                size: Responsive.iconSize(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32,
                ),
              ),
            ),
            SizedBox(
              width: Responsive.spacing(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Gift Management',
                    style: TextStyle(
                      color: GlassTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.fontSize(
                        context,
                        mobile: 17,
                        tablet: 20,
                        desktop: 24,
                      ),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'ระบบจัดการของแจก',
                    style: TextStyle(
                      color: GlassTheme.textSecondary,
                      fontSize: Responsive.fontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: GlassTheme.textPrimary),
        toolbarHeight: Responsive.height(
          context,
          mobile: 95,
          tablet: 100,
          desktop: 120,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            Responsive.height(context, mobile: 51, tablet: 60, desktop: 70),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 20,
              ),
              vertical: Responsive.spacing(
                context,
                mobile: 7,
                tablet: 8,
                desktop: 10,
              ),
            ),
            child: GlassContainer(
              padding: EdgeInsets.all(
                Responsive.spacing(context, mobile: 3, tablet: 4, desktop: 5),
              ),
              borderRadius: Responsive.borderRadius(
                context,
                mobile: 21,
                tablet: 25,
                desktop: 30,
              ),
              backgroundColor: GlassTheme.glassBackground,
              borderColor: GlassTheme.glassBorder,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.borderRadius(
                      context,
                      mobile: 17,
                      tablet: 20,
                      desktop: 25,
                    ),
                  ),
                  gradient: LinearGradient(colors: GlassTheme.accentGradient),
                  boxShadow: [
                    BoxShadow(
                      color: GlassTheme.glassShadow,
                      blurRadius: Responsive.width(
                        context,
                        mobile: 7,
                        tablet: 8,
                        desktop: 10,
                      ),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: GlassTheme.textPrimary,
                unselectedLabelColor: GlassTheme.textSecondary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.fontSize(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.fontSize(
                    context,
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                ),
                tabs: [
                  Tab(
                    text: 'Inventory',
                    icon: Icon(
                      Icons.inventory_2_rounded,
                      size: Responsive.iconSize(
                        context,
                        mobile: 17,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                  ),
                  Tab(
                    text: 'Requisition',
                    icon: Icon(
                      Icons.receipt_long_rounded,
                      size: Responsive.iconSize(
                        context,
                        mobile: 17,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                  ),
                  Tab(
                    text: 'Reports',
                    icon: Icon(
                      Icons.analytics_rounded,
                      size: Responsive.iconSize(
                        context,
                        mobile: 17,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                  ),
                  Tab(
                    text: 'Customers',
                    icon: Icon(
                      Icons.people_rounded,
                      size: Responsive.iconSize(
                        context,
                        mobile: 17,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManageFreeGiftsScreen(),
          RequisitionScreen(),
          RequisitionReportsScreen(),
          CustomerManagementScreen(),
        ],
      ),
    );
  }
}
