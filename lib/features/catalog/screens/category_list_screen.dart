import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CategoryListScreen extends StatefulWidget {
  final int initialTabIndex;

  const CategoryListScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  List<dynamic> _categories = [];
  List<dynamic> _subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final catRes = await _apiClient.get('/categories');
      final subRes = await _apiClient.get('/sub-categories');

      if (catRes.data['success'] == true) {
        _categories = catRes.data['data'] ?? [];
      }
      if (subRes.data['success'] == true) {
        _subCategories = subRes.data['data'] ?? [];
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddCategoryModal() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name *')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _apiClient.post('/categories', data: {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()});
                  _fetchData();
                } catch (_) {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubCategoryModal() {
    final nameCtrl = TextEditingController();
    int? selectedCatId = _categories.isNotEmpty ? _categories.first['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Sub Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_categories.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  value: selectedCatId,
                  decoration: const InputDecoration(labelText: 'Parent Category *'),
                  items: _categories.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem<int>(value: c['id'] as int, child: Text(c['name'] as String));
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedCatId = val),
                ),
                const SizedBox(height: 12),
              ],
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Sub Category Name *')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || selectedCatId == null) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await _apiClient.post('/sub-categories', data: {'name': nameCtrl.text.trim(), 'category_id': selectedCatId});
                    _fetchData();
                  } catch (_) {
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text('Save Sub Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Sub Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Sub Categories'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddCategoryModal();
          } else {
            _showAddSubCategoryModal();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Category' : 'Add Sub Category',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Categories List
                _categories.isEmpty
                    ? const Center(child: Text('No categories found.'))
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final c = _categories[idx];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepOrange.shade100,
                                  child: Icon(Icons.category, color: Colors.deepOrange.shade800),
                                ),
                                title: Text(c['name'] ?? 'Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Slug: ${c['slug'] ?? "N/A"}${c['description'] != null ? " • ${c['description']}" : ""}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                // Sub Categories List
                _subCategories.isEmpty
                    ? const Center(child: Text('No sub categories found.'))
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _subCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final sc = _subCategories[idx];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Icon(Icons.account_tree, color: Colors.indigo.shade800),
                                ),
                                title: Text(sc['name'] ?? 'Sub Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Parent Category: ${sc['category_name'] ?? "General"}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
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
