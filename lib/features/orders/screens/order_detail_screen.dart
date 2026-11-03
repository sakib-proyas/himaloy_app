import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final bool canApprove;

  const OrderDetailScreen({super.key, required this.orderId, this.canApprove = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  OrderModel? _order;
  bool _isLoading = true;
  bool _isActionRunning = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('${ApiConstants.employeeOrders}/${widget.orderId}');
      if (res.data['success'] == true) {
        setState(() {
          _order = OrderModel.fromJson(res.data['data']);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveFirst() async {
    setState(() => _isActionRunning = true);
    try {
      final res = await _apiClient.post('${ApiConstants.employeeOrders}/${widget.orderId}/approve-first');
      if (res.data['success'] == true) {
        _fetchOrderDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approval error: $e')));
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  Future<void> _approveSecond() async {
    setState(() => _isActionRunning = true);
    try {
      final res = await _apiClient.post('${ApiConstants.employeeOrders}/${widget.orderId}/approve-second');
      if (res.data['success'] == true) {
        _fetchOrderDetail();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Final approval error: $e')));
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'final_approved':
        return AppTheme.primaryGreen;
      case 'first_approved':
        return Colors.blue.shade700;
      case 'waiting':
        return Colors.orange.shade800;
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'final_approved':
        return 'Final Approved';
      case 'first_approved':
        return '1st Level Approved';
      case 'waiting':
        return 'Waiting Approval';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found.')),
      );
    }

    final order = _order!;
    final statusColor = _getStatusColor(order.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrderDetail,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _formatStatus(order.status),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Booked by: ${order.employeeName ?? "Field Representative"} • ${order.createdAt.toLocal().toString().split('.').first}'),
                  if (order.orderDetails != null && order.orderDetails!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Notes: ${order.orderDetails}', style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textMuted)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items Table
          const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final item = order.items[index];
                return ListTile(
                  dense: true,
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('৳ ${item.price.toStringAsFixed(2)} × ${item.qty.toStringAsFixed(0)}'),
                  trailing: Text(
                    '৳ ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary Card
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Order Value:'),
                      Text('৳ ${order.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advance Paid:'),
                      Text('৳ ${order.paid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Due:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '৳ ${order.due.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.errorRed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Manager Approval Actions
          if (widget.canApprove) ...[
            if (order.status == 'waiting')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                onPressed: _isActionRunning ? null : _approveFirst,
                icon: const Icon(Icons.check),
                label: const Text('Grant Level 1 Approval'),
              ),
            if (order.status == 'first_approved') ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                onPressed: _isActionRunning ? null : _approveSecond,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Grant Final Approval & Dispatch to Delivery'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

