import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../customers/models/customer_model.dart';
import '../models/due_invoice_model.dart';

class DueCollectionScreen extends StatefulWidget {
  const DueCollectionScreen({super.key});

  @override
  State<DueCollectionScreen> createState() => _DueCollectionScreenState();
}

class _DueCollectionScreenState extends State<DueCollectionScreen> {
  final ApiClient _apiClient = ApiClient();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  List<DueInvoiceModel> _invoices = [];
  double _customerTotalDue = 0.0;

  String _paymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'bKash', 'Nagad', 'Bank Transfer', 'Cheque'];

  bool _isLoading = true;
  bool _isLoadingInvoices = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(
        ApiConstants.customers,
        queryParameters: {'per_page': 200, 'only_due': 'true'},
      );
      if (res.data['success'] == true) {
        final List list = res.data['data']['data'] ?? [];
        setState(() {
          _customers = list
              .map((c) => CustomerModel.fromJson(c))
              .where((c) => c.totalDue > 0)
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCustomerChanged(CustomerModel? customer) async {
    if (customer == null) return;
    setState(() {
      _selectedCustomer = customer;
      _isLoadingInvoices = true;
      _invoices = [];
      _customerTotalDue = 0.0;
    });

    try {
      final res = await _apiClient.get('${ApiConstants.dueCollections}/customer/${customer.id}');
      if (res.data['success'] == true) {
        final List invList = res.data['data']['invoices'] ?? [];
        setState(() {
          _invoices = invList.map((i) => DueInvoiceModel.fromJson(i)).toList();
          _customerTotalDue = double.tryParse(res.data['data']['total_due']?.toString() ?? '0') ?? 0.0;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingInvoices = false);
    }
  }

  Future<void> _submitCollection() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer.')));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid collection amount.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await _apiClient.post(
        ApiConstants.dueCollections,
        data: {
          'customer_id': _selectedCustomer!.id,
          'amount': amount,
          'date': DateTime.now().toIso8601String().split('T').first,
          'payment_method': _paymentMethod,
          'reference_no': _referenceController.text.trim(),
          'note': _noteController.text.trim(),
        },
      );

      if (res.data['success'] == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Collection Recorded'),
            content: Text('৳ ${amount.toStringAsFixed(2)} was successfully collected and settled across previous invoices FIFO.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Collection error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Due Collection'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Select Customer *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<CustomerModel>(
                  value: _selectedCustomer,
                  isExpanded: true,
                  hint: const Text('Choose customer...'),
                  items: _customers.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text('${c.name} (Due: ৳ ${c.totalDue.toStringAsFixed(0)})'),
                    );
                  }).toList(),
                  onChanged: _onCustomerChanged,
                ),
                const SizedBox(height: 16),

                if (_isLoadingInvoices)
                  const Center(child: CircularProgressIndicator())
                else if (_selectedCustomer != null) ...[
                  // Due summary card
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Proprietor: ${_selectedCustomer!.proprietorName ?? "N/A"} • 📞 ${_selectedCustomer!.phone}'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Due', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text(
                                '৳ ${_customerTotalDue.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.errorRed),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Outstanding Invoices List
                  const Text('Unpaid Invoices (Settled FIFO)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  if (_invoices.isEmpty)
                    const Text('No outstanding due invoices for this customer.', style: TextStyle(color: AppTheme.textMuted))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _invoices.length,
                      itemBuilder: (ctx, idx) {
                        final inv = _invoices[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text('Invoice #${inv.invoiceNo} • ${inv.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Warehouse: ${inv.warehouseName} • Total: ৳ ${inv.total.toStringAsFixed(0)}'),
                            trailing: Text(
                              '৳ ${inv.due.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  // Payment Form
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Collection Amount *',
                      prefixText: '৳ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method *'),
                    items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _referenceController,
                    decoration: const InputDecoration(labelText: 'Reference / Money Receipt No.'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Notes / Remarks'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCollection,
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm & Save Collection'),
                  ),
                ],
              ],
            ),
    );
  }
}

