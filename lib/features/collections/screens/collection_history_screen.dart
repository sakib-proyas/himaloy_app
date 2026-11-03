import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CollectionHistoryScreen extends StatefulWidget {
  final bool filterMyCollections;

  const CollectionHistoryScreen({super.key, this.filterMyCollections = false});

  @override
  State<CollectionHistoryScreen> createState() => _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _collections = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get('/due-collections/history');
      if (res.data['success'] == true) {
        final data = res.data['data'] ?? {};
        final List list = data['collections']?['data'] ?? [];
        _collections = list;
        _stats = data['stats'] ?? {};
      }
    } catch (e) {
      _errorMessage = 'Failed to load collection history. Please check connection.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = _collections.where((c) {
      final no = (c['collection_no'] ?? '').toString().toLowerCase();
      final ref = (c['reference_no'] ?? '').toString().toLowerCase();
      final method = (c['payment_method'] ?? '').toString().toLowerCase();
      return query.isEmpty || no.contains(query) || ref.contains(query) || method.contains(query);
    }).toList();

    final totalAmount = double.tryParse(_stats['total_amount']?.toString() ?? '0') ?? 0.0;
    final todayAmount = double.tryParse(_stats['today_amount']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filterMyCollections ? 'Employee Collection Log' : 'All Collections History'),
      ),
      body: Column(
        children: [
          // Stats banner
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Collected', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('৳ ${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text('Today Collected', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('৳ ${todayAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search collection no, reference, payment method...',
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
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchHistory, child: const Text('Retry Connection')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(child: Text('No collection history records found.'))
                        : RefreshIndicator(
                            onRefresh: _fetchHistory,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final c = filtered[idx];
                                final amount = double.tryParse(c['amount_collected']?.toString() ?? '0') ?? 0.0;
                                final method = (c['payment_method'] ?? 'cash').toString().toUpperCase();

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: Icon(Icons.payments, color: Colors.green.shade800),
                                    ),
                                    title: Text(c['collection_no'] ?? 'COLL-#${c['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Date: ${c['date'] ?? "-"} • Method: $method\n${c['note'] ?? ""}'),
                                    isThreeLine: c['note'] != null && c['note'].toString().isNotEmpty,
                                    trailing: Text(
                                      '৳ ${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen),
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
