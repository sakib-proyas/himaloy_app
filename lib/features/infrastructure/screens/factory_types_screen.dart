import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class FactoryTypesScreen extends StatefulWidget {
  const FactoryTypesScreen({super.key});

  @override
  State<FactoryTypesScreen> createState() => _FactoryTypesScreenState();
}

class _FactoryTypesScreenState extends State<FactoryTypesScreen> {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _types = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/warehouse-types');
      if (res.data['success'] == true) {
        setState(() {
          _types = res.data['data'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTypeModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Factory Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Type Name *')),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Type Code')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _apiClient.post(
                    '/warehouse-types',
                    data: {
                      'name': nameCtrl.text.trim(),
                      'code': codeCtrl.text.trim(),
                    },
                  );
                  _fetchTypes();
                } catch (_) {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save Factory Type'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Types'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showAddTypeModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Factory Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _types.isEmpty
              ? const Center(child: Text('No factory types recorded.'))
              : RefreshIndicator(
                  onRefresh: _fetchTypes,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: _types.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final t = _types[idx];
                      final status = t['status'] ?? 'Active';
                      final isActive = status == 'Active';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade50,
                            child: Text(
                              '#${idx + 1}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800),
                            ),
                          ),
                          title: Text(t['name'] ?? 'Type', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Code: ${t['code'] ?? "N/A"}${t['description'] != null ? " • ${t['description']}" : ""}'),
                          trailing: Container(
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
