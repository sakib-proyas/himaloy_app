import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../catalog/models/product_model.dart';
import '../../customers/models/customer_model.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final ApiClient _apiClient = ApiClient();
  final _paidController = TextEditingController(text: '0');
  final _noteController = TextEditingController();

  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  CustomerModel? _selectedCustomer;

  // Selected items: productId -> {product, qty, price}
  final Map<int, Map<String, dynamic>> _cart = {};

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final custRes = await _apiClient.get(ApiConstants.customers, queryParameters: {'per_page': 100});
      final prodRes = await _apiClient.get(ApiConstants.products, queryParameters: {'per_page': 100});

      if (custRes.data['success'] == true && prodRes.data['success'] == true) {
        final List cList = custRes.data['data']['data'] ?? [];
        final List pList = prodRes.data['data']['data'] ?? [];
        setState(() {
          _customers = cList.map((c) => CustomerModel.fromJson(c)).toList();
          _products = pList.map((p) => ProductModel.fromJson(p)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCustomerSelected(CustomerModel? customer) {
    setState(() {
      _selectedCustomer = customer;
      // Re-evaluate cart item prices based on customer pricing tier
      _cart.forEach((id, item) {
        final product = item['product'] as ProductModel;
        final price = (_selectedCustomer?.isWholesale == true && product.wholesalePrice > 0)
            ? product.wholesalePrice
            : product.salePrice;
        item['price'] = price;
      });
    });
  }

  void _addProductToCart(ProductModel product) {
    setState(() {
      final price = (_selectedCustomer?.isWholesale == true && product.wholesalePrice > 0)
          ? product.wholesalePrice
          : product.salePrice;

      if (_cart.containsKey(product.id)) {
        _cart[product.id]!['qty'] = (_cart[product.id]!['qty'] as double) + 1.0;
      } else {
        _cart[product.id] = {
          'product': product,
          'qty': 1.0,
          'price': price,
        };
      }
    });
  }

  double get _totalOrderAmount {
    double total = 0;
    _cart.forEach((_, item) {
      total += (item['qty'] as double) * (item['price'] as double);
    });
    return total;
  }

  Future<void> _submitOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first.')),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to the order.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final items = _cart.entries.map((entry) {
        return {
          'product_id': entry.key,
          'qty': entry.value['qty'],
          'price': entry.value['price'],
        };
      }).toList();

      final response = await _apiClient.post(
        ApiConstants.employeeOrders,
        data: {
          'customer_id': _selectedCustomer!.id,
          'items': items,
          'paid': double.tryParse(_paidController.text) ?? 0,
          'note': _noteController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Submitted'),
            content: const Text('The employee order has been placed and is waiting for Level 1 approval.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Field Order'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Customer Dropdown
                      const Text('Select Customer *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<CustomerModel>(
                        value: _selectedCustomer,
                        isExpanded: true,
                        hint: const Text('Choose customer...'),
                        items: _customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} (${c.isWholesale ? "Wholesale" : "Retail"})'),
                          );
                        }).toList(),
                        onChanged: _onCustomerSelected,
                      ),
                      const SizedBox(height: 16),

                      // Add Products Button & Modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                            onPressed: () => _showProductPickerModal(),
                          ),
                        ],
                      ),

                      if (_cart.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Cart is empty. Tap "+ Add Product" to include items.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cart.length,
                          itemBuilder: (ctx, index) {
                            final productId = _cart.keys.elementAt(index);
                            final item = _cart[productId]!;
                            final ProductModel product = item['product'];
                            final double qty = item['qty'];
                            final double price = item['price'];
                            final double subtotal = qty * price;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            '৳ ${price.toStringAsFixed(2)} × ${qty.toStringAsFixed(0)} ${product.unitName ?? ""}',
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                          ),
                                          Text(
                                            'Subtotal: ৳ ${subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        setState(() {
                                          if (qty > 1) {
                                            item['qty'] = qty - 1;
                                          } else {
                                            _cart.remove(productId);
                                          }
                                        });
                                      },
                                    ),
                                    Text('${qty.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        setState(() {
                                          item['qty'] = qty + 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),
                      // Payment Section
                      TextField(
                        controller: _paidController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Advance Paid Amount (৳)',
                          prefixText: '৳ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(labelText: 'Order Notes / Delivery Instructions'),
                      ),
                    ],
                  ),
                ),

                // Bottom Checkout Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text(
                              '৳ ${_totalOrderAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitOrder,
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Confirm Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showProductPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Select Products to Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final product = _products[index];
                      final price = (_selectedCustomer?.isWholesale == true && product.wholesalePrice > 0)
                          ? product.wholesalePrice
                          : product.salePrice;

                      return ListTile(
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('৳ ${price.toStringAsFixed(2)} • Stock: ${product.totalAvailableStock}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onPressed: () {
                            _addProductToCart(product);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Add'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

