class DeliveryModel {
  final int id;
  final int employeeOrderId;
  final String customerName;
  final String? employeeName;
  final String deliveryStatus;
  final String? deliveredAt;
  final String? receiverName;
  final String? deliveryNote;
  final double orderAmount;

  DeliveryModel({
    required this.id,
    required this.employeeOrderId,
    required this.customerName,
    this.employeeName,
    required this.deliveryStatus,
    this.deliveredAt,
    this.receiverName,
    this.deliveryNote,
    required this.orderAmount,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id'] ?? 0,
      employeeOrderId: json['employee_order_id'] ?? 0,
      customerName: json['order']?['customer_name'] ?? 'Customer',
      employeeName: json['employee']?['name'],
      deliveryStatus: json['delivery_status'] ?? 'pending',
      deliveredAt: json['delivered_at'],
      receiverName: json['receiver_name'],
      deliveryNote: json['delivery_note'],
      orderAmount: double.tryParse(json['order']?['amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

