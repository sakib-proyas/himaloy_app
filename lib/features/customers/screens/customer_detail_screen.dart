import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';
import '../../orders/screens/create_order_screen.dart';
import '../../collections/screens/due_collection_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  CustomerModel? _customer;
  List<dynamic> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
  }

  Future<void> _fetchCustomerDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('${ApiConstants.customers}/${widget.customerId}');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() {
          _customer = CustomerModel.fromJson(data);
          _sales = data['sales'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: Text('Customer not found.')),
      );
    }

    final c = _customer!;
    final hasDue = c.totalDue > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.isWholesale ? Colors.blue.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.isWholesale ? 'Wholesale Customer' : 'Retail Customer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: c.isWholesale ? Colors.blue.shade800 : AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('👤 Proprietor: ${c.proprietorName ?? "N/A"}'),
                  const SizedBox(height: 4),
                  Text('📞 Phone: ${c.phone} ${c.phone2 != null ? "• " + c.phone2! : ""}'),
                  const SizedBox(height: 4),
                  Text('📍 Territory: ${c.territory ?? "General"} • Region: ${c.region ?? "All"}'),
                  if (c.address != null) ...[
                    const SizedBox(height: 4),
                    Text('🏠 Address: ${c.address}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Due Balance Banner
          Card(
            color: hasDue ? Colors.red.shade50 : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDue ? 'Outstanding Due Debt' : 'Clear Account',
                        style: TextStyle(fontSize: 12, color: hasDue ? AppTheme.errorRed : AppTheme.successGreen, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '৳ ${c.totalDue.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: hasDue ? AppTheme.errorRed : AppTheme.successGreen),
                      ),
                    ],
                  ),
                  if (hasDue)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DueCollectionScreen()));
                      },
                      child: const Text('Collect Due'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Shortcuts
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen()));
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Book Order'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Invoices History
          const Text('Recent Invoices & Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (_sales.isEmpty)
            const Text('No recent invoice records found.', style: TextStyle(color: AppTheme.textMuted))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sales.length,
              itemBuilder: (ctx, idx) {
                final sale = _sales[idx];
                final double total = double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0;
                final double due = double.tryParse(sale['due']?.toString() ?? '0') ?? 0.0;
                final isPaid = due <= 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    title: Text('Invoice #${sale['invoice_no']} • ${sale['date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total: ৳ ${total.toStringAsFixed(0)}'),
                    trailing: Text(
                      isPaid ? 'PAID' : 'Due: ৳ ${due.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

