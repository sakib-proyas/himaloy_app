import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import 'order_detail_screen.dart';
import 'create_order_screen.dart';

class OrderListScreen extends StatefulWidget {
  final bool canApprove;
  final bool isSalesLedger;
  final String? filterCategory; // 'wholesale' or null
  final UserModel? currentUser;

  const OrderListScreen({
    super.key,
    this.canApprove = false,
    this.isSalesLedger = true,
    this.filterCategory,
    this.currentUser,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  List<dynamic> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _tabs = ['All', 'Paid', 'Due', 'Partial'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchSales();
      }
    });
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> params = {};
      if (widget.filterCategory != null) {
        params['category'] = widget.filterCategory;
      }

      final tabIdx = _tabController.index;
      if (tabIdx == 1) params['status'] = 'paid';
      if (tabIdx == 2) params['status'] = 'due';
      if (tabIdx == 3) params['status'] = 'partial';

      final endpoint = widget.isSalesLedger ? '/sales' : ApiConstants.employeeOrders;
      final res = await _apiClient.get(endpoint, queryParameters: params);

      if (res.data['success'] == true) {
        final data = res.data['data'];
        final List list = data is List ? data : (data['data'] ?? []);

        // Client-side fallback filtering by officer assigned customers for non-admin staff
        List<dynamic> items = list;
        final user = widget.currentUser;
        if (user != null && !user.isAdmin && user.role.toLowerCase() != 'admin' && user.role.toLowerCase() != 'superadmin') {
          final empName = (user.employee?.name ?? user.name).toLowerCase();
          final empId = user.employee?.id;

          // Fetch officer assigned customer IDs to filter
          try {
            final custRes = await _apiClient.get(ApiConstants.customers);
            if (custRes.data['success'] == true) {
              final List rawCustList = custRes.data['data']['data'] ?? [];
              final assignedCustIds = <int>{};
              final assignedCustNames = <String>{};

              for (final c in rawCustList) {
                final officerId = c['officer_id'];
                final officerStr = (c['officer'] ?? '').toString().toLowerCase();
                if ((empId != null && officerId == empId) ||
                    (officerStr.isNotEmpty && (officerStr.contains(empName) || empName.contains(officerStr)))) {
                  if (c['id'] != null) assignedCustIds.add(c['id']);
                  if (c['name'] != null) assignedCustNames.add((c['name'] ?? '').toString().toLowerCase());
                }
              }

              items = items.where((s) {
                final custId = s['customer_id'] ?? s['customer']?['id'];
                final custName = (s['customer_name'] ?? s['customer']?['name'] ?? '').toString().toLowerCase();
                final officerId = s['officer_id'] ?? s['employee_id'];
                final officerStr = (s['officer'] ?? s['employee_name'] ?? '').toString().toLowerCase();

                if (custId != null && assignedCustIds.contains(custId)) return true;
                if (custName.isNotEmpty && assignedCustNames.contains(custName)) return true;
                if (empId != null && officerId == empId) return true;
                if (officerStr.isNotEmpty && (officerStr.contains(empName) || empName.contains(officerStr))) return true;
                return false;
              }).toList();
            }
          } catch (_) {}
        }

        setState(() {
          _sales = items;
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to load sales order ledger. Please check connection.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'FINAL_APPROVED':
      case 'APPROVED':
        return AppTheme.primaryGreen;
      case 'DUE':
      case 'WAITING':
        return AppTheme.errorRed;
      case 'PARTIAL':
      case 'FIRST_APPROVED':
        return Colors.orange.shade800;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.filterCategory == 'wholesale' ? 'Wholesale Sales' : 'Sales Order Ledger';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
          _fetchSales();
        },
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('Add Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchSales, child: const Text('Retry Connection')),
                    ],
                  ),
                )
              : _sales.isEmpty
                  ? Center(
                      child: Text(
                        widget.filterCategory == 'wholesale'
                            ? 'No wholesale sales records found for your assigned customers.'
                            : 'No sales records found for your assigned customers.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSales,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          final invoiceNo = sale['invoice_no'] ?? 'SAL-#${sale['id']}';
                          final date = sale['date'] ?? '-';
                          final customerName = sale['customer_name'] ?? 'General Customer';
                          final factory = sale['warehouse_name'] ?? 'Main Factory';
                          final status = (sale['status'] ?? 'DUE').toString().toUpperCase();
                          final total = double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0;
                          final paid = double.tryParse(sale['paid']?.toString() ?? '0') ?? 0.0;
                          final due = double.tryParse(sale['due']?.toString() ?? '0') ?? 0.0;
                          final statusColor = _getStatusColor(status);

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        invoiceNo,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    customerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dispatched: $factory • Date: $date',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  const Divider(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          Text('৳ ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text('Paid Amount', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          Text('৳ ${paid.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Due Balance', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          Text(
                                            '৳ ${due.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: due > 0 ? AppTheme.errorRed : AppTheme.primaryGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
