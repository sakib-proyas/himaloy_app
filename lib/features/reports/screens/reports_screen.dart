import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  final String? initialReportType;

  const ReportsScreen({super.key, this.initialReportType});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiClient _apiClient = ApiClient();

  late String _selectedReportKey;
  bool _isLoading = false;
  dynamic _reportData;

  final Map<String, Map<String, dynamic>> _reports = {
    'summary': {
      'title': 'Executive Summary Report',
      'icon': Icons.pie_chart_outline,
      'endpoint': '/reports/summary',
      'color': Colors.blue,
    },
    'product_transfer': {
      'title': 'Product Transfer',
      'icon': Icons.swap_horiz_outlined,
      'endpoint': '/reports/product-transfer',
      'color': Colors.orange,
    },
    'customer_ledger': {
      'title': 'Customer Ledger',
      'icon': Icons.menu_book_outlined,
      'endpoint': '/reports/customer-ledger',
      'color': Colors.indigo,
    },
    'factory_stock': {
      'title': 'Factory Stock',
      'icon': Icons.storefront_outlined,
      'endpoint': '/reports/factory-stock',
      'color': Colors.teal,
    },
    'product_stock': {
      'title': 'Product Stock',
      'icon': Icons.inventory_2_outlined,
      'endpoint': '/reports/product-stock',
      'color': Colors.deepPurple,
    },
    'raw_material_stock': {
      'title': 'Raw Material Stock',
      'icon': Icons.opacity_outlined,
      'endpoint': '/reports/raw-material-stock',
      'color': Colors.brown,
    },
    'finished_goods_stock': {
      'title': 'Finished Goods Stock',
      'icon': Icons.check_circle_outline,
      'endpoint': '/reports/finished-goods-stock',
      'color': Colors.green,
    },
    'product_wise_sale': {
      'title': 'Product-Wise Sale',
      'icon': Icons.bar_chart_outlined,
      'endpoint': '/reports/product-wise-sale',
      'color': Colors.deepOrange,
    },
    'employee_sale_collection': {
      'title': 'Employee Sale Collection',
      'icon': Icons.people_outline,
      'endpoint': '/reports/employee-sale-collection',
      'color': Colors.purple,
    },
    'employee_product_wise_sale': {
      'title': 'Employee Product-Wise Sale',
      'icon': Icons.shopping_bag_outlined,
      'endpoint': '/reports/employee-product-wise-sale',
      'color': Colors.lightBlue,
    },
    'customer_due_collection_by_employee': {
      'title': 'Customer Due Collection by Employee',
      'icon': Icons.monetization_on_outlined,
      'endpoint': '/reports/customer-due-collection-by-employee',
      'color': Colors.teal,
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedReportKey = widget.initialReportType ?? 'summary';
    _fetchReport(_selectedReportKey);
  }

  Future<void> _fetchReport(String key) async {
    setState(() {
      _selectedReportKey = key;
      _isLoading = true;
      _reportData = null;
    });

    final config = _reports[key];
    if (config == null) return;

    try {
      final res = await _apiClient.get(config['endpoint']);
      if (res.data['success'] == true) {
        setState(() {
          _reportData = res.data['data'];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _reports[_selectedReportKey] ?? _reports['summary']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Center'),
      ),
      body: Column(
        children: [
          // Horizontal Selector Chips for All 11 Reports
          Container(
            height: 52,
            color: Colors.grey.shade100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _reports.entries.map((entry) {
                final isSelected = entry.key == _selectedReportKey;
                final color = entry.value['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(entry.value['icon'] as IconData, size: 16, color: isSelected ? Colors.white : color),
                    label: Text(
                      entry.value['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: Colors.white,
                    onSelected: (_) => _fetchReport(entry.key),
                  ),
                );
              }).toList(),
            ),
          ),

          // Main Report Content Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchReport(_selectedReportKey),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(currentConfig['icon'] as IconData, color: currentConfig['color'] as Color, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentConfig['title'] as String,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Expanded(child: _buildReportDataView()),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDataView() {
    if (_reportData == null) {
      return const Center(child: Text('No data recorded for this report.'));
    }

    // 1. Executive Summary Report
    if (_selectedReportKey == 'summary') {
      final m = _reportData as Map<String, dynamic>;
      final topSelling = m['top_selling'] as List? ?? [];
      final officers = m['officer_performance'] as List? ?? [];

      return ListView(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCard('GROSS REVENUE', '৳ ${m['gross_revenue'] ?? 0}', Colors.blue.shade800)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard('CASH INFLOW', '৳ ${m['cash_inflow'] ?? 0}', Colors.green.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildKpiCard('CASH OUTFLOW', '৳ ${m['cash_outflow'] ?? 0}', Colors.red.shade800)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard('NET CASH POSITION', '৳ ${m['net_cash'] ?? 0}', Colors.amber.shade900)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildKpiCard('NEW RECEIVABLES (DUE)', '৳ ${m['new_receivables'] ?? 0}', Colors.orange.shade800)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard('SUPPLIER PAYABLES', '৳ ${m['supplier_payables'] ?? 0}', Colors.purple.shade800)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Top Selling Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...topSelling.map((item) {
            final p = item as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text('${p['product']} (${p['sku'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Category: ${p['category'] ?? "General"} • Qty Sold: ${p['qty_sold']}'),
                trailing: Text('৳ ${p['revenue']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Sales Officer Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...officers.map((item) {
            final o = item as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(o['officer'] ?? 'Sales Officer', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Designation: ${o['designation'] ?? "N/A"} • Orders: ${o['orders_count']}'),
                trailing: Text('৳ ${o['total_sales']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              ),
            );
          }),
        ],
      );
    }

    // 2. Customer Due Collection by Employee
    if (_selectedReportKey == 'customer_due_collection_by_employee' && _reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No collections recorded.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['collection_no'] ?? 'COLL-${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  Text(item['date'] ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Collector: ${item['employee_collector'] ?? "-"}'),
                  Text('Customer: ${item['customer_name'] ?? "-"}'),
                  if (item['order_no'] != null) Text('Order: ${item['order_no']}'),
                ],
              ),
              trailing: Text(
                '৳ ${item['amount'] ?? item['total_collected'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
              ),
            ),
          );
        },
      );
    }

    // 3. Employee Product-Wise Sale
    if (_selectedReportKey == 'employee_product_wise_sale' && _reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No product sales recorded.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item['sales_representative'] ?? item['employee_name'] ?? 'Sales Officer', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Factory: ${item['factory_base'] ?? "Main Factory"}'),
                  Text('Product: ${item['product_name']} (${item['sku'] ?? 'N/A'})'),
                  Text('Category: ${item['category'] ?? "General"} • Qty: ${item['qty_sold']}'),
                ],
              ),
              trailing: Text('৳ ${item['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ),
          );
        },
      );
    }

    // 4. Employee Sale & Collection Performance
    if (_selectedReportKey == 'employee_sale_collection' && _reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No performance data found.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item['officer_name'] ?? item['name'] ?? 'Officer', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Designation: ${item['designation'] ?? "N/A"} • Base: ${item['factory_base'] ?? "Main Factory"}\nOrders Booked: ${item['orders_booked'] ?? item['total_orders']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Sales: ৳ ${item['total_sales'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                  Text('Collected: ৳ ${item['total_collected'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
                ],
              ),
            ),
          );
        },
      );
    }

    // 5. Product-Wise Sale Report
    if (_selectedReportKey == 'product_wise_sale' && _reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No sales found.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${item['product_name']} (${item['product_code'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Category: ${item['category'] ?? "General"} • Pack: ${item['pack_size'] ?? "Unit"}\nQty Sold: ${item['qty_sold']}'),
              trailing: Text('৳ ${item['total_revenue'] ?? item['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen)),
            ),
          );
        },
      );
    }

    // 6. Product Stock / Factory Stock / Raw Material Stock / Finished Goods Stock
    if ((_selectedReportKey == 'product_stock' || _selectedReportKey == 'factory_stock' || _selectedReportKey == 'raw_material_stock' || _selectedReportKey == 'finished_goods_stock') && _reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No stock items recorded.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          final qty = double.tryParse(item['total_stock']?.toString() ?? item['quantity']?.toString() ?? item['stock']?.toString() ?? '0') ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${item['product_name']} (${item['sku'] ?? "N/A"})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Category: ${item['category'] ?? "General"}${item['warehouse_name'] != null ? " • Warehouse: ${item['warehouse_name']}" : ""}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${qty.toStringAsFixed(2)} ${item['unit'] ?? "pcs"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: qty <= 0 ? AppTheme.errorRed : AppTheme.primaryGreen)),
                  if (item['stock_value'] != null) Text('Val: ৳ ${item['stock_value']}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          );
        },
      );
    }

    // 7. Product Transfer Report
    if (_selectedReportKey == 'product_transfer' && _reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No transfer logs found.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          final status = (item['status'] ?? 'APPROVED').toString().toUpperCase();
          final isApproved = status == 'APPROVED';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['reference_no'] ?? 'TRANSFER-#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.green.shade100 : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isApproved ? Colors.green.shade900 : Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Product: ${item['product'] ?? item['product_name']}'),
                  Text('From: ${item['from_dipo']} ➔ To: ${item['to_dipo']}'),
                  Text('Date: ${item['date']}'),
                ],
              ),
              trailing: Text('${item['quantity']} units', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          );
        },
      );
    }

    // Default Generic List Renderer
    if (_reportData is List) {
      final list = _reportData as List;
      if (list.isEmpty) return const Center(child: Text('No data found for this report.'));

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final item = list[idx] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.entries.map((e) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(child: Text(_reportData.toString()));
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
