import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ManufacturingScreen extends StatefulWidget {
  final int initialTabIndex;

  const ManufacturingScreen({super.key, this.initialTabIndex = 1});

  @override
  State<ManufacturingScreen> createState() => _ManufacturingScreenState();
}

class _ManufacturingScreenState extends State<ManufacturingScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  List<dynamic> _recipes = [];
  List<dynamic> _manufacturings = [];
  List<dynamic> _factoryProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rRes = await _apiClient.get('/recipes');
      final mRes = await _apiClient.get('/manufacturings');
      final fpRes = await _apiClient.get('/factory-products');

      if (rRes.data['success'] == true) _recipes = rRes.data['data'] ?? [];
      if (mRes.data['success'] == true) _manufacturings = mRes.data['data'] ?? [];
      if (fpRes.data['success'] == true) _factoryProducts = fpRes.data['data'] ?? [];
    } catch (e) {
      _errorMessage = 'Failed to load manufacturing data. Please check connection.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manufacturing & Production'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Recipes'),
            Tab(text: 'Manufacturings'),
            Tab(text: 'Factory Products'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchData, child: const Text('Retry Connection')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. Recipes Tab
                    _recipes.isEmpty
                        ? const Center(child: Text('No manufacturing recipes recorded.'))
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _recipes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final r = _recipes[idx];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.purple.shade100,
                                      child: Icon(Icons.receipt, color: Colors.purple.shade800),
                                    ),
                                    title: Text(r['name'] ?? 'Recipe', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Product: ${r['factory_product_name'] ?? "N/A"}\nType: ${r['recipe_type'] ?? "mix"}'),
                                    isThreeLine: true,
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text(r['status'] ?? 'Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                    // 2. Manufacturings Tab
                    _manufacturings.isEmpty
                        ? const Center(child: Text('No manufacturing batches recorded.'))
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _manufacturings.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final m = _manufacturings[idx];
                                final status = m['status'] ?? 'PENDING';
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.amber.shade100,
                                      child: Icon(Icons.precision_manufacturing, color: Colors.amber.shade900),
                                    ),
                                    title: Text(m['batch_no'] ?? 'BATCH-#${m['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Product: ${m['factory_product_name'] ?? "N/A"} (${m['recipe_name'] ?? ""})\nPlanned: ${m['planned_qty']} • Date: ${m['start_date']}'),
                                    isThreeLine: true,
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                    // 3. Factory Products Tab
                    _factoryProducts.isEmpty
                        ? const Center(child: Text('No factory products recorded.'))
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _factoryProducts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final fp = _factoryProducts[idx];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.teal.shade100,
                                      child: Icon(Icons.inventory, color: Colors.teal.shade800),
                                    ),
                                    title: Text(fp['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Type: ${fp['type'] ?? "General"}${fp['remarks'] != null ? " • ${fp['remarks']}" : ""}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text(fp['status'] ?? 'Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
    );
  }
}
