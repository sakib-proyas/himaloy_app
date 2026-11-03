import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class FactoryListScreen extends StatefulWidget {
  const FactoryListScreen({super.key});

  @override
  State<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends State<FactoryListScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _warehouses = [];
  List<dynamic> _types = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWarehouses();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    try {
      final res = await _apiClient.get('/warehouse-types');
      if (res.data['success'] == true) {
        setState(() {
          _types = res.data['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/warehouses');
      if (res.data['success'] == true) {
        setState(() {
          _warehouses = res.data['data'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddFactoryModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    int? selectedTypeId = _types.isNotEmpty ? _types.first['id'] : null;

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
                  'Add New Factory / Warehouse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Factory Name *')),
                const SizedBox(height: 12),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code / Reference')),
                const SizedBox(height: 12),
                if (_types.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Factory Type'),
                    items: _types.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'] as int,
                        child: Text(t['name'] as String),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedTypeId = val),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City / Location')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      await _apiClient.post(
                        '/warehouses',
                        data: {
                          'name': nameCtrl.text.trim(),
                          'code': codeCtrl.text.trim(),
                          'warehouse_type_id': selectedTypeId,
                          'city': cityCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                        },
                      );
                      _fetchWarehouses();
                    } catch (_) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Save Factory'),
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
    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = _warehouses.where((w) {
      final name = (w['name'] ?? '').toString().toLowerCase();
      final code = (w['code'] ?? '').toString().toLowerCase();
      final city = (w['city'] ?? '').toString().toLowerCase();
      return query.isEmpty || name.contains(query) || code.contains(query) || city.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory & Warehouses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showAddFactoryModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Factory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search factory name, code, city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No factories or warehouses found.'))
                    : RefreshIndicator(
                        onRefresh: _fetchWarehouses,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final w = filtered[index];
                            final status = w['status'] ?? 'Active';
                            final isActive = status == 'Active';

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '#${index + 1} ',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                            ),
                                            Text(
                                              w['name'] ?? 'Factory',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildBadge('Code: ${w['code'] ?? "N/A"}', Colors.blue.shade800),
                                        const SizedBox(width: 8),
                                        _buildBadge('Type: ${w['type'] ?? "N/A"}', Colors.purple.shade800),
                                        const SizedBox(width: 8),
                                        _buildBadge('City: ${w['city'] ?? "N/A"}', Colors.teal.shade800),
                                      ],
                                    ),
                                    if (w['phone'] != null || w['address'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '📍 ${w['address'] ?? ""} • 📞 ${w['phone'] ?? ""}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
