import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/delivery_model.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  final ApiClient _apiClient = ApiClient();
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries([String? status]) async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> params = {'per_page': 50};
      if (status != null && status != 'all') {
        params['status'] = status;
      }

      final res = await _apiClient.get(ApiConstants.deliveries, queryParameters: params);
      if (res.data['success'] == true) {
        final List list = res.data['data']['data'] ?? [];
        setState(() {
          _deliveries = list.map((item) => DeliveryModel.fromJson(item)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMarkDeliveredDialog(DeliveryModel delivery) {
    final receiverCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deliver Order #${delivery.employeeOrderId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${delivery.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: receiverCtrl,
              decoration: const InputDecoration(labelText: 'Received by (Name) *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Delivery Remarks / Gate Pass'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (receiverCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _apiClient.put(
                  '${ApiConstants.deliveries}/${delivery.id}/status',
                  data: {
                    'delivery_status': 'delivered',
                    'receiver_name': receiverCtrl.text.trim(),
                    'delivery_note': noteCtrl.text.trim(),
                  },
                );
                _fetchDeliveries(_selectedFilter);
              } catch (_) {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Confirm Delivered'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Deliveries'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Pending Delivery'),
                  selected: _selectedFilter == 'pending',
                  onSelected: (val) {
                    setState(() => _selectedFilter = 'pending');
                    _fetchDeliveries('pending');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Delivered'),
                  selected: _selectedFilter == 'delivered',
                  onSelected: (val) {
                    setState(() => _selectedFilter = 'delivered');
                    _fetchDeliveries('delivered');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (val) {
                    setState(() => _selectedFilter = 'all');
                    _fetchDeliveries('all');
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _deliveries.isEmpty
                    ? const Center(child: Text('No deliveries found.'))
                    : RefreshIndicator(
                        onRefresh: () => _fetchDeliveries(_selectedFilter),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _deliveries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _deliveries[index];
                            final isPending = item.deliveryStatus == 'pending';

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Order #${item.employeeOrderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPending
                                                ? Colors.orange.withOpacity(0.12)
                                                : AppTheme.successGreen.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isPending ? 'Pending Dispatch' : 'Delivered',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: isPending ? Colors.orange.shade800 : AppTheme.successGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Order Value: ৳ ${item.orderAmount.toStringAsFixed(0)}'),
                                    if (item.receiverName != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Receiver: ${item.receiverName} • ${item.deliveredAt ?? ""}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    ],
                                    if (isPending) ...[
                                      const Divider(height: 18),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showMarkDeliveredDialog(item),
                                          icon: const Icon(Icons.check_circle_outline),
                                          label: const Text('Mark as Delivered'),
                                        ),
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
}

