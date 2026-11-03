import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class StockUsageScreen extends StatefulWidget {
  const StockUsageScreen({super.key});

  @override
  State<StockUsageScreen> createState() => _StockUsageScreenState();
}

class _StockUsageScreenState extends State<StockUsageScreen> {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _usages = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/stock-usages');
      final wRes = await _apiClient.get('/warehouses');
      final pRes = await _apiClient.get('/products');

      if (res.data['success'] == true) {
        _usages = res.data['data'] ?? [];
      }
      if (wRes.data['success'] == true) {
        _warehouses = wRes.data['data'] ?? [];
      }
      if (pRes.data['success'] == true) {
        final List list = pRes.data['data']['data'] ?? [];
        _products = list;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogUsageModal() {
    int? warehouseId = _warehouses.isNotEmpty ? _warehouses.first['id'] : null;
    int? selectedProductId = _products.isNotEmpty ? _products.first['id'] : null;
    final qtyCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Log Stock Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_warehouses.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: warehouseId,
                    decoration: const InputDecoration(labelText: 'Warehouse / Factory Base *'),
                    items: _warehouses.map<DropdownMenuItem<int>>((w) {
                      return DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'] as String));
                    }).toList(),
                    onChanged: (val) => setModalState(() => warehouseId = val),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_products.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Select Product *'),
                    items: _products.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(value: p['id'] as int, child: Text('${p['name']} (${p['sku']})'));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedProductId = val),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity Used *')),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Usage Purpose / Notes')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    if (warehouseId == null || selectedProductId == null || qty <= 0) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      await _apiClient.post(
                        '/stock-usages',
                        data: {
                          'warehouse_id': warehouseId,
                          'product_id': selectedProductId,
                          'quantity': qty,
                          'note': noteCtrl.text.trim(),
                        },
                      );
                      _fetchData();
                    } catch (_) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Confirm Usage Log'),
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
        title: const Text('Stock Usages'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showLogUsageModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Usage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usages.isEmpty
              ? const Center(child: Text('No stock usage logs found.'))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _usages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final su = _usages[idx];
                      final items = su['items'] as List? ?? [];

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
                                    su['reference_no'] ?? 'USE-#${su['id']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown),
                                  ),
                                  Text(
                                    su['date'] ?? '-',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Officer: ${su['employee_name'] ?? "N/A"} • Warehouse: ${su['warehouse_name'] ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              if (items.isNotEmpty) ...[
                                const Divider(height: 16),
                                ...items.map((it) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('🧪 ${it['product_name']} (${it['sku'] ?? 'N/A'})', style: const TextStyle(fontSize: 13)),
                                        Text('${it['quantity']} ${it['unit'] ?? "pcs"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.errorRed)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
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
