import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/units');
      if (res.data['success'] == true) {
        setState(() {
          _units = res.data['data'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddUnitModal() {
    final nameCtrl = TextEditingController();
    final shortNameCtrl = TextEditingController();

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
            const Text('Add Packaging Unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Unit Full Name (e.g. Kilogram) *')),
            const SizedBox(height: 12),
            TextField(controller: shortNameCtrl, decoration: const InputDecoration(labelText: 'Short Code (e.g. kg) *')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || shortNameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _apiClient.post(
                    '/units',
                    data: {
                      'name': nameCtrl.text.trim(),
                      'short_name': shortNameCtrl.text.trim(),
                    },
                  );
                  _fetchUnits();
                } catch (_) {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save Unit'),
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
        title: const Text('Units Control'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showAddUnitModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Unit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? const Center(child: Text('No packaging units found.'))
              : RefreshIndicator(
                  onRefresh: _fetchUnits,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _units.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final u = _units[idx];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown.shade100,
                            child: Icon(Icons.straighten, color: Colors.brown.shade800),
                          ),
                          title: Text(u['name'] ?? 'Unit', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Short Code: ${u['short_name'] ?? "N/A"}'),
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
    );
  }
}
