import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/customer_model.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  final bool initialOnlyDue;
  final bool initialOnlyWholesale;

  const CustomerListScreen({
    super.key,
    this.initialOnlyDue = false,
    this.initialOnlyWholesale = false,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  late bool _onlyDue;

  @override
  void initState() {
    super.initState();
    _onlyDue = widget.initialOnlyDue;
    _fetchCustomers();
  }

  Future<void> _fetchCustomers([String search = '']) async {
    setState(() => _isLoading = true);
    try {
      final query = <String, dynamic>{};
      if (search.isNotEmpty) query['search'] = search;
      if (_onlyDue) query['only_due'] = 'true';

      final response = await _apiClient.get(
        ApiConstants.customers,
        queryParameters: query.isNotEmpty ? query : null,
      );

      if (response.data['success'] == true) {
        final List list = response.data['data']['data'] ?? [];
        setState(() {
          var items = list.map((item) => CustomerModel.fromJson(item)).toList();
          if (_onlyDue) {
            items = items.where((c) => c.totalDue > 0).toList();
          }
          if (widget.initialOnlyWholesale) {
            items = items.where((c) => (c.customerCategory ?? '').toLowerCase().contains('wholesale') || c.isWholesale).toList();
          }
          _customers = items;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddCustomerModal() {
    final nameCtrl = TextEditingController();
    final propCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final territoryCtrl = TextEditingController();
    bool isWholesale = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add New Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer / Shop Name *')),
                const SizedBox(height: 12),
                TextField(controller: propCtrl, decoration: const InputDecoration(labelText: 'Proprietor Name')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Phone *')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Full Address')),
                const SizedBox(height: 12),
                TextField(controller: territoryCtrl, decoration: const InputDecoration(labelText: 'Territory / Market')),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Wholesale Customer'),
                  subtitle: const Text('Applies wholesale pricing structure'),
                  value: isWholesale,
                  onChanged: (val) => setModalState(() => isWholesale = val),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      await _apiClient.post(
                        ApiConstants.customers,
                        data: {
                          'name': nameCtrl.text.trim(),
                          'proprietor_name': propCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'territory': territoryCtrl.text.trim(),
                          'customer_category': isWholesale ? 'wholesale customer' : 'retail customer',
                        },
                      );
                      _fetchCustomers();
                    } catch (_) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Save Customer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showAddCustomerModal,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customer name, phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _fetchCustomers('');
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) => _fetchCustomers(value),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Only Due'),
                  selected: _onlyDue,
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryGreen,
                  onSelected: (val) {
                    setState(() => _onlyDue = val);
                    _fetchCustomers(_searchController.text);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? const Center(child: Text('No customers found.'))
                    : RefreshIndicator(
                        onRefresh: () => _fetchCustomers(_searchController.text),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: _customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            final hasDue = customer.totalDue > 0;

                            return Card(
                              child: ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: customer.isWholesale ? Colors.blue.shade100 : Colors.green.shade100,
                                  child: Icon(
                                    customer.isWholesale ? Icons.store : Icons.person,
                                    color: customer.isWholesale ? Colors.blue.shade800 : AppTheme.primaryGreen,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        customer.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (customer.isWholesale)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Wholesale',
                                          style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Proprietor: ${customer.proprietorName ?? "N/A"} • 📞 ${customer.phone}'),
                                    Text('Territory: ${customer.territory ?? "General"} • ${customer.address ?? ""}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '৳ ${customer.totalDue.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: hasDue ? AppTheme.errorRed : AppTheme.textMuted,
                                      ),
                                    ),
                                    Text(
                                      hasDue ? 'Due Balance' : 'Clear',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: hasDue ? AppTheme.errorRed : AppTheme.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

