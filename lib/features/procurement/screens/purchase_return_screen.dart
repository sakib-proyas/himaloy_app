import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key});

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _returns = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get('/purchase-returns');
      if (res.data['success'] == true) {
        _returns = res.data['data'] ?? [];
      }
    } catch (e) {
      _errorMessage = 'Failed to load purchase returns. Please check connection.';
    }

    try {
      final sRes = await _apiClient.get('/suppliers');
      if (sRes.data['success'] == true) _suppliers = sRes.data['data'] ?? [];
    } catch (_) {}

    try {
      final wRes = await _apiClient.get('/warehouses');
      if (wRes.data['success'] == true) _warehouses = wRes.data['data'] ?? [];
    } catch (_) {}

    try {
      final pRes = await _apiClient.get('/products');
      if (pRes.data['success'] == true) {
        final List list = pRes.data['data']['data'] ?? [];
        _products = list;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _showNewReturnModal() {
    int? supplierId = _suppliers.isNotEmpty ? _suppliers.first['id'] : null;
    int? warehouseId = _warehouses.isNotEmpty ? _warehouses.first['id'] : null;
    int? selectedProductId = _products.isNotEmpty ? _products.first['id'] : null;
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(text: '0');
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
                const Text('New Purchase Return Claim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_suppliers.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: supplierId,
                    decoration: const InputDecoration(labelText: 'Select Supplier *'),
                    items: _suppliers.map<DropdownMenuItem<int>>((s) {
                      return DropdownMenuItem<int>(value: s['id'] as int, child: Text('${s['name']} (${s['company']})'));
                    }).toList(),
                    onChanged: (val) => setModalState(() => supplierId = val),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_warehouses.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: warehouseId,
                    decoration: const InputDecoration(labelText: 'Dispatch Warehouse *'),
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
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Return Quantity *'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Cost (৳) *'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Return Reason / Notes')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    final cost = double.tryParse(costCtrl.text) ?? 0;
                    if (supplierId == null || warehouseId == null || selectedProductId == null || qty <= 0) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      await _apiClient.post(
                        '/purchase-returns',
                        data: {
                          'supplier_id': supplierId,
                          'warehouse_id': warehouseId,
                          'product_id': selectedProductId,
                          'quantity': qty,
                          'unit_cost': cost,
                          'note': noteCtrl.text.trim(),
                        },
                      );
                      _fetchData();
                    } catch (_) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Save Return Claim'),
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
        title: const Text('Purchase Returns'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showNewReturnModal,
        icon: const Icon(Icons.assignment_return, color: Colors.white),
        label: const Text('Return Claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      ElevatedButton(onPressed: _fetchData, child: const Text('Retry Connection')),
                    ],
                  ),
                )
              : _returns.isEmpty
                  ? const Center(child: Text('No purchase return claims recorded.'))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _returns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final pr = _returns[idx];
                          final items = pr['items'] as List? ?? [];
                          final total = double.tryParse(pr['total']?.toString() ?? '0') ?? 0.0;

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
                                        pr['reference_no'] ?? 'PR-#${pr['id']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                                      ),
                                      Text('৳ ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.errorRed)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Supplier: ${pr['supplier_name'] ?? "N/A"} • Warehouse: ${pr['warehouse_name'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text('Date: ${pr['date'] ?? "-"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  if (items.isNotEmpty) ...[
                                    const Divider(height: 16),
                                    ...items.map((it) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('📦 ${it['product_name']} (${it['sku'] ?? 'N/A'})', style: const TextStyle(fontSize: 13)),
                                            Text('${it['quantity']} ${it['unit'] ?? "pcs"} @ ৳${it['unit_cost']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
