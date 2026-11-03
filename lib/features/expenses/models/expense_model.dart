class ExpenseModel {
  final int id;
  final String expenseNo;
  final String date;
  final String category;
  final double amount;
  final String paymentMethod;
  final String? referenceNo;
  final String? note;
  final String? creatorName;

  ExpenseModel({
    required this.id,
    required this.expenseNo,
    required this.date,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    this.referenceNo,
    this.note,
    this.creatorName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? 0,
      expenseNo: json['expense_no'] ?? '',
      date: json['date'] ?? '',
      category: json['category'] ?? 'General',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      referenceNo: json['reference_no'],
      note: json['note'],
      creatorName: json['creator']?['name'],
    );
  }
}

