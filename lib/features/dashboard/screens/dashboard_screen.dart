import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../catalog/screens/product_list_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../orders/screens/order_list_screen.dart';
import '../../deliveries/screens/delivery_list_screen.dart';
import '../../collections/screens/due_collection_screen.dart';
import '../../targets/screens/target_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../notices/screens/notice_list_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../reports/screens/activity_log_screen.dart';
import '../../settings/screens/site_settings_screen.dart';
import '../../infrastructure/screens/factory_list_screen.dart';
import '../../infrastructure/screens/factory_types_screen.dart';
import '../../catalog/screens/category_list_screen.dart';
import '../../catalog/screens/brand_list_screen.dart';
import '../../catalog/screens/company_list_screen.dart';
import '../../catalog/screens/unit_list_screen.dart';
import '../../inventory/screens/stock_transfer_screen.dart';
import '../../inventory/screens/stock_request_screen.dart';
import '../../inventory/screens/stock_usage_screen.dart';
import '../../procurement/screens/purchase_list_screen.dart';
import '../../procurement/screens/purchase_return_screen.dart';
import '../../procurement/screens/supplier_list_screen.dart';
import '../../sales_returns/screens/sales_return_screen.dart';
import '../../collections/screens/collection_history_screen.dart';
import '../../personnel/screens/employee_list_screen.dart';
import '../../personnel/screens/manufacturing_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel currentUser;

  const DashboardScreen({super.key, required this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
  }

  Future<void> _fetchDashboardMetrics() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get(ApiConstants.dashboard);
      if (response.data['success'] == true) {
        setState(() {
          _dashboardData = response.data['data'];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SecureStorageService.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.currentUser.employee;
    final stats = _dashboardData?['employee_stats'];
    final managerStats = _dashboardData?['manager_stats'];
    final bool canApprove = widget.currentUser.isAdmin ||
        widget.currentUser.role == 'admin' ||
        widget.currentUser.role == 'manager';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.currentUser.name),
            if (employee?.designation != null)
              Text(
                '${employee!.designation} • ${employee.territory ?? "Head Office"}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardMetrics,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryGreen),
              accountName: Text(widget.currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.currentUser.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.currentUser.name.isNotEmpty ? widget.currentUser.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ),

            // SYSTEM
            _buildDrawerCategory(
              title: 'SYSTEM',
              icon: Icons.grid_view_rounded,
              initiallyExpanded: true,
              children: [
                _buildDrawerItem('Dashboard', Icons.dashboard_outlined, () => Navigator.pop(context)),
                _buildDrawerItem('Notice Board', Icons.notifications_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListScreen()));
                }),
                _buildDrawerItem('Site Settings', Icons.settings_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SiteSettingsScreen()));
                }),
              ],
            ),

            // INFRASTRUCTURE
            _buildDrawerCategory(
              title: 'INFRASTRUCTURE',
              icon: Icons.domain_outlined,
              children: [
                _buildDrawerItem('Factory & Warehouses', Icons.storefront_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FactoryListScreen()));
                }),
                _buildDrawerItem('Factory Types', Icons.category_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FactoryTypesScreen()));
                }),
              ],
            ),

            // CATALOG
            _buildDrawerCategory(
              title: 'CATALOG',
              icon: Icons.inventory_2_outlined,
              children: [
                _buildDrawerItem('All Products', Icons.inventory_2_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                }),
                _buildDrawerItem('Categories', Icons.category_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen(initialTabIndex: 0)));
                }),
                _buildDrawerItem('Sub Categories', Icons.account_tree_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen(initialTabIndex: 1)));
                }),
                _buildDrawerItem('Brands', Icons.branding_watermark_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandListScreen()));
                }),
                _buildDrawerItem('Companies', Icons.business_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyListScreen()));
                }),
                _buildDrawerItem('Units Control', Icons.straighten_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitListScreen()));
                }),
              ],
            ),

            // INVENTORY
            _buildDrawerCategory(
              title: 'INVENTORY',
              icon: Icons.layers_outlined,
              children: [
                _buildDrawerItem('Current Stock', Icons.storage_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                }),
                _buildDrawerItem('Stock Transfer', Icons.swap_horiz_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StockTransferScreen()));
                }),
                _buildDrawerItem('Stock Request', Icons.move_to_inbox_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StockRequestScreen()));
                }),
                _buildDrawerItem('Stock Usages', Icons.production_quantity_limits_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StockUsageScreen()));
                }),
              ],
            ),

            // PROCUREMENT
            _buildDrawerCategory(
              title: 'PROCUREMENT',
              icon: Icons.shopping_cart_outlined,
              children: [
                _buildDrawerItem('All Purchases', Icons.shopping_bag_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen()));
                }),
                _buildDrawerItem('Purchase Returns', Icons.assignment_return_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseReturnScreen()));
                }),
                _buildDrawerItem('Suppliers', Icons.local_shipping_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierListScreen()));
                }),
              ],
            ),

            // SALES & CRM
            _buildDrawerCategory(
              title: 'SALES & CRM',
              icon: Icons.point_of_sale_outlined,
              initiallyExpanded: true,
              children: [
                _buildDrawerItem('All Sales', Icons.receipt_long_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen(isSalesLedger: true)));
                }),
                _buildDrawerItem('Wholesale Sales', Icons.store_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen(isSalesLedger: true, filterCategory: 'wholesale')));
                }),
                _buildDrawerItem('Returns', Icons.assignment_return_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesReturnScreen()));
                }),
                _buildDrawerItem('Customers', Icons.people_alt_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen(initialOnlyWholesale: false)));
                }),
                _buildDrawerItem('Wholesale Customers', Icons.storefront_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen(initialOnlyWholesale: true)));
                }),
                _buildDrawerItem('Due Collection', Icons.payments_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DueCollectionScreen()));
                }),
                _buildDrawerItem('All Collections', Icons.history_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionHistoryScreen(filterMyCollections: false)));
                }),
                _buildDrawerItem('Customer Due Collection', Icons.monetization_on_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen(initialOnlyDue: true)));
                }),
                _buildDrawerItem('Employee Collection', Icons.badge_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionHistoryScreen(filterMyCollections: true)));
                }),
              ],
            ),

            // PERSONNEL & HR
            _buildDrawerCategory(
              title: 'PERSONNEL & HR',
              icon: Icons.badge_outlined,
              children: [
                _buildDrawerItem('Employees', Icons.badge_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeListScreen()));
                }),
                _buildDrawerItem('Employee Orders', Icons.receipt_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OrderListScreen(canApprove: canApprove)));
                }),
                _buildDrawerItem('Employee Orders Delivery', Icons.local_shipping_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryListScreen()));
                }),
                _buildDrawerItem('Year Target', Icons.calendar_today_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TargetScreen()));
                }),
                _buildDrawerItem('Month Target', Icons.calendar_month_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TargetScreen()));
                }),
                _buildDrawerItem('Recipes', Icons.receipt_long_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManufacturingScreen(initialTabIndex: 0)));
                }),
                _buildDrawerItem('Manufacturings', Icons.precision_manufacturing_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManufacturingScreen(initialTabIndex: 1)));
                }),
                _buildDrawerItem('Factory Products', Icons.inventory_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManufacturingScreen(initialTabIndex: 2)));
                }),
                _buildDrawerItem('Expenses Management', Icons.account_balance_wallet_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
                }),
              ],
            ),

            // ACTIVITY & REPORTS
            _buildDrawerCategory(
              title: 'ACTIVITY & REPORTS',
              icon: Icons.analytics_outlined,
              initiallyExpanded: true,
              children: [
                _buildDrawerItem('Summary Report', Icons.pie_chart_outline, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'summary')));
                }),
                _buildDrawerItem('Product Transfer', Icons.swap_horiz_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'product_transfer')));
                }),
                _buildDrawerItem('Customer Ledger', Icons.menu_book_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'customer_ledger')));
                }),
                _buildDrawerItem('Factory Stock', Icons.storefront_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'factory_stock')));
                }),
                _buildDrawerItem('Product Stock', Icons.inventory_2_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'product_stock')));
                }),
                _buildDrawerItem('Raw Material Stock', Icons.opacity_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'raw_material_stock')));
                }),
                _buildDrawerItem('Finished Goods Stock', Icons.check_circle_outline, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'finished_goods_stock')));
                }),
                _buildDrawerItem('Product-Wise Sale', Icons.bar_chart_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'product_wise_sale')));
                }),
                _buildDrawerItem('Employee Sale Collection', Icons.people_outline, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'employee_sale_collection')));
                }),
                _buildDrawerItem('Employee Product-Wise Sale', Icons.shopping_bag_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'employee_product_wise_sale')));
                }),
                _buildDrawerItem('Customer Due Collection by Employee', Icons.monetization_on_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'customer_due_collection_by_employee')));
                }),
                _buildDrawerItem('Activity Log', Icons.history_outlined, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityLogScreen()));
                }),
              ],
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardMetrics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Field Officer KPI Stats
                  if (stats != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Today Orders',
                            '${stats['today_orders_count'] ?? 0}',
                            '৳ ${(stats['today_orders_amount'] ?? 0).toStringAsFixed(0)}',
                            Icons.shopping_bag_outlined,
                            AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Month Collection',
                            '৳ ${(stats['month_collection'] ?? 0).toStringAsFixed(0)}',
                            'Target: ${_formatTargetShort(stats['active_target'])}',
                            Icons.account_balance_wallet_outlined,
                            Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Active Target Progress Banner
                    if (stats['active_target'] != null)
                      _buildTargetBanner(stats['active_target']),
                    const SizedBox(height: 20),
                  ],

                  // Manager Approvals
                  if (managerStats != null) ...[
                    const Text(
                      'Management Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderListScreen(canApprove: canApprove)),
                            ),
                            child: _buildMetricCard(
                              '1st Approvals',
                              '${managerStats['pending_first_approvals'] ?? 0}',
                              'Orders Waiting',
                              Icons.rule_outlined,
                              Colors.orange.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderListScreen(canApprove: canApprove)),
                            ),
                            child: _buildMetricCard(
                              '2nd Approvals',
                              '${managerStats['pending_second_approvals'] ?? 0}',
                              'Dispatch Waiting',
                              Icons.check_circle_outline,
                              Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- 1. SYSTEM ---
                  _buildSectionHeader('SYSTEM', Icons.grid_view_rounded),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'Notice Board',
                        'Announcements & news',
                        Icons.campaign_outlined,
                        Colors.pink.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeListScreen())),
                      ),
                      _buildNavTile(
                        'Site Settings',
                        'Server & config',
                        Icons.settings_outlined,
                        Colors.blueGrey.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SiteSettingsScreen())),
                      ),
                    ],
                  ),

                  // --- 2. INFRASTRUCTURE ---
                  _buildSectionHeader('INFRASTRUCTURE', Icons.domain_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'Factory & Warehouses',
                        'Dispatch locations',
                        Icons.storefront_outlined,
                        Colors.teal.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FactoryListScreen())),
                      ),
                      _buildNavTile(
                        'Factory Types',
                        'Classifications',
                        Icons.category_outlined,
                        Colors.cyan.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FactoryTypesScreen())),
                      ),
                    ],
                  ),

                  // --- 3. CATALOG ---
                  _buildSectionHeader('CATALOG', Icons.inventory_2_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'All Products',
                        'Stock & prices',
                        Icons.inventory_2_outlined,
                        Colors.indigo.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                      ),
                      _buildNavTile(
                        'Categories',
                        'Product categories',
                        Icons.category_outlined,
                        Colors.deepOrange.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen(initialTabIndex: 0))),
                      ),
                      _buildNavTile(
                        'Sub Categories',
                        'Sub-groups',
                        Icons.account_tree_outlined,
                        Colors.teal.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryListScreen(initialTabIndex: 1))),
                      ),
                      _buildNavTile(
                        'Brands',
                        'Product brands',
                        Icons.branding_watermark_outlined,
                        Colors.purple.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandListScreen())),
                      ),
                      _buildNavTile(
                        'Companies',
                        'Manufacturers',
                        Icons.business_outlined,
                        Colors.blue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyListScreen())),
                      ),
                      _buildNavTile(
                        'Units Control',
                        'Packaging units',
                        Icons.straighten_outlined,
                        Colors.brown.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitListScreen())),
                      ),
                    ],
                  ),

                  // --- 4. INVENTORY ---
                  _buildSectionHeader('INVENTORY', Icons.layers_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'Current Stock',
                        'Warehouse stock',
                        Icons.storage_outlined,
                        Colors.blue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                      ),
                      _buildNavTile(
                        'Stock Transfer',
                        'Inter-warehouse',
                        Icons.swap_horiz_outlined,
                        Colors.amber.shade900,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockTransferScreen())),
                      ),
                      _buildNavTile(
                        'Stock Request',
                        'Central requisitions',
                        Icons.move_to_inbox_outlined,
                        Colors.deepPurple.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockRequestScreen())),
                      ),
                      _buildNavTile(
                        'Stock Usages',
                        'Material consumption',
                        Icons.production_quantity_limits_outlined,
                        Colors.red.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockUsageScreen())),
                      ),
                    ],
                  ),

                  // --- 5. PROCUREMENT ---
                  _buildSectionHeader('PROCUREMENT', Icons.shopping_cart_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'Purchases',
                        'Supplier POs & invoices',
                        Icons.shopping_bag_outlined,
                        Colors.lightBlue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen())),
                      ),
                      _buildNavTile(
                        'Purchase Returns',
                        'Damage claims',
                        Icons.assignment_return_outlined,
                        Colors.orange.shade900,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseReturnScreen())),
                      ),
                      _buildNavTile(
                        'Suppliers',
                        'Vendor directory',
                        Icons.local_shipping_outlined,
                        Colors.teal.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierListScreen())),
                      ),
                    ],
                  ),

                  // --- 6. SALES & CRM ---
                  _buildSectionHeader('SALES & CRM', Icons.point_of_sale_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'All Sales',
                        'Sales order ledger',
                        Icons.receipt_long_outlined,
                        Colors.blue.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen(isSalesLedger: true))),
                      ),
                      _buildNavTile(
                        'Wholesale Sales',
                        'Bulk & trade sales',
                        Icons.store_outlined,
                        Colors.indigo.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderListScreen(isSalesLedger: true, filterCategory: 'wholesale'))),
                      ),
                      _buildNavTile(
                        'Returns',
                        'Sales return notes',
                        Icons.assignment_return_outlined,
                        Colors.deepOrange.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesReturnScreen())),
                      ),
                      _buildNavTile(
                        'Customers',
                        'Customer directory',
                        Icons.people_alt_outlined,
                        Colors.blueGrey.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen(initialOnlyWholesale: false))),
                      ),
                      _buildNavTile(
                        'Wholesale Customers',
                        'Wholesale directory',
                        Icons.storefront_outlined,
                        Colors.green.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen(initialOnlyWholesale: true))),
                      ),
                      _buildNavTile(
                        'Due Collection',
                        'Settle debts FIFO',
                        Icons.payments_outlined,
                        Colors.teal.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DueCollectionScreen())),
                      ),
                      _buildNavTile(
                        'All Collections',
                        'Collection history',
                        Icons.history_outlined,
                        Colors.purple.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionHistoryScreen(filterMyCollections: false))),
                      ),
                      _buildNavTile(
                        'Customer Due Collection',
                        'Due customer list',
                        Icons.monetization_on_outlined,
                        Colors.teal.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen(initialOnlyDue: true))),
                      ),
                      _buildNavTile(
                        'Employee Collection',
                        'Employee ledger',
                        Icons.badge_outlined,
                        Colors.brown.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionHistoryScreen(filterMyCollections: true))),
                      ),
                    ],
                  ),

                  // --- 7. PERSONNEL & HR ---
                  _buildSectionHeader('PERSONNEL & HR', Icons.badge_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'Employees',
                        'Officer directory',
                        Icons.badge_outlined,
                        Colors.blue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeListScreen())),
                      ),
                      _buildNavTile(
                        'Employee Orders',
                        'Field orders log',
                        Icons.receipt_outlined,
                        Colors.blue.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderListScreen(canApprove: canApprove))),
                      ),
                      _buildNavTile(
                        'Employee Orders Delivery',
                        'Dispatch & receive',
                        Icons.local_shipping_outlined,
                        Colors.deepPurple.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryListScreen())),
                      ),
                      _buildNavTile(
                        'Year Target',
                        'Annual sales goals',
                        Icons.calendar_today_outlined,
                        Colors.deepOrange.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TargetScreen())),
                      ),
                      _buildNavTile(
                        'Month Target',
                        'Monthly quota',
                        Icons.calendar_month_outlined,
                        Colors.deepOrange.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TargetScreen())),
                      ),
                      _buildNavTile(
                        'Recipes',
                        'Formula & mixes',
                        Icons.receipt_long_outlined,
                        Colors.purple.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManufacturingScreen(initialTabIndex: 0))),
                      ),
                      _buildNavTile(
                        'Manufacturings',
                        'Production batches',
                        Icons.precision_manufacturing_outlined,
                        Colors.amber.shade900,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManufacturingScreen(initialTabIndex: 1))),
                      ),
                      _buildNavTile(
                        'Factory Products',
                        'Factory catalog',
                        Icons.inventory_outlined,
                        Colors.teal.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManufacturingScreen(initialTabIndex: 2))),
                      ),
                      _buildNavTile(
                        'Expenses Management',
                        'Conveyance & daily',
                        Icons.account_balance_wallet_outlined,
                        Colors.brown.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen())),
                      ),
                    ],
                  ),

                  // --- 8. ACTIVITY & REPORTS ---
                  _buildSectionHeader('ACTIVITY & REPORTS', Icons.analytics_outlined),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    children: [
                      _buildNavTile(
                        'Summary Report',
                        'Financial overview',
                        Icons.pie_chart_outline,
                        Colors.blue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'summary'))),
                      ),
                      _buildNavTile(
                        'Product Transfer',
                        'Stock movements',
                        Icons.swap_horiz_outlined,
                        Colors.orange.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'product_transfer'))),
                      ),
                      _buildNavTile(
                        'Customer Ledger',
                        'Account statements',
                        Icons.menu_book_outlined,
                        Colors.indigo.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'customer_ledger'))),
                      ),
                      _buildNavTile(
                        'Factory Stock',
                        'Factory inventory',
                        Icons.storefront_outlined,
                        Colors.teal.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'factory_stock'))),
                      ),
                      _buildNavTile(
                        'Product Stock',
                        'Stock quantities',
                        Icons.inventory_2_outlined,
                        Colors.deepPurple.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'product_stock'))),
                      ),
                      _buildNavTile(
                        'Raw Material Stock',
                        'Material inventory',
                        Icons.opacity_outlined,
                        Colors.brown.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'raw_material_stock'))),
                      ),
                      _buildNavTile(
                        'Finished Goods',
                        'Ready stock',
                        Icons.check_circle_outline,
                        Colors.green.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'finished_goods_stock'))),
                      ),
                      _buildNavTile(
                        'Product-Wise Sale',
                        'Item sales chart',
                        Icons.bar_chart_outlined,
                        Colors.deepOrange.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'product_wise_sale'))),
                      ),
                      _buildNavTile(
                        'Employee Sales',
                        'Collections by staff',
                        Icons.people_outline,
                        Colors.purple.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'employee_sale_collection'))),
                      ),
                      _buildNavTile(
                        'Employee Item Sale',
                        'Products by staff',
                        Icons.shopping_bag_outlined,
                        Colors.lightBlue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'employee_product_wise_sale'))),
                      ),
                      _buildNavTile(
                        'Due By Employee',
                        'Collections per staff',
                        Icons.monetization_on_outlined,
                        Colors.teal.shade900,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen(initialReportType: 'customer_due_collection_by_employee'))),
                      ),
                      _buildNavTile(
                        'Activity Log',
                        'Audit trail',
                        Icons.history_outlined,
                        Colors.blueGrey.shade700,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityLogScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _formatTargetShort(dynamic target) {
    if (target == null) return 'N/A';
    final amt = target['target_amount'] ?? 0;
    return '৳ ${(amt / 1000).toStringAsFixed(0)}k';
  }

  Widget _buildMetricCard(String title, String mainValue, String subValue, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Icon(icon, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mainValue,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(subValue, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetBanner(dynamic target) {
    final double pct = (target['percentage'] as num?)?.toDouble() ?? 0.0;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  target['title'] ?? 'Monthly Target Progress',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  void _showWebModuleDialog(String title, String details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.computer, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCategory({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.primaryGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      initiallyExpanded: initiallyExpanded,
      childrenPadding: const EdgeInsets.only(left: 12),
      children: children,
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 18, color: AppTheme.textMuted),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }

  Widget _buildNavTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
