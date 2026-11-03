class OrderModel {
  final int id;
  final int employeeId;
  final String? employeeName;
  final int? customerId;
  final String customerName;
  final double amount;
  final double paid;
  final double due;
  final String status;
  final String paymentStatus;
  final String? orderDetails;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.customerId,
    required this.customerName,
    required this.amount,
    required this.paid,
    required this.due,
    required this.status,
    required this.paymentStatus,
    this.orderDetails,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<OrderItemModel> itemsList = rawItems.map((i) => OrderItemModel.fromJson(i)).toList();

    return OrderModel(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee']?['name'],
      customerId: json['customer_id'],
      customerName: json['customer_name'] ?? json['customer']?['name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paid: double.tryParse(json['paid']?.toString() ?? '0') ?? 0.0,
      due: double.tryParse(json['due']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'waiting',
      paymentStatus: json['payment_status'] ?? 'due',
      orderDetails: json['order_details'],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      items: itemsList,
    );
  }
}

class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final double qty;
  final double price;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product']?['name'] ?? 'Product #${json['product_id']}',
      qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0.0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

