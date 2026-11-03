import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _transfers = [];
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
      final res = await _apiClient.get('/stock-transfers');
      final wRes = await _apiClient.get('/warehouses');
      final pRes = await _apiClient.get('/products');

      if (res.data['success'] == true) {
        _transfers = res.data['data'] ?? [];
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

  void _showNewTransferModal() {
    int? fromWarehouseId = _warehouses.isNotEmpty ? _warehouses.first['id'] : null;
    int? toWarehouseId = _warehouses.length > 1 ? _warehouses[1]['id'] : fromWarehouseId;
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
                const Text('New Stock Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_warehouses.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: fromWarehouseId,
                    decoration: const InputDecoration(labelText: 'From Warehouse / Dipo *'),
                    items: _warehouses.map<DropdownMenuItem<int>>((w) {
                      return DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'] as String));
                    }).toList(),
                    onChanged: (val) => setModalState(() => fromWarehouseId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: toWarehouseId,
                    decoration: const InputDecoration(labelText: 'To Warehouse / Dipo *'),
                    items: _warehouses.map<DropdownMenuItem<int>>((w) {
                      return DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'] as String));
                    }).toList(),
                    onChanged: (val) => setModalState(() => toWarehouseId = val),
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
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Transfer Quantity *')),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Notes / Remarks')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    if (fromWarehouseId == null || toWarehouseId == null || selectedProductId == null || qty <= 0) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      await _apiClient.post(
                        '/stock-transfers',
                        data: {
                          'from_warehouse_id': fromWarehouseId,
                          'to_warehouse_id': toWarehouseId,
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
                  child: const Text('Confirm Transfer'),
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
        title: const Text('Stock Transfer'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showNewTransferModal,
        icon: const Icon(Icons.swap_horiz, color: Colors.white),
        label: const Text('New Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transfers.isEmpty
              ? const Center(child: Text('No stock transfers recorded.'))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _transfers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final st = _transfers[idx];
                      final status = (st['status'] ?? 'APPROVED').toString().toUpperCase();
                      final isApproved = status == 'APPROVED';
                      final items = st['items'] as List? ?? [];

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
                                    st['reference_no'] ?? 'TRF-#${st['id']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isApproved ? Colors.green.shade100 : Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isApproved ? Colors.green.shade900 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.storefront, size: 16, color: Colors.grey.shade700),
                                  const SizedBox(width: 4),
                                  Text('${st['from_warehouse'] ?? "N/A"} ➔ ${st['to_warehouse'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Date: ${st['date'] ?? "-"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              if (items.isNotEmpty) ...[
                                const Divider(height: 16),
                                ...items.map((it) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('📦 ${it['product_name']} (${it['sku'] ?? 'N/A'})', style: const TextStyle(fontSize: 13)),
                                        Text('${it['quantity']} ${it['unit'] ?? "pcs"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
