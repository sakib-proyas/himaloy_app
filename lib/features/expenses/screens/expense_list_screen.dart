import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/expense_model.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ApiClient _apiClient = ApiClient();
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Transport & Fuel',
    'Food & Entertainment',
    'Hotel & Lodging',
    'Field Promotion',
    'Office Supplies',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses([String? category]) async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> params = {'per_page': 50};
      if (category != null && category != 'All') {
        params['category'] = category;
      }

      final res = await _apiClient.get(ApiConstants.expenses, queryParameters: params);
      if (res.data['success'] == true) {
        final List list = res.data['data']['data'] ?? [];
        setState(() {
          _expenses = list.map((item) => ExpenseModel.fromJson(item)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalExpenseSum {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _showAddExpenseModal() {
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = 'Transport & Fuel';
    String paymentMethod = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                const Text('Record Field Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Expense Category *'),
                  items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setModalState(() => category = val ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (৳) *', prefixText: '৳ '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method *'),
                  items: ['Cash', 'bKash', 'Nagad', 'Company Card'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setModalState(() => paymentMethod = val ?? 'Cash'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Voucher / Bill No.'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Purpose / Details'),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amount <= 0) return;

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      await _apiClient.post(
                        ApiConstants.expenses,
                        data: {
                          'category': category,
                          'amount': amount,
                          'date': DateTime.now().toIso8601String().split('T').first,
                          'payment_method': paymentMethod,
                          'reference_no': refCtrl.text.trim(),
                          'note': noteCtrl.text.trim(),
                        },
                      );
                      _fetchExpenses(_selectedCategory);
                    } catch (_) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Save Expense'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Expenses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showAddExpenseModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // KPI Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Logged Expenses', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '৳ ${_totalExpenseSum.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_expenses.length} Records',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      _fetchExpenses(cat);
                    }
                  },
                );
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? const Center(child: Text('No expenses recorded.'))
                    : RefreshIndicator(
                        onRefresh: () => _fetchExpenses(_selectedCategory),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _expenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _expenses[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                                  child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
                                ),
                                title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${item.date} • ${item.paymentMethod.toUpperCase()} ${item.note != null ? "• " + item.note! : ""}'),
                                trailing: Text(
                                  '৳ ${item.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.errorRed),
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

